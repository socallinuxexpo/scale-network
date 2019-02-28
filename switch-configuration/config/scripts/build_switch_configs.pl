#!/usr/bin/env perl
#
# This script will iterate through each of the switches named in the switchtypes
# file and produce a configuration file for that switch named <switchname>.conf
#
require "./scripts/switch_template.pl";   # Pull in configuration library
set_debug_level(5);
my $switchlist = get_switchlist();
my $switch;

if(scalar(@ARGV)) # One or more switch names specified
{
    $switchlist = \@ARGV;
}
else
{
    ##FIXME## Probably should evaluate switch list and remove any entries
    ##FIXME## that no longer exist from output directory.
    my @outputs = ();
    my $file;
    if (scalar(@ARGV))
    # Selectively delete only configurations we are rebuilding
    {
        foreach $file (@{$switchlist})
        {
            push @outputs, $file.".conf";
        }
    }
    else
    # Rebuild entire config set, so start with empty output directory
    {
        @outputs = glob("output/*");
    }
    foreach $file (@outputs)
    {
        unlink($file) || die "Failed to delete $file: $!\n";
        debug(3, "Deleted $file from output directory\n");
    }
}

# Pull in data necessary for VVLAN handling and prepare it.
# Use of global variables here is ugly, but due to the need to maintain a lot of
# shared state information, there's no easy to code better way.
#
# Hopefully this all eventually goes away in favor of Ansible next year, so not
# worth a lot of focus to improve now.
our $VL_CONFIG = read_config_file("vlans");
our $VV_name_prefix;
our $VV_LOW;
our $VV_HIGH;
our $VV_COUNT=0;
our $VV_prefix6;
our $VV_prefix4;

foreach(@{$VL_CONFIG})
{
  my @TOKENS;
  @TOKENS = split(/\t/, $_);
  next if ($TOKENS[0] ne "VVRNG");
  die "Error: Multiple VVRNG statements encountered!\n" if ($VV_name_prefix);
  $VV_name_prefix = $TOKENS[1];
  ($VV_LOW, $VV_HIGH) = split(/\s*-\s*/, $TOKENS[2]);
  $VV_prefix6 = $TOKENS[3];
  $VV_prefix4 = $TOKENS[4];
  debug(5, "VVRNG $VV_name_prefix from $VV_LOW to $VV_HIGH within ".
		"$VV_prefix6 and $VV_prefix4.\n");
}

 


foreach $switch (@{$switchlist})
{
    debug(2, "Building $switch\n");
    open(PASSWD, "< ../../facts/secrets/jroot_pw") ||
    	die "Couldnt find root PW: $!\n";
    my $rootpw = <PASSWD> || die "Couldn't read root PW: $!\n";
    chomp $rootpw;
    close PASSWD;
    my $cf = build_config_from_template($switch,$rootpw);
    if ( ! -d "output")
    {
	mkdir "output";
    }
    if ( ! -d "output" || ! -w "output" || ! -x "output" )
    {
        die("Directory \"output\" does not exist!\n");
    }
    open OUTPUT, ">output/$switch.conf" ||
             die("Couldn't write configuration for ".$switch." $!\n");
    print OUTPUT $cf;
    close OUTPUT;
    debug(1, "Wrote $switch\n");
}


