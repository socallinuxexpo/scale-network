#!/usr/bin/perl
use strict;

my %Switchtypes;

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
    open SWITCHTYPES, "<config/switchtypes" || die("Failed to open switchtypes file\n");
    foreach(<SWITCHTYPES>)
    {
      chomp;
      my ($Name, $Num, $MgtVL, $IPv6Addr, $Type) = split(/\t/, $_)
      $Switchtypes{$Name} = [ $Num, $MgtVL, $IPv6Addr, $Type ];
    }
    return(@{$Switchtypes{$hostname}});
}
  

sub build_users_from_auth
{
  my %Keys;
  my $user;
  my $type;
  my $file;
  foreach $file (glob("../authentication/keys/*"))
  {
    print STDERR "Examining key file $file\n";
    $file =~ /..\/authentication\/keys\/(.*)_id_(.*).pub/;
    if (length($1) < 3)
    {
      warn("Skipping key $file -- Invalid username $1\n");
      next;
    }
    $user = $1;
    $type = $2;
    print STDERR "\tFound USER $user type $type\n";
    open KEYFILE, "<$file" || die("Failed to open key file: $file\n");
    my $key = <KEYFILE>;
    close KEYFILE;
    if (!defined($Keys{$user}))
    {
      print STDERR "\t\tFirst key for USER $user\n";
      $Keys{$user} = [];
    }
    else
    {
      print STDERR "\t\tAdditional key for USER $user\n";
    }
    push @{$Keys{$user}},{ 'type' => $type, 'key' => $key };
  }
  my $OUTPUT = "";
  print STDERR "OUTPUT KEY ENTRIES...(", join(" ", sort(keys(%Keys))), ")\n";
  foreach (sort keys(%Keys))
  {
    print STDERR "\tUser $_\n";
    $OUTPUT .= <<EOF;
        user $_ {
            class super-user;
            authentication {
EOF
    my $entry;
    foreach $entry (@{$Keys{$_}})
    {
      print STDERR "\t\tType: ".${$entry}{"type"}."\n";
      $OUTPUT.= "                ssh-".${$entry}{"type"}." \"".${$entry}{"key"}."\";\n";
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
  my $hostname = shift @_;
  my $OUTPUT = "";
  # Retrieve Switch Type Information
  my ($Number, $MgtVL, $IPv6addr, $Type) = get_switchtype($hostname);
  # Read Type file and produce interface configuration
  return("            ##### Interface configuration goes here\n");
}

sub build_l3_from_config
{
  my $hostname = shift @_;
  return("            ##### Layer 3 configuration goes here\n", "2001:470:dead:beef::1");
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
  my ($INTERFACES_LAYER3, $IPV6_DEFGW) = build_l3_from_config($hostname);
  my $VLAN_CONFIGURATION = build_vlans_from_config($hostname);

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

my $cf = build_config_from_template("Expo5",'$1$qQMsQS3c$DmHnv3mHPwDuE/ILQ.yLl.');
print $cf;

1;
