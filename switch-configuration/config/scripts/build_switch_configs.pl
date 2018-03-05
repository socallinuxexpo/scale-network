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
    # Rebuild entire config set, so start with empty output directory
    my $file;
    foreach $file (glob("output/*"))
    {
        unlink($file) || die "Failed to delete $file: $!\n";
        debug(3, "Deleted $file from output directory\n");
    }
}
foreach $switch (@{$switchlist})
{
    debug(2, "Building $switch\n");
    my $cf = build_config_from_template($switch,
            '$1$qQMsQS3c$DmHnv3mHPwDuE/ILQ.yLl.');
    open OUTPUT, ">output/$switch.conf" ||
             die("Couldn't write configuration for ".$switch." $!\n");
    print OUTPUT $cf;
    close OUTPUT;
    debug(1, "Wrote $switch\n");
}


