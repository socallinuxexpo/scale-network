#!/usr/bin/perl
use strict;

my $DEBUGLEVEL = 5;

my %Switchtypes;

sub debug
{
  my $lvl = shift(@_);
  my $msg = join("", @_);
  print STDERR $msg if ($lvl >= $DEBUGLEVEL);
}

sub read_config_file
{
  my $filename = shift(@_);
  my @OUTPUT;
  open CONFIG, "<$filename" || die("Failed to open $filename as CONFIG\n");
  while ($_ = <CONFIG>)
  {
    chomp;
    debug(5, "Based input: $_\n");
    while ($_ =~ s/ \\$/ /)
    {
      my $x = <CONFIG>;
      chomp($x);
      $x =~ s/^\s*//;
      debug(5, "\tC->: $x\n");
      $_ .= $x;
    }
    $_ =~ s@//.*@@; # Eliminate comments
    next if ($_ =~ /^\s*$/); # Ignore blank lines
    $_ =~ s/\t+/\t/g;
    debug(5, "Cooked output: $_\n");
    push @OUTPUT, $_;
  }
  return(\@OUTPUT);
}
sub get_switchtype
{
  my $hostname = shift(@_);
  if (defined($Switchtypes{$hostname}))
  {
    return(@{$Switchtypes{$hostname}});
  }
  else
  {
    # Read configuration file and build cache
    my $switchtypes = read_config_file("switchtypes");
    foreach(@{$switchtypes})
    {
      my ($Name, $Num, $MgtVL, $IPv6Addr, $Type) = split(/\t+/, $_);
      debug(5,"switchtypes->$Name = ($Num, $MgtVL, $IPv6Addr, $Type)\n");
      $Switchtypes{$Name} = [ $Num, $MgtVL, $IPv6Addr, $Type ];
    }
    if (!defined($Switchtypes{$hostname}))
    {
      die("Name: $hostname not found in switchtypes file\n");
    }
    return(@{$Switchtypes{$hostname}});
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
  # that all interaces are ge-0/0/*
  # Covers all but fiber ports for SCALE 16x.
  my $hostname = shift @_;
  # Retrieve Switch Type Information
  my ($Number, $MgtVL, $IPv6addr, $Type) = get_switchtype($hostname);
  my $OUTPUT = "# Generated interface configuration for $hostname ".
			"(Type: $Type)\n";
  my $port = 0;
  # Read Type file and produce interface configuration
  my $switchtype = read_config_file("types/$Type");
  debug(5, "$hostname: type: $Type, received ", $#{$switchtype},
      " lines of config\n");
  foreach(@{$switchtype})
  {
    my @tokens = split(/\t/, $_); # Split line into tokens
    my $cmd = shift(@tokens);     # Command is always first token.
    debug(5, "\tCommand: $cmd ", join(",", @tokens), "\n");
    if ($cmd eq "RSRVD")
    {
      # Create empty ports matching reserved port count 
      my $portcount = shift(@tokens);
      while ($portcount)
      {
        debug(5, "\t\tPort ge-0/0/$port\n");
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
      # Access ports do (except for FIBER directive).
      ##FIXME## Build interface ranges
      my $iface = shift(@tokens);
      my $vlans = shift(@tokens);
      debug(5, "\t\t$iface ($vlans)\n");
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
      debug(5, "\t$count members of VLAN $vlan\n");
      # Use interface-ranges to make the configuration more readable

      # For convenience, use the VLAN name as the interface range name.
      
      ##FIXME## Using the VLAN name means only one definition per VLAN
      # in a types file is allowed, but this isn't validated.
      my $MEMBERS = "";
      while ($count)
      {
          debug(5, "\t\tMember ge-0/0/$port remaining $count\n");
          $MEMBERS.= "        ge-0/0/$port;\n";
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
    elsif ($cmd eq "PVLAN")
    {
      # Create specified number of PVLAN ports. Ideally, use Vendor booth
      # information table and Expo switch location information to
      # determine which vendors are served and allocate community VLANs
      # and put 2 ports into each applicable community VLAN.
      #
      ##FIXME##
      # In this version, just create ports in the global isolation VLAN
      # and allow for moving them into community VLANs manually later.

      ##FIXME## Finish this section
    }
  }
  return($OUTPUT);
}

sub build_l3_from_config
{
  my $hostname = shift @_;
  return("            ##### Layer 3 configuration goes here\n",
			"2001:470:dead:beef::1");
}

sub build_vlans_from_config
{
  my $hostname = shift @_;
  return("            #### VLAN configuration goes here\n");
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
interfaces {
    $INTERFACES_PHYSICAL
    $INTERFACES_LAYER3
    }
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

my $cf = build_config_from_template("NW-IDF",
    '$1$qQMsQS3c$DmHnv3mHPwDuE/ILQ.yLl.');
print $cf;

1;
