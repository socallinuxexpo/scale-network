#!/usr/bin/env perl
#
# Collect EPS files in switch-maps directory and generate a single PS file that will print
# them 9 to a page.
#
# Currently output is to STDOUT. Might convert to sending to a file later.
#
# Intended for handheld reference, prints on US/Letter size paper

my $PS_Preamble = <<EOF;
%!PS-Adobe
/Inch { 72 mul } bind def

EOF

my $PS_Page_Preamble = <<EOF;
% Set up environment (landscape page, [0,0] origin at rotated bottom left corner)
% Assumes an 8.5 x 11 Inch page
<< /PageSize [ 8.5 Inch 11 Inch ] >> setpagedevice
% 11 Inch 0 translate % move origin to lower right edge of portrait page
% 90 rotate % rotate page clockwise 90 degrees around the bottom right corner
0.25 Inch 0.25 Inch translate % Move origin slightly off the bottom and left edge of the page
0.5 0.5 scale % Translate 17 inch wide diagram to 8.5" wide. (actually 14" to 7")
EOF

# General recipe for rotating and translating for landscape printing on 11x17"
#% Convert coordinate system from portrait to landscape
#% Replace the code below (original 1 map per page) with code to stack them
#%11 Inch 0 translate % move origin to lower right edge of portrait page
#%90 rotate % rotate page clockwise 90 degrees around the bottom right corner

my $map_number = 0;		# Current number in sequence of maps
my $map_pos = 0;		# Current position on page (0-3)

my @maps = <switch-maps/*.eps>;

show_preamble();

foreach(@maps)
{
  setorigin($map_pos) if ($map_number);	# Don't move the origin for the first map.
  embed($_);
  $map_number++;
  $map_pos++;
  if ($map_pos > 8)
  {
    $map_pos %= 9;
    showpage();
  }
}

if ($map_pos) # We didn't fill the last page
{
  $map_pos = 0;
  showpage();
}

sub show_preamble
{
  print $PS_Preamble;      # File Preamble
  print $PS_Page_Preamble; # Leadin for first page
}



sub setorigin
{
  my $position = shift(@_);
  if ($position == 0)
  {
    # Reset the origin to the bottom of the page.
    print <<EOF;
      0 -6 Inch translate
EOF
    print $PS_Page_Preamble;
  }
  else
  {
    print <<EOF;
      0 2 Inch translate
EOF
  }
}

sub embed
{
  my $file = shift(@_);
  open INPUT, "<$file" || die("Could not read $file: ");
  foreach(<INPUT>)
  {
    print $_;
  }
  close INPUT;
}

sub showpage
{
  print <<EOF;
    showpage
EOF
}

