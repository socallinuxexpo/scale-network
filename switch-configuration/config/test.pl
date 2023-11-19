#!/usr/bin/env perl
open FH, "+</dev/ttyUSB0" || die("Couldn't open serial port\n");
system('stty -F /dev/ttyUSB0 raw');
while(1)
{
  my ($rin, $win, $ein) = ('', '', '');
  vec($rin, fileno(FH), 1) = 1;
  vec($rin, fileno(STDIN), 1) = 1;
  $ein=$rin;
  my $nfh = select(my $rout=$rin, $wout=$win, $eout=$ein, 1);
  if ($nfh)
  {
    my @bits = split(//, unpack("b*", $rout));
    if ($bits[fileno(FH)])
    {
      sysread(FH, my $byte, 1);
      print "$byte";
    }
    if ($bits[fileno(STDIN)])
    {
      sysread(STDIN, my $byte, 1);
      print FH "$byte";
    }
  }

 }

