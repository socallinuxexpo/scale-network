#!/usr/bin/env perl
#
# Library to parse the JSON output from inventory.py and build a corresponding datastructure
#
use strict;

use JSON;
use Data::Dumper;
main();

sub main
{
  my $string = "";
  print "Initializing.\n";
  foreach(<>)
  {
    $string .= $_;
  }
  print "Decoding string:\n$string\n---------------EOF------------\n\n";
  my $result = JSON_Parse($string);
  print "Results:\n";
  print Dumper($result);
}

sub JSON_Parse
{
  my $string = shift @_;
  return(decode_json($string));
}

