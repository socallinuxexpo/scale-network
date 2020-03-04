#!/usr/bin/env perl
#
# This script goes through the aplist.csv file in ../../../facts/aps/
# and strips the "locally administered" (0x02) bit from the first
# octet of each MAC address in the third field.
#

# Example file contents
#name,serial,mac,ipv4,2.4Ghz_chan,5Ghz_chan,config_ver,map_id,map_x,map_y
#101-a,n8c-0050,46:94:fc:8d:37:03,10.128.3.10,1,36,0,,,
#101-b,n8c-0043,46:94:fc:8d:12:76,10.128.3.11,1,36,0,,,
#101-c,n8c-0046,08:a1:51:a0:60:a4,10.128.3.12,1,36,0,,,
#102-a,n8c-0044,76:44:01:7a:b7:95,10.128.3.13,1,36,0,,,
#102-b,n8c-0048,46:94:fc:8d:1c:78,10.128.3.14,1,36,0,,,
#103-a,n8t-0058,22:4e:7f:8e:57:69,10.128.3.15,1,36,0,,,

open INPUT, "<../../../facts/aps/aplist.csv" || die "Couldn't open input file for reading $!";
open OUTPUT, ">../../../facts/aps/aplist.out" || die "Couldn't create output file $!";

my $leader = <INPUT>;
print OUTPUT $leader;

foreach(<INPUT>)
{
    my @fields = split(/,/);
    my @octets = split(/:/, $fields[2]);
    $octets[0] = hex($octets[0]) & 0xfd; # 0xfd = 0b11111101 to cancel any 0x02 bit present
    $octets[0] = sprintf("%02x", $octets[0]);
    $fields[2] = join(":", @octets);
    print "SOURCE-> $_";
    $_ = join(",", @fields);
    print "OUT   -> $_";
    print OUTPUT $_;
}
