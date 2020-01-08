#!/usr/bin/env perl
#
# This script will iterate through each of the switches named in the switchtypes
# file and produce a configuration file for that switch named <switchname>.conf
# It will also produce a port map file for each switch named <switchname>-map.ps
#
# Switch configurations are stored in ./output/
# Port map files are stored in ./switch-maps/
#
require "./scripts/switch_template.pl";   # Pull in configuration library
set_debug_level(5);
my $switchlist = "";
my $switch;

if(scalar(@ARGV)) # One or more switch names specified
{
    $switchlist = \@ARGV;
}
else
{
    $switchlist = get_switchlist();
}
my @outputs = ();
my @maps = ();
my $file;
if (scalar(@ARGV))
# Selectively delete only configurations we are rebuilding
{
    foreach $file (@{$switchlist})
    {
        push @outputs, "output/".$file.".conf";
        push @maps, "switch-maps/".$file."-map.ps";
    }
}
else
# Rebuild entire config set, so start with empty output directory
{
    @outputs = glob("output/*");
    @maps = glob("switch-maps/*");
}
foreach $file (@outputs)
{
    unlink($file) || die "Failed to delete $file: $!\n";
    debug(3, "Deleted $file from output directory\n");
}
foreach $file (@maps)
{
    unlink($file) || die "Failed to delete $file: $!\n";
    debug(3, "Deleted $file from output directory\n");
}

# Pull in data necessary for VVLAN handling and prepare it.
# Use of global variables here is ugly, but due to the need to maintain a lot of
# shared state information, there's no easy to code better way.
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

 
# Pull in private configuration objects (not stored in repo)
open(PASSWD, "< ../../facts/secrets/jroot_pw") ||
    die "Couldnt find root PW: $!\n";
my $rootpw = <PASSWD> || die "Couldn't read root PW: $!\n";
chomp $rootpw;
close PASSWD;

# Iterate through list of switches and build each configuration file
foreach $switch (@{$switchlist})
{
    debug(2, "Building $switch\n");
    my ($cf, $portmap)  = build_config_from_template($switch,$rootpw);
    if ( ! -d "output" )
    {
        mkdir "output";
    }
    if ( ! -d "output" || ! -w "output" || ! -x "output" )
    {
        die("Directory \"output\" does not exist!\n");
    }
    if ( ! -d "switch-maps" )
    {
        mkdir "switch-maps";
    }
    if (! -d "switch-maps" || ! -w "switch-maps" || ! -x "switch-maps" )
    {
        die("Directory \"switch-maps\" does not exist!\n");
    }
    open OUTPUT, ">output/$switch.conf" ||
             die("Couldn't write configuration for ".$switch." $!\n");
    print OUTPUT $cf;
    close OUTPUT;
    open MAP, ">switch-maps/$switch-map.ps" ||
             die("Couldn't write port map for ".$switch." $!\n");
    print MAP $portmap;
    close MAP;
    debug(1, "Wrote $switch\n");
}


