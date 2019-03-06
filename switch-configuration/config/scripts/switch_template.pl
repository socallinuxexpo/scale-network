#!/usr/bin/perl
#
# This script must be run from the .../config directory (the parent directory
# of the scripts directory where this script lives. All scripts are expected
# to be run from this location for consistency and ease of use.


##FIXME## Build a consistency check to match up VLANs in the vlans file(s) and
##FIXME## those defined in the types/* files.

use strict;
use integer;
use Scalar::Util qw/reftype/;
use Data::Dumper;

our $VV_LOW;
our $VV_HIGH;
our $VV_COUNT;
our $VV_prefix6;
our $VV_prefix4;
our $VV_name_prefix;


my $DEBUGLEVEL = 0;

my %Switchtypes;

sub set_debug_level
{
    $DEBUGLEVEL = shift(@_);
}
sub debug
{
  my $lvl = shift(@_);
  my $msg = join("", @_);
  print STDERR $msg if ($lvl <= $DEBUGLEVEL);
}

sub expand_double_colon
{
  my $addr = shift(@_);
  debug(8, "Expanding: $addr\n");
  my ($left, $right) = split(/::/, $addr);
  debug(8, "\t$left <-> $right\n");
  my $lcount = 1;
  my $rcount = 1;
  $lcount ++ while ($left  =~ m/:/g);
  $rcount ++ while ($right =~ m/:/g);
  my $needful = 8 - ($lcount + $rcount); # Number of quartets needed
  my $center = ":0" x $needful;
  debug(9, "\t Needed $needful -> $center\n");
  debug(8, "Returning: $left$center".":$right\n");
  return ($left. $center. ":". $right);
}

sub expand_quartet
{
  my $quartet = shift(@_);
  $quartet = "0".$quartet while length($quartet < 4);
}

sub get_default_gw
{
  # Assumes that the ::1 address of the /64 containing the given $addr
  # is the default gateway. Returns that address.
  my $addr = shift(@_);
  $addr = expand_double_colon($addr) if ($addr =~ /::/);
  my @quartets = split(/:/, $addr);
  my $gw = join(":", @quartets[0 .. 3])."::"."1";
  return($gw);
}

sub read_config_file
{
  my $filename = shift(@_);
  my @OUTPUT;
  my $CONFIG;
  open $CONFIG, "<$filename" || die("Failed to open $filename as CONFIG\n");
  while ($_ = <$CONFIG>)
  {
    chomp;
    debug(8, "Base input: $_\n");
    while ($_ =~ s/ \\$/ /)
    {
      my $x = <$CONFIG>;
      chomp($x);
      $x =~ s/^\s*//;
      debug(9, "\tC->: $x\n");
      $_ .= $x;
    }
    $_ =~ s@//.*@@; # Eliminate comments
    next if ($_ =~ /^\s*$/); # Ignore blank lines
    $_ =~ s/\t+/\t/g;
    debug(8, "Cooked output: $_\n");
    if ($_ =~ /^\s*#include (.*)/)
    {
        debug(8, "\tProcessing included file $1\n");
        my $input = read_config_file($1);
        debug(8, "\t End of included file $1\n");
        push @OUTPUT, @{$input};
    }
    else
    {
        push @OUTPUT, $_;
    }
  }
  close $CONFIG;
  debug(6, "Configuration file $filename total output lines: ", $#OUTPUT,"\n");
  return(\@OUTPUT);
}

sub get_switchlist
{
  my @list = sort(keys(%Switchtypes));
  debug(5, "get_switchlist called\n");
  if (scalar(@list))
  {
    debug(5, "Returning ",$#list," Switch Names.\n");
    return \@list;
  }
  else
  {
    get_switchtype("anonymous");
    my @list = sort(keys(%Switchtypes));
    debug(5, "Returning ",scalar(@list)," Switch Names.\n");
    return \@list;
  }
}


sub get_switchtype
{
  my $hostname = shift(@_);
  my @list = sort(keys(%Switchtypes));
  debug(5, "get_switchtype called for $hostname.\n");
  # Preload the cache if we don't have a hit or are specifically called to preload ("anonymous")
  if (!exists($Switchtypes{$hostname}) || $hostname eq "anonymous")
  {
    my $switchtypes = read_config_file("switchtypes");
    foreach(@{$switchtypes})
    {
      my ($Name, $Num, $MgtVL, $IPv6Addr, $Type) = split(/\t+/, $_);
      debug(9,"switchtypes->$Name = ($Num, $MgtVL, $IPv6Addr, $Type)\n");
      $Switchtypes{$Name} = [ $Num, $MgtVL, $IPv6Addr, $Type ];
    }
  }
  # If we're just doing a cache preload, we're done.
  if ($hostname eq "anonymous")
  {
    return(undef);
  }
  # Perform consistency checks
  my @v6q = split(/:/, $Switchtypes{$hostname}[2]);
  if ($Switchtypes{$hostname}[1] != $v6q[3])
  {
    die("ERROR: Switch: $hostname Management VLAN (".$Switchtypes{$hostname}[1].
        ") does not match Address (".$Switchtypes{$hostname}[2].")\n");
  }
  # Return appropriate information
  return(@{$Switchtypes{$hostname}});
}

sub build_users_from_auth
{
  my %Keys;    # %Keys is actually a data structure. The Hash keys are
               # Usernames. The values are references to anonymous arrays.
               # The anonymous arrays contain references to anonymous hashes
               # which each contain a key 'type' and a key 'key' whose values
               # are the key type and public key text, respectively.
               #
               # e.g.
               # %Keys = {
               #	"username" => [
               #		{ "type" => "ssh-rsa", "key" => "<keytext>" },
               #		{ "type" => "ssh-ecdsa", "key" => "<keytext>" }
               #	]
               # }
  my $user;
  my $type;
  my $file;

  ##FIXME## In the future add support for users that don't get superuser

  foreach $file (glob("../authentication/keys/*"))
  {
    debug(9, "Examining key file $file\n");
    $file =~ /..\/authentication\/keys\/(.*)_id_(.*).pub/;
    if (length($1) < 3)
    {
      warn("Skipping key $file -- Invalid username $1\n");
      next;
    }
    $user = $1;
    $type = $2;
    debug(9, "\tFound USER $user type $type\n");
    open KEYFILE, "<$file" || die("Failed to open key file: $file\n");
    my $key = <KEYFILE>;
    chomp($key);
    close KEYFILE;
    if (!defined($Keys{$user}))
    {
      debug(9, "\t\tFirst key for USER $user\n");
      $Keys{$user} = [];
    }
    else
    {
      debug(9, "\t\tAdditional key for USER $user\n");
    }
    # Append anonymous hash reference onto list for $user.
    push @{$Keys{$user}},{ 'type' => $type, 'key' => $key };
  }
  my $OUTPUT = "";
  debug(9, "OUTPUT KEY ENTRIES...(", join(" ", sort(keys(%Keys))), ")\n");
  # Process each user
  foreach (sort keys(%Keys))
  {
    debug(9, "\tUser $_\n");
    $OUTPUT .= <<EOF;
        user $_ {
            class super-user;
            authentication {
EOF
    my $entry;
    # Go through the key entry list for $user. (${$entry}) is iterated through
    # the list of hash references for $user.
    foreach $entry (@{$Keys{$_}})
    {
      debug(9, "\t\tType: ".${$entry}{"type"}."\n");
      # Place the type and key text into JunOS configuration file format.
      $OUTPUT.= "                ssh-".${$entry}{"type"}." \"".
			${$entry}{"key"}."\";\n";
    }
    $OUTPUT .= <<EOF;
            }
        }
EOF
  }
  return($OUTPUT);
}

sub build_interfaces_from_config
{
  ##FIXME## There are a number of places where this subroutine assumes
  ##FIXME## that all interaces are ge-0/0/*
  ##FIXME## Covers all but fiber ports for SCALE 17x.
  my $hostname = shift @_;
  # Retrieve Switch Type Information
  my ($Number, $MgtVL, $IPv6addr, $Type) = get_switchtype($hostname);
  my $OUTPUT = "# Generated interface configuration for $hostname ".
			"(Type: $Type)\n";
  my $port = 0;
  # Read Type file and produce interface configuration
  my $switchtype = read_config_file("types/$Type");
  debug(9, "$hostname: type: $Type, received ", $#{$switchtype},
      " lines of config\n");
  $OUTPUT .= <<EOF;
    me-0 {
        unit 0 {
            family inet {
                    address 192.168.255.76/24;
            }
        }
    }
EOF
  foreach(@{$switchtype})
  {
    my @tokens = split(/\t/, $_); # Split line into tokens
    my $cmd = shift(@tokens);     # Command is always first token.
    debug(9, "\tCommand: $cmd ", join(",", @tokens), "\n");
    if ($cmd eq "RSRVD")
    {
      # Create empty ports matching reserved port count 
      my $portcount = shift(@tokens);
      while ($portcount)
      {
        debug(9, "\t\tPort ge-0/0/$port\n");
        $OUTPUT .= <<EOF;
    inactive: ge-0/0/$port {
        unit 0 {
            family ethernet-switching;
        }
    }
EOF
        $portcount--;
        $port++;
      }
    }
    elsif ($cmd eq "TRUNK" || $cmd eq "FIBER")
    {
      # Create specified TRUNK port -- Warn if it doesn't match port counter
      ##FIXME## This really should convert to using port counts like VLAN
      ##FIXME## Access ports do (except for FIBER directive).

      ##FIXME## Build interface ranges
      my $iface = shift(@tokens);
      my $vlans = shift(@tokens);
      debug(9, "\t\t$iface ($vlans)\n");
      $vlans =~ s/\s*,\s*/ /g;
      my $portnum = $iface;
      if ($cmd eq "TRUNK")
      {
        $portnum =~ s@^ge-0/0/(\d+)$@$1@;
        if ($portnum != $port)
        {
          warn("Port number in Trunk: $_ does not match expected port ".
			"$port (Host: $hostname, Type: $Type)\n");
        }
        # Safety -- Move past portnum if port was lower.
        $port = $portnum if ($portnum > $port);
        $port++;
      }
      ##FIXME## Put some sanity checking on fiber interface
      $OUTPUT .= <<EOF;
    $iface {
        description "$cmd Port ($vlans)";
        unit 0 {
            family ethernet-switching {
                port-mode trunk;
                vlan members [ $vlans ];
            }
        }
    }
EOF
    }
    elsif ($cmd eq "VLAN")
    {
      # Create specified number of interfaces as switchport members
      # of specified VLAN
      my $vlan = shift(@tokens);
      my $count = shift(@tokens);
      debug(9, "\t$count members of VLAN $vlan\n");
      # Use interface-ranges to make the configuration more readable

      # For convenience, use the VLAN name as the interface range name.
      
      ##FIXME## Using the VLAN name means only one definition per VLAN
      ##FIXME## in a types file is allowed, but this isn't validated.
      my $MEMBERS = "";
      while ($count)
      {
          debug(9, "\t\tMember ge-0/0/$port remaining $count\n");
          $MEMBERS.= "        member ge-0/0/$port;\n";
          $count--;
          $port++;
      }
      $OUTPUT .= <<EOF;
    interface-range $vlan {
        description "VLAN $vlan Interfaces";
        unit 0 {
            family ethernet-switching {
                port-mode access;
                vlan members $vlan;
            }
        }
$MEMBERS
    }
EOF
    }
    elsif ($cmd eq "VVLAN")
    {
      # Skip for now. Needs to be handled as a special case due to interaction of multiple
      # elements across multiple switches.
      # Account for the ports VVLAN directive takes up.
      my $count = shift(@tokens);
      $port += $count;
    }
  }
  return($OUTPUT);
}

sub build_l3_from_config
{
  my $hostname = shift @_;
  my ($Number, $MgtVL, $IPv6addr, $Type) = get_switchtype($hostname);
  my $OUTPUT = "        # Automatically Generated Layer 3 Configuration ".
                "for $hostname (MGT: $MgtVL Addr: $IPv6addr Type: $Type\n";
  $OUTPUT .= <<EOF;
        unit $MgtVL {
            family inet6 {
                address $IPv6addr/64;
            }
        }
EOF
  my $gw = get_default_gw($IPv6addr);
  return($OUTPUT, $gw);
}

sub build_vlans_from_config
{
  my $hostname = shift @_;
  my ($Number, $MgtVL, $IPv6addr, $Type) = get_switchtype($hostname);
  # MgtVL is treated special because it has a layer 3 interface spec
  # to interface vlan.$MgtVL.

  my $VL_CONFIG = read_config_file("vlans");
  # Convert configuration data to hash with VLAN ID as key
  my %VLANS;         # Hash containing VLAN data structure as follows:
                     # %VLANS = {
                     #     <VLANID> => [ <type>, <name>, <IPv6>,
                     #                   <IPv4>, <desc>, <prim> ],
                     #     ...
                     # }
  my %VLANS_byname;  # Hash mapping VLAN Name => ID
  my $OUTPUT = "";

  my $type;   # Type of VLAN (VLAN, PRIM, ISOL, COMM)
              # Where:
              #    VLAN = Ordinary VLAN
              #    PRIM = Primary PVLAN
              #    ISOL = Isolated Secondary PVLAN
              #    COMM = Community Secondary PVLAN
  my $name;   # VLAN Name
  my $vlid;   # VLAN ID (802.1q tag number)
  my $IPv6;   # IPv6 Prefix (For reference and possible future consistency
              #   checks). Not used in config generation for switches..
  my $IPv4;   # IPv4 Prefix (For reference and possible future consistency
              #   checks). Not used in config generation for switches..
  my $desc;   # Description
  my $prim;   # Primary VLAN Name (if this is a secondary (ISOL | COMM) VLAN)
  debug(9, "Got ", $#{$VL_CONFIG}, " Lines of VLAN configuraton\n");
  foreach(@{$VL_CONFIG})
  {
    my @TOKENS;
    @TOKENS = split(/\t/, $_);
    $prim = 0;
    $name = $TOKENS[1];
    if ($TOKENS[0] eq "VLAN") # Standard VLAN
    {
      $type = $TOKENS[0]; # VLAN
      $vlid = $TOKENS[2];
      $desc = $TOKENS[5];
      $IPv6 = $TOKENS[3];
      $IPv4 = $TOKENS[4];
      $VLANS_byname{$name} = $vlid;
      $VLANS{$vlid} = [ $type, $name, $IPv6, $IPv4, $desc, 
                        ($prim ? $prim : undef) ];
      debug(1, "VLAN $vlid => $name ($type) $IPv6 $IPv4 $prim $desc\n");
    }
    elsif ($TOKENS[0] eq "VVRNG") # Vendor VLAN Range Specification
    {
      # Skip this line here... Process elsewhere
    }
  }

  # Now that we have a hash containing all of the VLAN configurations, iterate
  # through and write out the switch configuration vlans {} section.
  foreach(sort(keys(%VLANS)))
  {
    ($type, $name, $IPv6, $IPv4, $desc, $prim) = @{$VLANS{$_}};
    if ($type eq "VLAN")
    {
      $OUTPUT .= <<EOF;
    $name {
        description "$desc";
        vlan-id $_;
EOF
      $OUTPUT .= "        l3-interface vlan.$_;\n" if ($_ eq $MgtVL);
      $OUTPUT .= "    }\n";
    }
    else
    {
        warn("Skipped unknown VLAN type ($_ => $name type=$type).\n");
    }
  }
  return($OUTPUT);
}


# Vendor VLAN subroutines
sub VV_get_prefix6
# Return the $VV_COUNT'th /64 prefix from $VV_prefix6 (if possible), or -1 if error.
##FIXME## This subroutine is very hacky. Should actually just do proper arithmetic
##FIXME## After converting the IPv6 prefix to a 64-bit integer and handling. Currently
##FIXME## Assumes prefix is longer than or equal to a /48 and we are issuing /64s.
{
  my $VV_COUNT = shift @_;
  my $VV_prefix6 = shift @_;
  debug(5, "VV_get_prefix6: Count: $VV_COUNT from prefix $VV_prefix6.\n");
  my ($net, $mask) = split(/\//, $VV_prefix6);
  $net = expand_double_colon($net);
  my @quartets = split(/:/, $net);
  my $n_bits = 64 - $mask;
  debug(5, "\tNet: $net Mask: $mask ($n_bits bits to play)\n");
  my $netbase = "";
  my $digitpfx = "";
  if ($n_bits > 16)
  {
    warn("Error: cannot support more than 9999 IPv6 VLANs (>16 bit variable field) for VVRNG\n");
    return -1;
  }
  $netbase = $quartets[3];
  if ($quartets[3] !~ /^\d+$/)
  {
    # Have to extract BCD compatible portion to netbase and treat rest as fixed.
    my @digits = split(//, $quartets[3]);
    while ($digits[0] !~ /^\d$/ && $#digits)
    {
      $digitpfx .= shift @digits; # Save hex prefix for later use
    }
    $netbase = join("", @digits);
    if ($netbase !~ /^\d+$/)
    {
      warn("Error: Supplied ipv6 not BCD cmpatible for VVRNG\n");
      return -1;
    }
  }
  my $netmax;
  if ($n_bits % 4)
  {
    $netmax = $netbase + 10 ** ($n_bits/4) + (2 ** (($n_bits % 4) -1) * (10 ** ($n_bits/4))) - 1 ;
  }
  else
  {
    $netmax = $netbase + 10 ** ($n_bits/4) - 1;
  }
  debug(5, "IPv6 Netmax (Base = $netbase with $n_bits) $netmax\n");
  my $candidate = $netbase + $VV_COUNT;
  debug(5, "\tCandidate: $candidate\n");
  return -1 if ($candidate > $netmax);
  $candidate = $digitpfx.$candidate; # Restore hex prefix if needed
  debug(5, "\tReturning: ".$quartets[0].":".$quartets[1].":".$quartets[2].":".$candidate."::/64\n");
  return($quartets[0].":".$quartets[1].":".$quartets[2].":".$candidate."::/64");
}

sub VV_get_prefix4
# Return the $VV_COUNT'th /24 prefix from $VV_prefix4 (if possible), or -1 if error.
{
  my $VV_COUNT = shift @_;
  my $VV_prefix4 = shift @_;
  my ($net, $mask) = split(/\//, $VV_prefix4);
  debug(5, "VV_get_prefix4 Count: $VV_COUNT Prefix: $net Mask: $mask\n");
  my @octets = split(/\./, $net);
  my $netbase = ($octets[0] << 24) + ($octets[1] << 16) + ($octets[2] << 8) + $octets[3];
  my $n = ((2 ** (32 - $mask)) / 256);
  debug(5, "\t\tAllows $n Vendor VLANs.\n");
  my $netmax = $netbase + (2 ** (32 - $mask)) -1;
  my $candidate = $netbase + ($VV_COUNT << 8);
  debug(5, "\tBase: $netbase Max: $netmax Candidate: $candidate\n");
  return(-1) if ($candidate > $netmax);
  debug(5, "\tBase:\n");
  debug(5, "\t\t3 -> ($netbase ->)", $netbase % 256, ".\n");
  $octets[3] = ($netbase % 256);
  $netbase >>= 8;
  debug(5, "\t\t2 -> ($netbase ->)", $netbase % 256, ".\n");
  $octets[2] = ($netbase % 256);
  $netbase >>= 8;
  debug(5, "\t\t1 -> ($netbase ->)", $netbase % 256, ".\n");
  $octets[1] = ($netbase % 256);
  $netbase >>= 8;
  debug(5, "\t\t0 -> ($netbase ->)", $netbase % 256, ".\n");
  debug(5, "\tMAX:\n");
  debug(5, "\t\t3 -> ($netmax ->)", $netmax % 256, ".\n");
  $octets[3] = ($netmax % 256);
  $netmax >>= 8;
  debug(5, "\t\t2 -> ($netmax ->)", $netmax % 256, ".\n");
  $octets[2] = ($netmax % 256);
  $netmax >>= 8;
  debug(5, "\t\t1 -> ($netmax ->)", $netmax % 256, ".\n");
  $octets[1] = ($netmax % 256);
  $netmax >>= 8;
  debug(5, "\t\t0 -> ($netmax ->)", $netmax % 256, ".\n");
  $octets[0] = ($netmax % 256);
  debug(5, "\tResult: ".join(".", @octets)."/24.\n");
  debug(5, "\tCandidate:\n");
  debug(5, "\t\t3 -> ($candidate ->)", $candidate % 256, ".\n");
  $octets[3] = ($candidate % 256);
  $candidate >>= 8;
  debug(5, "\t\t2 -> ($candidate ->)", $candidate % 256, ".\n");
  $octets[2] = ($candidate % 256);
  $candidate >>= 8;
  debug(5, "\t\t1 -> ($candidate ->)", $candidate % 256, ".\n");
  $octets[1] = ($candidate % 256);
  $candidate >>= 8;
  debug(5, "\t\t0 -> ($candidate ->)", $candidate % 256, ".\n");
  $octets[0] = ($candidate % 256);
  debug(5, "\tResult: ".join(".", @octets)."/24.\n");
  return(join(".", @octets)."/24");
}

sub VV_get_vlid
# Return the $VV_COUNT'th vlan ID from $VV_LOW to $VV_HIGH (if possible), or -1 if error.
{
  my $VV_COUNT = shift @_;
  my $candidate = $VV_LOW + $VV_COUNT;
  return -1 if ($candidate > $VV_HIGH);
  return $candidate;
}

sub VV_init_firewall
# Return a string contiaing the base firewall configuration fragment for a switch
{
  my  $VV_firewall = <<EOF;
    family inet {
        filter only_to_internet {
            term dns {
                from {
                    destination-address {
                        10.0.3.0/24;
                        10.128.3.0/24;
                    }
                    destination-port domain;
                }
                then {
                    accept;
                }
            }
            term dhcp {
                from {
                    destination-address {
                        10.0.3.0/24;
                        10.128.3.0/24;
                    }
                    destination-port [ bootps dhcp ];
                }
            }
            term no-rfc1918 {
                from {
                    destination-address {
                        10.0.0.0/8;
                        172.16.0.0/12;
                        192.168.0.0/16;
                    }
                }
                then {
                    reject;
                }
            }
            term to-internet {
                from {
                    destination-address {
                        0.0.0.0/0;
                    }
                }
                then {
                    accept;
                }
            }
        }
        filter only_from_internet {
            term dns {
                from {
                    source-address {
                        10.0.3.0/24;
                        10.128.3.0/24;
                    }
                    source-port domain;
                }
                then {
                    accept;
                }
            }
            term dhcp {
                from {
                    source-address {
                        10.0.3.0/24;
                        10.128.3.0/24;
                    }
                    source-port [ bootps dhcp ];
                }
                then {
                    accept;
                }
            }
            term no-rfc1918 {
                from {
                    source-address {
                        10.0.0.0/8;
                        172.16.0.0/12;
                        192.168.0.0/16;
                    }
                }
                then {
                    discard;
                }
            }
            term to-internet {
                from source-address {
                    0.0.0.0/0;
                }
                then {
                    accept;
                }
            }
        }
    }
    family inet6 {
        filter only_to_internet6 {
          term dns {
                from {
                    destination-address {
                        2001:470:f325:103::/64;
                        2001:470:f325:503::/64;
                    }
                    destination-port domain;
                }
                then {
                    accept;
                }
          }
          term dhcp {
                from {
                    destination-address {
                        2001:470:f325:103::/64;
                        2001:470:f325:503::/64;
                    }
                    destination-port [ bootps dhcp ];
                }
                then {
                    accept;
                }
          }
          term no-local {
                from {
                    destination-address {
                        2001:470:f325::/48;
                        fc00::/7;
                    }
                }
                then {
                    reject;
                }
          }
          term to-internet {
                from {
                    destination-address {
                        ::/0;
                    }
                }
                then {
                    accept;
                }
            }
        }
        filter only_from_internet6 {
          term dns {
                from {
                    source-address {
                        2001:470:f325:103::/64;
                        2001:470:f325:503::/64;
                    }
                    source-port domain;
                }
                then {
                    accept;
                }
          }
          term dhcp {
                from {
                    source-address {
                        2001:470:f325:103::/64;
                        2001:470:f325:503::/64;
                    }
                    source-port [ bootps dhcp ];
                }
                then {
                    accept;
                }
          }
          term no-local {
                from {
                    source-address {
                        2001:470:f325::/48;
                        fc00::/7;
                    }
                }
                then {
                    discard;
                }
          }
          term to-internet {
                from {
                    source-address {
                        ::/0;
                    }
                }
                then {
                    accept;
                }
          }
        }
    }
EOF
  return $VV_firewall;
}



sub build_vendor_from_config
# Return a reference to a hash containing the following elements:
# "interfaces" -> An interface configuration fragment for all Vendor related VLAN interfaces
# "vlans"      -> A vlan configuration fragment for all Vendor related VLANs
# "vlans_l3"    -> An interface configuration fragment for all Vendor VLAN L3 interfaces
# "defgw_ipv4" -> A routing-options configuration fragment to provide an IPv4 default gateway for the Vendor VLANs
# "firewall"   -> A firewall configuration fragment to provide the necessary filters to prevent Vendor VLANs from attacking others.
# "dhcp"       -> A forwarding-options configuration fragment to provide dhcp-relay configuration
{
  my $hostname = shift @_;
  debug(5, "Building Vendor VLANs for $hostname\n");
  # Retrieve Switch Type Information
  my ($Number, $MgtVL, $IPv6addr, $Type) = get_switchtype($hostname);
  
  my $port = 0;
  # Read Type file and produce interface configuration
  my $switchtype = read_config_file("types/$Type");
  debug(5, "$hostname: type: $Type, received ", scalar(@{$switchtype}),
      " lines of config\n");
  
  my $VV_interfaces = "";
  my $VV_vlans = "";
  my $VV_vlans_l3 = "";
  my $VV_defgw_ipv4 = "";
  my $VV_firewall = "";
  my $VV_dhcp = "";
  my $VV_portcount = 0;
  my @VV_intlist = ();
  my $VV_protocols = "";
  # Construct empty hashref to use later for return value
  my $VV_hashref = {
  };

  my $intnum = 0;
  foreach(@{$switchtype})
  {
    my @tokens = split(/\t/, $_); # Split line into tokens
    my $cmd = shift(@tokens);     # Command is always first token.
    debug(5, "\tCommand: $cmd (intnum: $intnum)", join(",", @tokens), "\n");
    if ($cmd eq "RSRVD")
    {
      # Skip -- Not vendor VLAN related, handled elsewhere
      # Need to account for the interfaces, though.
      my $count = $tokens[0];
      $intnum += $count;
      debug(5, "\t\tSkipping $count reserved ports, new intnum $intnum.\n");
    }
    elsif ($cmd eq "TRUNK" || $cmd eq "FIBER")
    {
      # Skip -- Not vendor VLAN related, handled elsewhere
      # Need to account for the interfaces, though.
      my $iname = $tokens[0];
      my ($name,$instance) = split(/-/, $iname);
      my ($fpc, $slot, $port) = split(/\//, $instance);
      $intnum = $port+1 if ($port >= $intnum);
      debug(5, "\t\tFound port definition for $name-$fpc/$slot/$port, new intnum $intnum.\n");
    }
    elsif ($cmd eq "VLAN")
    {
      # Skip -- Not vendor VLAN related, handled elsewhere
      # Need to account for the interfaces, though.
      my $count = $tokens[0];
      $intnum += $count;
      debug(5, "\t\tSkipping $count vlan ports, new intnum $intnum.\n");
    }
    elsif ($cmd eq "VVLAN")
    {
      debug(5, "Command: $cmd ", join(",", @tokens),"\n");
      # Determine number of ports to build out
      my $count = $tokens[0];
      $VV_portcount = $count;
      # Build config fragments for each interface.
      debug(5, "Building $count Vendor Interfaces starting at ge-0/0/$intnum\n");


      # Initialize config fragments. These initialized values (may) get appended to for each interface.
      $VV_interfaces = "";
      ##FIXME## Given that the Vendor VLAN Backbone is hard coded, this is a little bit silly, but avoids a dangling
      ##FIXME## timebomb if that ever gets corrected.
      my $v4_nexthop = ($MgtVL < 500) ? "10.2.0.1" : "10.130.0.1";
      debug(5, "Vendor v4_nexthop set to $v4_nexthop\n");
      ##FIXME## Vendor VLAN Backbone should come from a configuration file. This is a terrible hack for expedience
      ##FIXME## It means that 10.1.0.0/24 needs to be remembered and avoided which is a major timebomb in the code.
      $VV_vlans = <<EOF;
    vendor_backbone {
        description "Vendor Backbone";
        vlan-id 499;
        l3-interface vlan.499;
    }
EOF
      my $ipv4_suffix = $VV_COUNT + 10;
      $VV_vlans_l3 = <<EOF;
        unit 499 {
            family inet {
                address 10.1.0.$ipv4_suffix/24;
            }
        }
EOF
      $VV_defgw_ipv4 = <<EOF;
    static {
        route 0.0.0.0/0 next-hop $v4_nexthop;
    }
EOF
      $VV_firewall = VV_init_firewall();

      while ($count)
      {
        my $VLID = VV_get_vlid($VV_COUNT);
        debug(5, "$count remaining -- VV_COUNT $VV_COUNT, VLID $VLID.\n");
        if ($VLID < 0)
        {
          die("ERROR: Not enough Vendor VLANs defined in VVRNG.\n");
        }
        my $VL_prefix6 = VV_get_prefix6($VV_COUNT, $VV_prefix6);
        debug(5, "\tVL_prefix6 $VL_prefix6.\n");
        if ($VL_prefix6 < 0)
        {
          die("ERROR: Couldn't get IPv6 prefix for Vendor VLAN ($VV_COUNT)\n");
        }
        my $VL_prefix4 = VV_get_prefix4($VV_COUNT, $VV_prefix4);
        debug(5, "\tVL_prefix4 $VL_prefix4.\n");
        if ($VL_prefix4 < 0)
        {
          die("ERROR: Couldn't get IPv4 prefix for Vendor VLAN ($VV_COUNT)\n");
        }
#	"interfaces"  -> $VV_interfaces,
#       context: interfaces { <here> }
        $VV_interfaces .= <<EOF;
    ge-0/0/$intnum {
        unit 0 {
            description "Vendor VLAN $VLID"
            family ethernet-switching {
                port-mode access;
                vlan {
                    members vendor-vlan-$VLID;
                }
            }
        }
    }
EOF
#	"vlans"       -> $VV_vlans,
#	context: vlans { <here> }
    debug(5, "Name_prefix: x$VV_name_prefix"."x VLID: x$VLID"."x\n");
    my $vv_name = $VV_name_prefix.$VLID;
        $VV_vlans .= <<EOF;
    $vv_name {
        vlan-id $VLID
        l3-interface vlan.$VLID;
    }
EOF
#	"vlans_l3"    -> $VV_vlans_l3,
#       context: interfaces { vlan { <here> ... [}] }
        my ($pref,$mask) = split(/\//, $VL_prefix4);
        debug(5, "L3 Interface $VLID v4 = $pref / $mask.\n");
        $pref =~ s/\.0$/.1/;
        debug(5, "\t-> $pref\n");
        my $VL_addr4 = join("/", $pref, $mask);
        ($pref,$mask) = split(/\//, $VL_prefix6);
        debug(5, "L3 Interface $VLID v6 = $pref / $mask.\n");
        $pref =~ s/::$/::1/;
        debug(5, "\t-> $pref\n");
        my $VL_addr6 = join("/", $pref, $mask);
        debug(5, "L3 Interface $VLID -- v4 = $VL_addr4, v6 = $VL_addr6\n");
        $VV_vlans_l3 .= <<EOF;
        unit $VLID {
            family inet {
                address $VL_addr4;
                filter input only_to_internet;
                filter output only_from_internet;
            }
            family inet6 {
                address $VL_addr6;
                filter input only_to_internet6;
                filter output only_from_internet6;
            }
        }
EOF
# These two are simply used in their initialized state (currently)...
#	"defagw_ipv4" -> $VV_defgw_ipv4,
#	"firewall"    -> $VV_firewall,

#	"dhcp"        -> $VV_dhcp,
#       Build list of Vendor VLAN Interfaces for later use to build DHCP forwarders
        push @VV_intlist, "vlan.$VLID";


        # Increment / decrement counters
        $intnum++;	# Next interface (ge-0/0/{$intnum})
        $VV_COUNT++;	# Vendor VLAN Counter
        $count--;	# Remaining unprocessed interfaces in this group
      }
    }
  }
  # Finish up strings that need to be terminated (currently just $VV_vlans_l3)
  # Finalize DHCP Forwarder configuration
  my $active_srv_grp = ($MgtVL < 500) ? "Expo" : "Conference";
  $VV_dhcp = <<EOF;
forwarding-options {
    dhcp-relay {
        dhcpv6 {
            group vendors {

EOF

  foreach (@VV_intlist)
  {
    $VV_dhcp .= <<EOF;
                interface $_;
EOF

  }

  $VV_dhcp .= <<EOF;
            }
            server-group {
                Conference {
                    2001:470:f325:503::5;
                }
                Expo {
                    2001:470:f325:103::5;
                }
                AV {
                    2001:470:f325:105::10;
                }
            }
            active-server-group $active_srv_grp;
        }
        server-group {
            Conference {
                10.128.3.5;
            }
            Expo {
                10.0.3.5;
            }
            AV {
                10.0.5.10;
            }
        }
        active-server-group $active_srv_grp;
        group vendors {
EOF

  foreach (@VV_intlist)
  {
    $VV_dhcp .= <<EOF;
                interface $_;
EOF

  }

  $VV_dhcp .= <<EOF;
        }
    }
}
EOF

#    "protocols"    -> $VV_protocols
#   Build OSPF configuration to advertise Vendor VLANs across vendor-backbone network
#   Context: protocols { <here> }
  $VV_protocols = <<EOF;
    ospf {
        area 0.0.0.0 {
            interface vlan.499;
EOF
  foreach (@VV_intlist)
  {
     $VV_protocols .= <<EOF;
            interface $_ {
                passive;
            }
EOF
  }

  $VV_protocols .= <<EOF;
        }
    }
    ospf3 {
        area 0.0.0.0 {
            interface vlan.499;
EOF

  foreach (@VV_intlist)
  {
     $VV_protocols .= <<EOF;
            interface $_ {
                passive;
            }
EOF
  }

  $VV_protocols .= <<EOF;
        }
    }
EOF


  if ($VV_portcount == 0) # No VVLAN statement encountered.
  {
    return(0);
  }
  else
  {
    # Put cooked values into initialized hashref
    my $VV_hashref = {
        "interfaces"  => $VV_interfaces,
        "vlans"       => $VV_vlans,
        "vlans_l3"    => $VV_vlans_l3,
        "defagw_ipv4" => $VV_defgw_ipv4,
        "firewall"    => $VV_firewall,
        "dhcp"        => $VV_dhcp,
        "protocols"   => $VV_protocols,
    };
    debug(5, "Returning Vendor parameters:\n");
    debug(5, Dumper($VV_hashref));
    return($VV_hashref);
  }
}

# Put it all together
sub build_config_from_template
{
  # Add input variables here:
  my $hostname = shift @_;
  my $root_auth = shift @_;
  
  # Add configuration file fetches here:
  my $USER_AUTHENTICATION = build_users_from_auth();
  my $INTERFACES_PHYSICAL = build_interfaces_from_config($hostname);
  my $VLAN_CONFIGURATION = build_vlans_from_config($hostname);
  my $vcfg = build_vendor_from_config($hostname);
  my %VENDOR_CONFIGURATION = {};
  %VENDOR_CONFIGURATION = %{$vcfg} if (reftype $vcfg eq reftype {});;
  debug(5, "Received Vendor configuration:\n");
  debug(5, Dumper(%VENDOR_CONFIGURATION));
  debug(5, "End Vendor Config\n");
  my ($INTERFACES_LAYER3, $IPV6_DEFGW) = build_l3_from_config($hostname);
  $INTERFACES_PHYSICAL .= ${VENDOR_CONFIGURATION}{"interfaces"};
  $VLAN_CONFIGURATION  .= ${VENDOR_CONFIGURATION}{"vlans"};
  $INTERFACES_LAYER3   .= ${VENDOR_CONFIGURATION}{"vlans_l3"};
  my $IPV4_DEFGW           = ${VENDOR_CONFIGURATION}{"defgw_ipv4"};
  my $FIREWALL_CONFIG   = ${VENDOR_CONFIGURATION}{"firewall"};
  my $DHCP_CONFIG       = ${VENDOR_CONFIGURATION}{"dhcp"};
  my $PROTOCOL_CONFIG   = ${VENDOR_CONFIGURATION}{"protocols"};
  my $OUTPUT = <<EOF;
system {
    host-name $hostname;
    root-authentication {
        encrypted-password "$root_auth";
    }
    syslog {
        host loghost {
        any any;
        }
    }
    login {
$USER_AUTHENTICATION
    }
    services {
        ssh {
            protocol-version v2;
        }
        netconf {
            ssh;
        }
    }
    syslog {
        user * {
            any emergency;
        }
        file messages {
            any notice;
            authorization info;
        }
        file interactive-commands {
            interactive-commands any;
        }
    }
}
chassis {
    alarm {
        management-ethernet {
        link-down ignore;
        }
    }
}
snmp {
    community Junitux {
        authorization read-only;
        clients {
        2001:470:f325:103::/64;
        2001:470:f325:503::/64;
        }
    }
}
interfaces {
$INTERFACES_PHYSICAL
    vlan {
$INTERFACES_LAYER3
    }
}
$DHCP_CONFIG
routing-options {
    $IPV4_DEFGW
    rib inet6.0 {
        static {
            route ::/0 next-hop $IPV6_DEFGW;
        }
    }
}
protocols {
    igmp-snooping {
        vlan all;
    }
    rstp;
    lldp {
        interface all;
    }
    lldp-med {
        interface all;
    }
$PROTOCOL_CONFIG;
}
firewall {
$FIREWALL_CONFIG
}
ethernet-switching-options {
    storm-control {
        interface all;
    }
}
vlans {
$VLAN_CONFIGURATION
}
EOF

  return($OUTPUT);
}

#my $cf = build_config_from_template("NW-IDF",
#    '$1$qQMsQS3c$DmHnv3mHPwDuE/ILQ.yLl.');
#print $cf;

1;
