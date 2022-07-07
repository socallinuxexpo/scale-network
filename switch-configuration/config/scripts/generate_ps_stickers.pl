#!/usr/bin/env perl
#
# Collect EPS files in switch-maps directory and generate a single PS file
# optimized for 24 inch wide roll media (Stickers are printed vertically, 10
# stickers wide per row of stickers. Everything is on 1 page for roll media.
# So as many rows as are needed are fed to the output on a single page.
#
# Currently output is to STDOUT. Might convert to sending to a file later.

# Values for 17" wide switch labels on 24" media roll (Labels print vertically, joined horizontally 2" per label)
my $PageWidth = 20;
my $PageHeight = 15;

my $StickerHeight = 1.5;
my $StickerWidth  = 14;
my $Radius = 0.25;

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

% Set up environment (landscape page, [0,0] origin at rotated bottom left corner)
% Assumes a $PageWidth Wide $PageHeight tall page. (Change above, according to media roll)
/PageWidth { $PageWidth Inch } bind def
/PageHeight { $PageHeight Inch } bind def
/StickerWidth { $StickerWidth } bind def
/StickerHeight { $StickerHeight Inch } bind def
/CornerRadius { $Radius Inch } bind def			% Radius for Corner of sticker cut line
<< /PageSize [ PageWidth PageHeight ] >> setpagedevice

PageWidth 0 translate % move origin to lower right edge of portrait page
90 rotate % rotate page clockwise 90 degrees around the bottom right corner (what was bottom right corner is now bottom left corner)

0.25 Inch 0.25 Inch translate % Move origin slightly off the bottom and left edge of the page

EOF

my $PS_Page_Preamble = <<EOF;

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
  print <<EOF;
    gsave
    0.5 0 0 0 (StickerCut) 0 /tint exch def
    findcmykcustomcolor
    false setoverprint
    tint 1 exch sub setcustomcolor
    0.1 setlinewidth

    % Draw curved box line to cut sticker for peeling off of backing

    % Adjustments to box position
    /XLOffset {  0    Inch } bind def
    /YLOffset {  0    Inch } bind def
    /XROffset {  0    Inch } bind def
    /YUOffset {  0    Inch } bind def

    % Bounding box is (XLOffset, YLOffset) to (StickerWidth+XROffset, StickerHeight+YUOffset
    % offset left and right side X values by 0.25 (+Left, -Right) Inch on horizontal lines
    % offset top and bottom Y values by 0.25 (+bottom, -top) Inch on vertical lines
    %
    % Draw Bottom Line
    XLOffset CornerRadius add YLOffset moveto 								% Start at Left point of line for bottom edge
    StickerWidth XROffset add CornerRadius sub YLOffset lineto						% Line to Right point of line for bottom edge

    StickerWidth XROffset add CornerRadius sub YLOffset CornerRadius add CornerRadius 270 360 arc	% Draw Arc bottom right corner

    StickerWidth XROffset add StickerHeight YUOffset add CornerRadius sub lineto			% Line to top point of line for right edge

    StickerWidth XROffset add CornerRadius sub StickerHeight YUOffset add CornerRadius sub CornerRadius 0 90 arc
													% Draw Arc top right corner

    XLOffset CornerRadius add StickerHeight YUOffset add lineto						% Line to Left point of line for top edge

    XLOffset CornerRadius add StickerHeight YUOffset add CornerRadius sub CornerRadius 90 180 arc	% Draw Arc top left corner

    XLOFFset YLOffset CornerRadius add lineto								% Line to bottom point of line for left edge

    XLOffset CornerRadius add YLOffset CornerRadius add CornerRadius 180 270 arc			% Draw Ark bottom left corner

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

