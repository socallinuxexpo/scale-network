#!/usr/bin/perl
#
# This script must be run from the .../config directory (the parent directory
# of the scripts directory where this script lives. All scripts are expected
# to be run from this location for consistency and ease of use.


##FIXME## Build a consistency check to match up VLANs in the vlans file(s) and
##FIXME## those defined in the types/* files.

use strict;
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
  if (defined($Switchtypes{$hostname}))
  {
    return(@{$Switchtypes{$hostname}});
  }
  elsif($hostname ne "anonymous" && scalar(@list))
  {
      die("Name: $hostname not found in switchtypes file\n");
  }
  else
  {
    # Read configuration file and build cache
    debug(5, "Building switchtypes cache\n");
    my $switchtypes = read_config_file("switchtypes");
    foreach(@{$switchtypes})
    {
      my ($Name, $Num, $MgtVL, $IPv6Addr, $Type) = split(/\t+/, $_);
      debug(9,"switchtypes->$Name = ($Num, $MgtVL, $IPv6Addr, $Type)\n");
      $Switchtypes{$Name} = [ $Num, $MgtVL, $IPv6Addr, $Type ];
    }
    if ($hostname ne "anonymous" && !defined($Switchtypes{$hostname}))
    {
      die("Name: $hostname not found in switchtypes file\n");
    }
    return(@{$Switchtypes{$hostname}}) unless($hostname eq "anonymous");
    return(undef);
  }
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
  ##FIXME## Covers all but fiber ports for SCALE 16x.
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
        $portnum =~ s@^ge-0/0/(\d+)$@\1@;
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
  }
  return($OUTPUT);
}

sub build_l3_from_config
{
  my $hostname = shift @_;
  my ($Number, $MgtVL, $IPv6addr, $Type) = get_switchtype($hostname);
  my $OUTPUT = "    # Automatically Generated Layer 3 Configuration ".
                "for $hostname (MGT: $MgtVL Addr: $IPv6addr Type: $Type\n";
  $OUTPUT .= <<EOF;
    vlan {
        unit $MgtVL {
            family inet6 {
                address $IPv6addr/64;
            }
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
    if ($TOKENS[0] eq "SVLAN") # Secondary PVLAN
    {
      $type = $TOKENS[2];
      $vlid = $TOKENS[3];
      $prim = $TOKENS[4];
      $desc = $TOKENS[5];
      my $pvlid = $VLANS_byname{$prim};
      debug(1, "PVLAN Lookup for $prim\n");
      # For Secondary VLANs, retrieve prefix from Primary
      $IPv6 = $VLANS{$pvlid}[2];
      $IPv4 = $VLANS{$pvlid}[3];
    }
    else
    {
      $type = $TOKENS[0]; # VLAN or PVLAN
      $vlid = $TOKENS[2];
      $desc = $TOKENS[5];
      $IPv6 = $TOKENS[3];
      $IPv4 = $TOKENS[4];
    }
    $type = "PRIM" if ($type eq "PVLAN"); # FIXUP Type
    debug(1, "VLAN $vlid => $name ($type) $IPv6 $IPv4 $prim $desc\n");
    $VLANS_byname{$name} = $vlid;
    $VLANS{$vlid} = [ $type, $name, $IPv6, $IPv4, $desc, 
                      ($prim ? $prim : undef) ];
  }

  # Now that we have a hash containing all of the VLAN configurations, iterate
  # through and write out the switch configuration vlans {} section.
  ##FIXME## Need to figure out how to integrate interfaces and trunks,
  ##FIXME## especially pvlan trunks. currently not handled. Manual config
  ##FIXME## Edits will be required (This will be noted in generated config).
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
    elsif ($type eq "PRIM")
    {
      $OUTPUT .= <<EOF;
    $name {
        description "$desc";
        vlan-id $_;
        interface {
            ### WARNING ### Trunks must be manually configured
            # ge-0/1/0.0 {
            #     pvlan-trunk;
            # }
        }
        no-local-switching;
        isolation-id 2$_;
      }
EOF
    }
    elsif ($type eq "COMM")
    {
      $OUTPUT .= <<EOF;
    $name {
        description "COMMUNITY $desc";
        vlan-id $_;
        primary-vlan $prim;
    }
EOF
    }
    elsif ($type eq "ISOL")
    {
      $OUTPUT .= <<EOF;
    $name {
        description "ISOLATED $desc";
        vlan-id $_;
        primary-vlan $prim;
        no-local-switching;
        isolation-id $_;
    }
EOF
    }
    else
    {
        warn("Skipped unknown VLAN type ($_ => $name type=$type).\n");
    }
  }
  return($OUTPUT);
}


sub build_config_from_template
{
  # Add input variables here:
  my $hostname = shift @_;
  my $root_auth = shift @_;
  
  # Add configuration file fetches here:
  my $USER_AUTHENTICATION = build_users_from_auth();
  my $INTERFACES_PHYSICAL = build_interfaces_from_config($hostname);
  my $VLAN_CONFIGURATION = build_vlans_from_config($hostname);
  my ($INTERFACES_LAYER3, $IPV6_DEFGW) = build_l3_from_config($hostname);

  my $OUTPUT = <<EOF;
system {
    host-name $hostname;
    root-authentication {
        encrypted-password "$root_auth";
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
interfaces {
    $INTERFACES_PHYSICAL
    $INTERFACES_LAYER3
}
routing-options {
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
