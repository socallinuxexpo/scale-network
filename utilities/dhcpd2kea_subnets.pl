#!/usr/bin/env perl
use strict;
use Getopt::Std;

getopts('i:o:');
our $opt_i = "dhcpd.conf.subnets" unless defined($opt_i);;
our $opt_o = "kea.conf.subnets" unless defined($opt_o);;

my @INPUT;
my @OUTPUT;

open INPUT, "<$opt_i" || die("Failed to open subnets file \"$opt_i\".\n");
open OUTPUT, ">$opt_o" || die("Failed to create kea subnets file \"$opt_o\".\n");

# State machine
#	State		Event			Resulting state
#	Outside		subnet.*{		Subnet
#	Subnet		range.*			Subnet	(range is acquired)
#	Subnet		option domain.*		Subnet  (DNS servers are acquired)
#	Subnet		option routers.*	Subnet  (Routers are acquired)
#	Subnet		^}			Complete
#	Complete	Validate and write out	Outside

my $STATE = "Outside";
my ($code, $comment);
my ($subnet, $pfx, $range_start, $range_end, $domain, $routers);

foreach my $line (<>)
{
    # Process each input line
    chomp($line);
    if ($line =~ /#.*$/)
    {
        ($code, $comment) = split(/#/, $line);
        if ($code =~ /^\s*$/)
        {
            print OUTPUT $line, "\n";
            next;
        }
     }
     else
     {
         $code = $line;
     }
     if ($code =~ /^\s+subnet/)
     {
         if ($STATE ne "Outside")
         {
             warn("Subnet declaration ($line) encountered while inside previous ($subnet) declaration. Data may be lost or corrupted.\n");
         }
         if ($code =~ /^\s*subnet6/) # IPv6 declaration
         {
             $code =~ /^\s*subnet6\s+([0-9a-fA-F:])\/([0-9]+\s+{*\s*$/;
             ($subnet, $pfx) = (\1, \2);
             if ($code =~ /{\s*$/)
             {
                 $STATE = "Subnet";
             }
         }
         else # Assume IPv4 Declaration
         {
             $code =~ /^\s*subnet6\s+([0-9\.])\s+netmask\s+([0-9\.]+\s+{*\s*$/;
             ($subnet, $pfx) = (\1, \2);
             if ($code =~ /{\s*$/)
             {
         }
         if ($comment)
         {
             print OUTPUT, "# $comment\n";
         }
     }
}
