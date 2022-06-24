#!/usr/bin/env perl
#
# Collect EPS files in switch-maps directory and generate a single EPS file
# optimized for 30 inch wide media (Stickers are printed vertically, 27
# stickers wide, one row of stickers per "page".
#
# Currently output is to STDOUT. Might convert to sending to a file later.

my $PS_Preamble = <<EOF;
%!PS-Adobe
%%DocumentNeededResources: font Helvetica
%%DocumentProcess Colors: Cyan Magenta Yellow Black
%%DocumentCustomColors: (FullCut)
%%+ (StickerCut)
%%CMYKCustomColor: 0.5 0 0 0 (FullCut)
%%+ 0 0.5 0 0 (StickerCut)
%%Extensions: CMYK
%%EndComments
/Inch { 72 mul } bind def
/Sheet_Boundary_Color 

EOF
# Values for 14" wide switch labels on 24" media roll (Labels print vertically, joined horizontally 2" per label)
my $PageWidth = 20;
my $PageHeight = 17;

my $PS_Page_Preamble = <<EOF;
% Set up environment (landscape page, [0,0] origin at rotated bottom left corner)
% Assumes a $PageWidth Wide $PageHeight tall page. (Change above, according to media roll)
/PageWidth { $PageWidth Inch } bind def
/PageHeight { $PageHeight Inch } bind def
<< /PageSize [ PageWidth PageHeight ] >> setpagedevice

PageWidth 0 translate % move origin to lower right edge of portrait page
90 rotate % rotate page clockwise 90 degrees around the bottom right corner (what was bottom right corner is now bottom left corner)

0.25 Inch 0.25 Inch translate % Move origin slightly off the bottom and left edge of the page
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

foreach(sort(@maps))
{
  setorigin($map_pos) if ($map_number);	# Don't move the origin for the first map.
  embed($_);
  $map_number++;
  $map_pos++;
  if ($map_pos > 10)
  {
    $map_pos %= 11;
    showpage();
  }
}

if ($map_pos) # We didn't fill the last page
{
  $map_pos = 0;
  showpage();
}
print "showpage\n";

sub show_preamble
{
  print $PS_Preamble;      # File Preamble
  print $PS_Page_Preamble; # Leadin for first page
}



my $Xorigin = 0;
my $Yorigin = 0;
sub setorigin
{
  my $position = shift(@_);
  if ($position == 0)
  {
    # Reset the origin to the bottom of the page.
    $Yorigin -= 20;
    $Xorigin += 17;
    print <<EOF;
      -20 Inch PageHeight translate
      (new origin ($Xorigin, $Yorigin)) =
EOF
    print $PS_Page_Preamble;
  }
  else
  {
    $Yorigin += 2;
    print <<EOF;
      0 2 Inch translate
      (new origin ($Xorigin, $Yorigin)) =
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
  # Draw sticker cut bounding box around sticker with 0.25" radius corners
  ## FIXME ## The following code is hard coded for a particular sticker size
  print <<EOF;
    gsave
    0.5 0 0 0 (StickerCut) 0 /tint exch def
    findcmykcustomcolor
    false setoverprint
    tint 1 exch sub setcustomcolor
    0.1 setlinewidth
    0.25 Inch -0.1 Inch moveto % lower left point of bottom edge
    13.9 Inch -0.1 Inch lineto % lower right end of straight line
    13.9 Inch 0.15 Inch 0.25 Inch 270 360 arc % arc to right edge vertical
    14.15 Inch 1.35 Inch lineto % right edge
    13.9 Inch 1.35 Inch 0.25 Inch 0 90 arc % arc to top edge
    0.25 Inch 1.6 Inch lineto % Top edge
    0.25 Inch 1.35 Inch 0.25 Inch 90 180 arc % arc to left edge
    0 Inch 0.15 Inch lineto % left edge
    0.25 Inch 0.15 Inch 0.25 Inch 180 270 arc % arc to bottom edge
    closepath
    stroke
    grestore
EOF
}

sub showpage
{
  ## FIXME ## The following code is hard coded for a particular sticker size and grouping
  print <<EOF;
    gsave
    -0.1 Inch $Yorigin Inch -1 mul 0.1 Inch sub translate
    0 0.5 0 0 (FullCut) 0 /tint exch def
    findcmykcustomcolor
    false setoverprint
    tint 1 exch sub setcustomcolor
    0.1 setlinewidth
    0 -0.1 Inch moveto
    14.4 Inch -0.1 Inch lineto
    14.4 Inch PageWidth 0.1 Inch sub lineto
    0 PageWidth 0.1 Inch sub lineto
    closepath
    stroke
    grestore
    %showpage
EOF
}

