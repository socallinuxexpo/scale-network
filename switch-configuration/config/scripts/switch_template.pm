#!/usr/bin/perl
#
# This script must be run from the .../config directory (the parent directory
# of the scripts directory where this script lives. All scripts are expected
# to be run from this location for consistency and ease of use.

##FIXME## Clean up separation of package variables (our *), use package object instead

##FIXME## Add POD for all (exportable) functions

##FIXME## Build a consistency check to match up VLANs in the vlans file(s) and
##FIXME## those defined in the types/* files.

##FIXME## Learn v6 prefix dynamically from config files (look for 2001:470 throughout script)
##FIXME## Assumes v6 prefix is a /48 and many code dependencies on this assumption. Safe at least for now.

##FIXME## Add a PS color block to PoE ports


package switch_template;

use strict;
use integer;
use Scalar::Util qw/reftype/;
use Data::Dumper;
use Exporter;

our $VV_LOW           = "";
our $VV_HIGH          = "";
our $VV_COUNT         = "";
our $VV_prefix6       = "";
our $VV_prefix4       = "";
our $VV_name_prefix   = "";
our $DEBUGLEVEL       = 9;
our %Switchtypes      = ();
our %Switchgroups     = ();
our $PREFIX           = "";
our %TRUNKTYPES       = ();
our %vfgcolor         = ();
our %vbgcolor         = ();

our @ISA = qw(Exporter);

our @EXPORT = qw(
    debug
    set_debug_level
    get_default_gw
    read_config_file
    get_switchlist
    expand_switch_groups
    get_switchtype
    get_switch_by_mac
    build_config_from_template
    $VV_LOW
    $VV_HIGH
    $VV_COUNT
    $VV_prefix6
    $VV_prefix4
    $VV_nme_prefix
    %Switchtypes
    %Switchgroups
);


my %colormap = (
	"AP" => {
		'bgred'		=> 0,
		'bggreen'	=> 0.25,
		'bgblue'	=> 0.25,
                'fgred'		=> 0.75,
                'fggreen'	=> 0.75,
                'fgblue'	=> 0.75,
		},
	"Uplink" => {
		'bgred'		=> 0,
		'bggreen'	=> 0.25,
		'bgblue'	=> 0,
                'fgred'		=> 0.75,
                'fggreen'	=> 0.75,
                'fgblue'	=> 0.75,
		},
	"Downlink" => {
		'bgred'		=> 0.25,
		'bggreen'	=> 0.25,
		'bgblue'	=> 0,
                'fgred'		=> 0.75,
                'fggreen'	=> 0.75,
                'fgblue'	=> 0.75,
		},
	"MassFlash" => {
		'bgred'		=> 0.25,
		'bggreen'	=> 0,
		'bgblue'	=> 0.25,
                'fgred'		=> 1,
                'fggreen'	=> 1,
                'fgblue'	=> 1,
		},
	"Unknown" => {
		'bgred'		=> 0.25,
		'bggreen'	=> 0,
		'bgblue'	=> 0,
                'fgred'		=> 0.75,
                'fggreen'	=> 0.75,
                'fgblue'	=> 0.75,
		},
);
sub BEGIN
{
  return;
}

sub new
{
  my ($class, @args) = @_;

  $class = ref($class) if ref($class); # Allows calling as $exp->new()

  my $self = ();

  bless $self, $class;
  return $self;
}


sub parse_hex_color
{
  no integer;
  my $hexcolor = shift @_;
  my $value = hex($hexcolor);
  debug(5, "Parse_hex_color: $hexcolor -> $value\n");
  debug(5, "Parse_hex_color: ".$value/0x10000 % 0x100."\n");
  debug(5, "Parse_hex_color: ".$value/0x100 % 0x100."\n");
  debug(5, "Parse_hex_color: ".$value%0x100."\n");
  my $red   = ((($value / 0x10000) % 0x100) / 255.0);		# Extract red and scale to postscript color range (0-1 float)
  my $green = ((($value / 0x100) % 0x100) / 255.0);		# Extract green and scale
  my $blue  = (($value % 0x100) / 255.0);			# Extract blue and scale
  debug(5, "Parsed $hexcolor -> ($red, $green, $blue)\n");
  return ($red, $green, $blue);
}

sub set_debug_level
{
    $DEBUGLEVEL = shift(@_);
}

sub debug
{
  my $lvl = shift(@_);
  my $msg = join("", @_);
  print STDERR $msg if ($lvl <= $DEBUGLEVEL);
}

sub expand_double_colon
{
  my $addr = shift(@_);
  debug(8, "Expanding: $addr\n");
  my ($left, $right) = split(/::/, $addr);
  debug(8, "\t$left <-> $right\n");
  my $lcount = 1;
  my $rcount = 1;
  $lcount ++ while ($left  =~ m/:/g);
  $rcount ++ while ($right =~ m/:/g);
  my $needful = 8 - ($lcount + $rcount); # Number of quartets needed
  my $center = ":0" x $needful;
  debug(9, "\t Needed $needful -> $center\n");
  debug(8, "Returning: $left$center".":$right\n");
  return ($left. $center. ":". $right);
}

sub expand_quartet
{
  my $quartet = shift(@_);
  $quartet = "0".$quartet while length($quartet < 4);
}

sub get_default_gw
{
  # Assumes that the ::1 address of the /64 containing the given $addr
  # is the default gateway. Returns that address.
  my $addr = shift(@_);
  $addr = expand_double_colon($addr) if ($addr =~ /::/);
  my @quartets = split(/:/, $addr);
  my $gw = join(":", @quartets[0 .. 3])."::"."1";
  return($gw);
}

sub read_config_file
{
  my $filename = shift(@_);
  my @OUTPUT;
  my $CONFIG;
  open $CONFIG, "<$filename" || die("Failed to open $filename as CONFIG\n");
  while ($_ = <$CONFIG>)
  {
    chomp;
    debug(8, "Base input: $_\n");
    while ($_ =~ s/ \\$/ /)
    {
      my $x = <$CONFIG>;
      chomp($x);
      $x =~ s/^\s*//;
      debug(9, "\tC->: $x\n");
      $_ .= $x;
    }
    $_ =~ s@//.*@@; # Eliminate comments
    next if ($_ =~ /^\s*$/); # Ignore blank lines
    $_ =~ s/\t+/\t/g;
    if ($_ =~ /^\s*#include (.*)/)
    {
        debug(8, "\tProcessing included file $1\n");
        my $input = read_config_file($1);
        debug(8, "\t End of included file $1\n");
        push @OUTPUT, @{$input};
    }
    else
    {
        $_ =~ s@#.*@@; # Eliminate comments
        next if ($_ =~ /^\s*$/); # Ignore blank lines
        push @OUTPUT, $_;
        debug(8, "Cooked output: $_\n");
    }
  }
  close $CONFIG;
  debug(6, "Configuration file $filename total output lines: ", $#OUTPUT,"\n");
  return(\@OUTPUT);
}

sub get_prefix
{
  my @OUTPUT = @{ read_config_file("ipv6_prefix") };
  if (@OUTPUT != 1)
  {
    die("ERROR: more than one entry in ipv6_prefix file.\n".
	" File must contain a single IPv6 prefix on one line and otherwise be empty.\n");
  }
  chomp(@OUTPUT);
  my ($prefix,$pfxlen) = split(/\//, $OUTPUT[0]);
  if ($pfxlen ne "48")
  {
    die("ERROR: Only /48 is allowed at this time. File (ipv6_prefix) has /$pfxlen.\n");
  }
  $prefix = lc($prefix);
  $prefix =~ s/([23][0-9a-f]{3}):([0-9a-f]{1,4}):([0-9a-f]{0,4})::{0,1}.*$/$1:$2:$3::/;
  $prefix =~ s/:+$/::/;
  return $prefix;
}
  
sub get_switchlist
{
  my $include_Z = shift(@_);
  my @list=();
  foreach(sort(keys(%Switchtypes)))
  {
    if ($include_Z || $Switchtypes{$_}[4] ne "Z")
    {
      push @list, $_;
      debug(9, "Adding $_ to list with group $Switchtypes{$_}[4]\n");
    }
    else
    {
      debug(9, "Skipping $_ with group $Switchtypes{$_}[4]\n");
    }
  }
  debug(5, "get_switchlist called\n");
  if (scalar(@list))
  {
    debug(5, "Returning ",$#list," Switch Names.\n");
    return \@list;
  }
  else
  {
    get_switchtype("anonymous");
    my @list = sort(keys(%Switchtypes));
    debug(5, "Returning ",scalar(@list)," Switch Names.\n");
    return \@list;
  }
}

sub expand_switch_groups
{
    print "Expanding switch list...\n";
    my @list = @_;
    my @output = ();
    # Make sure cache is prepopulated from configuration file
    get_switchtype("anonymous");
    foreach(@list)
    {
        if (defined($Switchgroups{$_}))
        {
            print "Expanding $_\n";
            push @output, @{$Switchgroups{$_}};
        }
        else
        {
            print "Passing $_\n";
            push @output, $_;
        }
    }
    print "Expansion ends\n";
    return @output;
}

sub get_switchtype
{
  my $hostname = shift(@_);
  my @list = sort(keys(%Switchtypes));
  debug(5, "get_switchtype called for $hostname.\n");
  # Preload the cache if we don't have a hit or are specifically called to preload ("anonymous")
  if (!exists($Switchtypes{$hostname}) || $hostname eq "anonymous")
  {
    debug(5, "Reading switchtypes configuration file");
    my $switchtypes = read_config_file("switchtypes");
    foreach(@{$switchtypes})
    {
      my ($Name, $Num, $MgtVL, $IPv6Addr, $Type, $hierarchy, $noiselevel, $model, $mgmtMAC) = split(/\t+/, $_);
      my ($group, $level) = split(/\./, $hierarchy);
      debug(9,"switchtypes->$Name = ($Num, $MgtVL, $IPv6Addr, $Type, $group, $level)\n");
      $Switchtypes{$Name} = [ $Num, $MgtVL, $IPv6Addr, $Type, $group, $level, $noiselevel, $model, $mgmtMAC ];
      # Build cache of groups
      debug(5, "Adding $Name to group $group at level $level\n");
      if (!defined($Switchgroups{$group}))
      {
          @{$Switchgroups{$group}} = ();
      }
      push(@{$Switchgroups{$group}}, $Name);
    }
  }
  # If we're just doing a cache preload, we're done.
  if ($hostname eq "anonymous")
  {
    return(undef);
  }
  # Perform consistency checks
  my @v6q = split(/:/, $Switchtypes{$hostname}[2]);
  if ($Switchtypes{$hostname}[1] != $v6q[3])
  {
    die("ERROR: Switch: $hostname Management VLAN (".$Switchtypes{$hostname}[1].
        ") does not match Address (".$Switchtypes{$hostname}[2].")\n");
  }
  # Return appropriate information
  debug(9, "Returning: (".  $hostname. ", ".
                            $Switchtypes{$hostname}[0]. ", ".
                            $Switchtypes{$hostname}[1]. ", ".
                            $Switchtypes{$hostname}[2]. ", ".
                            $Switchtypes{$hostname}[3]. ", ".
                            $Switchtypes{$hostname}[4]. ", ".
                            $Switchtypes{$hostname}[5]. ", ".
                            $Switchtypes{$hostname}[6]. ", ".
                            $Switchtypes{$hostname}[7]. ", ".
                            $Switchtypes{$hostname}[8]. ")\n");
  return($hostname, @{$Switchtypes{$hostname}});
}

sub get_switch_by_mac
{
  ## FIXME ## Assertion -- Switchtypes hash has been preloaded
  my $macaddr = shift(@_);
  my @switches = ();
  foreach(keys(%Switchtypes))
  {
    my @octets = split(/:/, $macaddr);
    my $macaddr = sprintf("%02s:%02s:%02s:%02s:%02s:%02s", @octets);
    @octets = split(/:/, $Switchtypes{$_}[8]);
    my $styaddr = sprintf("%02s:%02s:%02s:%02s:%02s:%02s", @octets);
    if (lc($macaddr) eq lc($styaddr))
    {
      push(@switches, $_);
    }
  }
  return(@switches);
};

sub build_users_from_auth
{
  my %Keys;    # %Keys is actually a data structure. The Hash keys are
               # Usernames. The values are references to anonymous arrays.
               # The anonymous arrays contain references to anonymous hashes
               # which each contain a key 'type' and a key 'key' whose values
               # are the key type and public key text, respectively.
               #
               # e.g.
               # %Keys = {
               #	"username" => [
               #		{ "type" => "ssh-rsa", "key" => "<keytext>" },
               #		{ "type" => "ssh-ecdsa", "key" => "<keytext>" }
               #	]
               # }
  my $user;
  my $type;
  my $file;

  ##FIXME## In the future add support for users that don't get superuser

  foreach $file (glob("../../facts/keys/*"))
  {
    debug(9, "Examining key file $file\n");
    $file =~ /..\/..\/facts\/keys\/(.*)_id_(.*).pub/;
    if (length($1) < 3)
    {
      warn("Skipping key $file -- Invalid username $1\n");
      next;
    }
    $user = $1;
    $type = $2;
    debug(9, "\tFound USER $user type $type\n");
    open KEYFILE, "<$file" || die("Failed to open key file: $file\n");
    my $key = <KEYFILE>;
    chomp($key);
    close KEYFILE;
    if (!defined($Keys{$user}))
    {
      debug(9, "\t\tFirst key for USER $user\n");
      $Keys{$user} = [];
    }
    else
    {
      debug(9, "\t\tAdditional key for USER $user\n");
    }
    # Append anonymous hash reference onto list for $user.
    push @{$Keys{$user}},{ 'type' => $type, 'key' => $key };
  }
  my $OUTPUT = "";
  debug(9, "OUTPUT KEY ENTRIES...(", join(" ", sort(keys(%Keys))), ")\n");
  # Process each user
  foreach (sort keys(%Keys))
  {
    debug(9, "\tUser $_\n");
    $OUTPUT .= <<EOF;
        user $_ {
            class super-user;
            authentication {
EOF
    my $entry;
    # Go through the key entry list for $user. (${$entry}) is iterated through
    # the list of hash references for $user.
    foreach $entry (@{$Keys{$_}})
    {
      debug(9, "\t\tType: ".${$entry}{"type"}."\n");
      # Place the type and key text into JunOS configuration file format.
      $OUTPUT.= "                ssh-".${$entry}{"type"}." \"".
			${$entry}{"key"}."\";\n";
    }
    $OUTPUT .= <<EOF;
            }
        }
EOF
  }
  return($OUTPUT);
}

sub build_interfaces_from_config
{
  ##FIXME## There are a number of places where this subroutine assumes
  ##FIXME## that all interaces are ge-0/0/*
  ##FIXME## There are special excpetions coded for FIBER ports at ge-0/1/[0-3] to partially compensate
  ##FIXME## This is adequate for our current switch inventory which does not include any multi-U switches or chassis.
  ##FIXME## Fiber_Left_Edge (Position of Fiber Port List) is currently above 4th port grouping. Should be to right, but involves expanding sticker size to accommodate
  ##FIXME## Draw boxes around all ports, not just the configured ones
  my $hostname = shift @_;
  # Retrieve Switch Type Information
  my ($Name, $Number, $MgtVL, $IPv6addr, $Type) = get_switchtype($hostname);
  my $OUTPUT = "# Generated interface configuration for $hostname ".
			"(Type: $Type)\n";
  my $portmap_PS = "%!PS-Adobe-3.0 EPSF-3.0\n%%BoundingBox: 0 0 1008 144 % 14\" x 2\"\n%\n".
            "% Generated Interface Portmap for ".
            "Switch #$Number Name: $hostname (Type: $Type)\n%\n";
  $portmap_PS .= <<EOF;
% Initialization of graphical context for portmap
% Each portmap is roughly 14" wide by 2" high.

/SwitchMapDict 20 dict def
SwitchMapDict begin
% Font Definitions
/BoxFont { /Helvetica-Bold findfont 9 scalefont setfont } bind def
/TitleFont { /Helvetica findfont 24 scalefont setfont } bind def

% Color Setting
/PoEOnColor { 0 1 0 setrgbcolor } def

% Misc. Subroutines used in constant definitions (mostly unit conversions)
/Inch { 72 mul } bind def   % Inch converted to points (I -> pts)
/mm  { 2.835 mul } bind def % mm converted to points   (mm -> pts)

% Leave the lesser of the top two stack items on the stack (min(a,b))
/minimum { /b exch def /a exch def a b lt { a } { b } ifelse } bind def

% Constants for use in building portmaps
/Origin           [ 0.5 Inch 0.25 Inch ] def    % Bottom Left Corner of port map (After rotation and translatin of [0,0])
/Label_Ligature   1.25 Inch def                 % Ligature Line Position for Label
/Box_Height       0.5 Inch def                  % Height of boxes for portmap
/Odd_Bottom       0.0 Inch def                  % Bottom Line for Even Ports
/Even_Bottom      Odd_Bottom Box_Height add def % Bottom Line for Even Ports
/Left_Port_Edge   0.125 Inch def                % Left edge of first port column
/Port_Width       0.5625 Inch def               % Width of each port
/Port_Group_Gap   0.125 Inch def                % Width of gap between port groups
/Center           7 Inch def                    % Center of box diagram
/Fiber_Bottom     Even_Bottom Box_Height add 0.1 Inch add def
/Fiber_Left_Edge  Port_Width 6 mul Port_Group_Gap add 3 mul Port_Width add def % Compute position for left edge of Fiber Ports
/Fiber_Port_Width 0.583 Inch def		% Width of SFP Port


% String for storing port numbers
/s 3 string def

% Subroutines specific to drawing a portmap
 % ShowTitle [ text ] -> [ ]
/ShowTitle {
  TitleFont                    % Set up Title Font
  0 0 0 setrgbcolor            % Title in black
  dup stringwidth pop          % Get width from font metrics (discard height) [ text ] -> [ text width ]
  2 div                        % Convert to offset from center for left edge -> [ text width/2 ]
  Center exch sub              % Subtract from Center position -> [ text Center-width/2 ]
  Label_Ligature moveto        % Position at bottom left edge of text -> [ text ]
  show                         % Display text [ text ] -> [ ]
} bind def

 % Box [ Left Bottom Width Height ] -> [ ]
/Box {
  /boxHeight exch def
  /boxWidth exch def
  /boxBottom exch def
  /boxLeft exch def
  /boxTop boxBottom boxHeight add def
  /boxRight boxLeft boxWidth add def
  newpath
  boxLeft boxBottom moveto
  boxRight boxBottom lineto
  boxRight boxTop lineto
  boxLeft boxTop lineto
  closepath % Draw line from boxLeft BoxTop to boxLeft boxBottom
 } bind def

/DrawPoEBox {
  /PortHeight exch def
  /PortWidth exch def
  /PortBottom exch def
  /PortLeft exch def
  /BoxSize PortHeight PortWidth minimum 8 div def % 1/8th of shortest PortBox dimension
  /LeftEdge PortWidth 8 div PortLeft add def
  /BottomEdge PortHeight 8 div PortBottom add def
  gsave
  LeftEdge BottomEdge BoxSize BoxSize Box
  fill
  grestore
} bind def

 % DrawPort [ poe fr fg fb Text br bg bb Number ] -> [ ]
 % fr/g/b are text color, br/g/b are box color
/DrawPort {
  % Convert Number to X and Y position
  % -Identify the ligature line and bottom of box
  % [ poe r g b Text r g b Number ] -> [ poe r g b Text r g b Number ]
  % -Save Port Number
  % (Entered DrawPort) print
  % pstack()=
  dup /PortNum exch def
  % -Determine bottom edge of box
  dup /Bottom exch 2 mod 0 eq { Even_Bottom } { Odd_Bottom } ifelse def
  /Ligature Bottom 0.35 Inch add def
  % -Identify left and bottom edge of Port Box on Map (consumes Number)
  % [ poe r g b Text r g b Number ] -> [ poe r g b Text r g b ]
  % (DrawPort Find Left and Bottom of box) print
  % pstack()=
  2 div                     % Get horizontal port position
  dup cvi 6 idiv            % Get number of preceding port groups
  Port_Group_Gap mul        % Convert to width
  exch                      % Swap port group width with Port Horizontal Position
  cvi Port_Width mul add    % Convert Port Horizontal Position to width and add to Group offset
  Left_Port_Edge add        % Add offset for left port edge
  /Left exch def            % Save as Left
  % Set color for fill [ poe r g b Text r g b ] -> [ poe r g b Text ]
  % (DrawPort Set color for fill) print
  % pstack()=
  /bgblue exch def % Save blue value for background
  /bggreen exch def % Save blue value for background
  /bgred exch def % Save blue value for background
  bgred bggreen bgblue setrgbcolor % Set color for background
  % Build Box path
  Left Bottom Port_Width Box_Height Box
  % Fill Box
  gsave
  fill
  % Draw outline
  grestore
  0 0 0 setrgbcolor %black
  stroke
  % Draw Text
  BoxFont
  % Save Text in variable for later use. [ poe r g b Text ] -> [ poe r g b ] (Defines Text)
  /Text exch def
  % (DrawPort saved Text) print
  % pstack()=
  % Set text color. [ poe r g b ] -> [ poe ]
  /b exch def
  /g exch def
  /r exch def
  r g b setrgbcolor % pull text RGB color from stack.
  % (DrawPort TextColor Selected) print
  % pstack()=
  % Put Text back on stack and compute position [ poe ] -> [ poe text ] (Computes W (textwidth/2))
  Text dup stringwidth pop 2 div /W exch def
  % (DrawPort Text back on stack) print
  % pstack()=
  % Move to the left edge of text at ligature position
  Left Port_Width 2 div add W sub Ligature moveto
  % Render text [ poe text ] -> [ poe ]
  % (DrawPort Ready to render PortDesc) print
  % pstack()=
  show
  /P PortNum s cvs def
  P stringwidth pop 2 div /W exch def
  Left Port_Width 2 div add W sub Ligature 10 sub moveto
  P % Put Portnum back on stack for rendering
  % (DrawPort Ready to render PortNum) print
  % pstack()=
  show
  % (DrawPort Ready to PortNum rendered) print
  % pstack()=
  /PoE exch def
  gsave
  PoE { PoEOnColor } { bgred bggreen bgblue setrgbcolor }
  % (DrawPort Ready to render PoE) print
  % pstack()=
  ifelse % Set color for PoE State box
  Left Bottom Port_Width Box_Height DrawPoEBox
  grestore
} bind def

 % DrawFiberPort [ Text r g b Number ] -> [ ]
/DrawFiberPort {
  % Convert Number to X and Y position
    % Identify the ligature line and bottom of box
    % [ Text r g b Number ] -> [ Text r g b Number ]
    % Save Port Number
  dup /PortNum exch def

    % Determine bottom edge of box
  /Bottom Fiber_Bottom def
  /Ligature Bottom 0.35 Inch add def
    % Identify left and bottom edge of Port Box on Map (consumes Number)
    % [ Text r g b Number ] -> [ Text r g b ]
  Fiber_Left_Edge                 % Place FiberPort Group Left Edge on stack
  exch                            % Swap Fiber port group position with subgroup Port Horizontal Position
  cvi Fiber_Port_Width mul add    % Convert Port Horizontal Position to width and add to Group offset
  Left_Port_Edge add              % Add offset for left port edge
  /Left exch def                  % Save as Left
  % Set color for fill [ Text r g b ] -> [ Text ] (consumes r g b)
  /b exch def
  /g exch def
  /r exch def
  r g b setrgbcolor
  % Build Box path
  Left Bottom Port_Width Box_Height Box % Graphics context now includes a path for the box
  % Fill Box
  gsave
  fill
  % Draw outline
  grestore
  0 0 0 setrgbcolor %black
  stroke
  % Draw Text [ Text ] -> [ ]
  BoxFont
  dup stringwidth pop 2 div /W exch def
  Left Port_Width 2 div add W sub Ligature moveto
  show
  /P PortNum s cvs def
  P stringwidth pop 2 div /W exch def
  Left Port_Width 2 div add W sub Ligature 10 sub moveto P show
} bind def

(Switch #$Number Name: $hostname (Type: $Type)) ShowTitle
EOF

# Preamble information to put in generator pulling EPS files together for printing
#% Set up page and draw title
#
#% Set up environment (landscape page, [0,0] origin at rotated bottom left corner)
#% Assumes a 17" wide 11" tall page.
#<< /PageSize [ 11 Inch 17 Inch ] >> setpagedevice
#% Convert coordinate system from portrait to landscape
#% Replace the code below (original 1 map per page) with code to stack them
#%11 Inch 0 translate % move origin to lower right edge of portrait page
#%90 rotate % rotate page clockwise 90 degrees around the bottom right corner

  my $port = 0;
  # Read Type file and produce interface configuration
  my $switchtype = read_config_file("types/$Type");
  debug(9, "$hostname: type: $Type, received ", $#{$switchtype},
      " lines of config\n");
  $OUTPUT .= <<EOF;
    me-0 {
        unit 0 {
            family inet {
                    address 192.168.255.76/24;
            }
        }
    }
EOF
  my @POEPORTS = ();
  my ($VLANS, $VLANS_byname) = build_vlan_hash();
  foreach(@{$switchtype})
  {
    my $POEFLAG = 0;
    my @tokens = split(/\t/, $_); # Split line into tokens
    my $cmd = shift(@tokens);     # Command is always first token.
    # Handle POE Flag Hack
    if ($tokens[2] =~ /poe/i)
    {
      $POEFLAG = 1;
      $cmd =~ s/^P//;
    }
    elsif ($tokens[2] !~ /^-$/)
    {
      if ($cmd =~ /^TRUNK$/ || $cmd =~ /^VLAN$/)
      {
	my $i=0;
        foreach(@tokens)
        {
          debug(9, "Token[$i] = \"$tokens[$i]\"\n");
          $i++;
        }
        die "Error in configuration for $Type at $_ -- Invalid POE specification ($tokens[2])";
      }
    }
    my $POE = ($POEFLAG ? "true" : "false");
    debug(9, "\tCommand: $cmd ", join(",", @tokens), "\n");
    if ($cmd eq "RSRVD")
    {
      # Create empty ports matching reserved port count 
      my $portcount = shift(@tokens);
      while ($portcount)
      {
        debug(9, "\t\tPort ge-0/0/$port\n");
        $OUTPUT .= <<EOF;
    inactive: ge-0/0/$port {
        unit 0 {
            family ethernet-switching;
        }
    }
EOF
        $portmap_PS .= <<EOF;
$POE 1 1 1 (UNUSED) 0.5 0 0.5 $port DrawPort
EOF
        $portcount--;
        $port++;
      }
    }
    elsif ($cmd eq "TRUNK" || $cmd eq "FIBER")
    {
      # Create specified TRUNK port -- Warn if it doesn't match port counter
      ##FIXME## This really should convert to using port counts like VLAN
      ##FIXME## Access ports do (except for FIBER directive).


      my $iface = shift(@tokens);
      my $vlans = shift(@tokens);
      my $poe = shift(@tokens) if ($cmd eq "TRUNK"); # No PoE on Fiber
      my $trunktype = "unknown";
      my @vlans = split(/,/, $vlans);
      for (my $i=0; $i < scalar(@vlans); $i++)
      {
        debug(9, "Checking $vlans[$i] for trunk macro\n");
        debug(9, "Looking in: ".Dumper(%TRUNKTYPES)."\n");
        if (defined($TRUNKTYPES{$vlans[$i]}))
        {
          debug(9, "\tExpanding\n");
          my ($vl, $bgcolor, $fgcolor) = @{$TRUNKTYPES{$vlans[$i]}};
          $trunktype=$vlans[$i];
          debug(5, "Set trunktype $vlans[$i] with ($vl,$bgcolor,$fgcolor)\n");
          my ($bgr, $bgg, $bgb) = parse_hex_color($bgcolor);
          my ($fgr, $fgg, $fgb) = parse_hex_color($fgcolor);
          $colormap{$trunktype} = {
            'fgred' => $fgr, 'fggreen' => $fgg, 'fgblue' => $fgb,
            'bgred' => $bgr, 'bggreen' => $bgg, 'bgblue' => $bgb
          };
          debug(5, "Assigned $bgcolor ($bgr,$bgg, $bgb) and $fgcolor ($fgr,$fgg,$fgb) to trunk type $trunktype as hash: ".Dumper(%{$colormap{$trunktype}}));
          $vlans[$i] = $vl;
        }
      }
      debug(5, "Finished VLAN expansion with trunktype=$trunktype\n");
      debug(9, "\t$cmd\t$iface (", join(",", @vlans),")\n");
      my $portnum = $iface;
      my $POE = ($POEFLAG ? "true" : "false");
      if ($cmd eq "TRUNK")
      {
        push @POEPORTS, $iface if ($POEFLAG);
        $portnum =~ s@^ge-0/0/(\d+)$@$1@;
        if ($portnum != $port)
        {
          warn("Port number in Trunk: $_ does not match expected port ".
			"$port (Host: $hostname, Type: $Type)\n");
        }
        # Safety -- Move past portnum if port was lower.
        $port = $portnum if ($portnum > $port);
        $port++;
      }
      ##FIXME## Put some sanity checking on fiber interface
      $OUTPUT .= <<EOF;
    $iface {
        description "$cmd Port ($vlans)";
        unit 0 {
            family ethernet-switching {
                port-mode trunk;
                vlan members [ $vlans ];
            }
        }
    }
EOF
      debug(9, "$cmd reached PS Output\n");
      if ($cmd eq "TRUNK")
      {
        # Handle non-fiber trunk port
        debug(6, "Trunktype reported as $trunktype for $_\n");
        debug(7, "Trunktypes available: ".Dumper(%colormap));
        debug(5, "dereferencing $trunktype in colormap FGRED = ".${$colormap{$trunktype}}{'fgred'}." FGGREEN=".${$colormap{$trunktype}}{'fggreen'}." FGBLUE=".${$colormap{$trunktype}}{'fgblue'}.".\n");
        debug(9, "$cmd output standard box for port $portnum ($iface) ($trunktype) -- (".$colormap{$trunktype}{'fgred'}.",".$colormap{$trunktype}{'fggreen'}.",".$colormap{$trunktype}{'fgblue'}."), (".$colormap{$trunktype}{'bgred'}.",".$colormap{$trunktype}{'bggreen'}.",".$colormap{$trunktype}{'bgblue'}.")\n");
        my $name = $trunktype;
        $name =~ s/^cf|ex|hi//;
        $portmap_PS .= <<EOF;
$POE ${$colormap{$trunktype}}{'fgred'} ${$colormap{$trunktype}}{'fggreen'} ${$colormap{$trunktype}}{'fgblue'} ($name) ${$colormap{$trunktype}}{'bgred'} ${$colormap{$trunktype}}{'bggreen'} ${$colormap{$trunktype}}{'bgblue'} $portnum DrawPort
EOF
        debug(9, "Resulting portmap_PS string: \"$portmap_PS\"\n\n");
      }

      if ( $cmd eq "FIBER")
      {
        # Fiber ports are special in the map
        my ($first, $second, $portnum) = split(/\//, $iface);
	print STDERR "REACHED DrawFiberPort IF statement\n";
        $portmap_PS .= <<EOF;
false 0 0 0 (FIBER) 0 1 1 $portnum DrawFiberPort
EOF
        debug(9, "$cmd output Fiber box for port $portnum ($iface)\n");

      }
    }
    elsif ($cmd eq "VLAN")
    {
      # Create specified number of interfaces as switchport members
      # of specified VLAN
      my $vlan = shift(@tokens);
      my $vname = $vlan;
      $vname =~ s/^cf|ex|hi//; # Shorten VLAN Name by removing building designation
      my $count = shift(@tokens);
      debug(9, "\t$count members of VLAN $vlan\n");
      # Use interface-ranges to make the configuration more readable

      # For convenience, use the VLAN name as the interface range name.
      
      my $MEMBERS = "";
      my $fgcolor;
      my $bgcolor;
      my $vlid = ${$VLANS_byname}{$vlan};
                     #     <VLANID> => [ <type>, <name>, <IPv6>,
                     #                   <IPv4>, <desc>, <prim>,
                     #			 <bgcolor>, <fgcolor>],
      my $vlinfo=${$VLANS}{$vlid};
      debug(4, "For $cmd $_ -> $vlan $vlid: ".Dumper(@{$vlinfo})."\n");
      debug(5, "Background: ".${$vlinfo}[6]." -> ".Dumper(parse_hex_color(${$vlinfo}[6]))."\n");
      $bgcolor = join(" ", parse_hex_color(${$vlinfo}[6]));
      $fgcolor = join(" ", parse_hex_color(${$vlinfo}[7]));
      debug(5, "Access Port Color: (".${$vlinfo}[6].",".${$vlinfo}[7].") -> ($bgcolor,$fgcolor)\n");
      my $POE = ($POEFLAG ? "true" : "false");
      while ($count)
      {
          debug(9, "\t\tMember ge-0/0/$port remaining $count\n");
          $MEMBERS.= "        member ge-0/0/$port;\n";
          push @POEPORTS, "ge-0/0/$port" if ($POEFLAG);
          $portmap_PS .= <<EOF;
$POE $fgcolor ($vname) $bgcolor $port DrawPort
EOF
          $count--;
          $port++;
      }
      $OUTPUT .= <<EOF;
    interface-range $vlan {
        description "VLAN $vlan Interfaces";
        unit 0 {
            family ethernet-switching {
                port-mode access;
                vlan members $vlan;
            }
        }
$MEMBERS
    }
EOF
    }
    elsif ($cmd eq "VVLAN")
    {
      # Account for the ports VVLAN directive takes up.
      # (Namely, each switch has a unique set of 16 vendor VLANs in a particular
      #  range for all VVLANs and firewall filters to prevent interaction between
      #  VVLANs)
      # The range is defined in the vlans file with a VVRNG directive.
      my $count = shift(@tokens);
      $port += $count;
    }
  }
  return($OUTPUT, \@POEPORTS, $portmap_PS);
}

sub build_l3_from_config
{
  my $hostname = shift @_;
  my ($Name, $Number, $MgtVL, $IPv6addr, $Type) = get_switchtype($hostname);
  my $OUTPUT = "        # Automatically Generated Layer 3 Configuration ".
                "for $hostname (MGT: $MgtVL Addr: $IPv6addr Type: $Type\n";
  $OUTPUT .= <<EOF;
        unit $MgtVL {
            family inet6 {
                address $IPv6addr/64;
            }
        }
EOF
  my $gw = get_default_gw($IPv6addr);
  return($OUTPUT, $gw);
}


sub build_vlans_from_config
{
  my $hostname = shift @_;

  my $OUTPUT;

  my ($Name, $Number, $MgtVL, $IPv6addr, $Type) = get_switchtype($hostname);
  my ($VLANS, $VLANS_byname) = build_vlan_hash();

  foreach(sort(keys(%{$VLANS})))
  {
    my ($type, $name, $IPv6, $IPv4, $desc, $prim) = @{${$VLANS}{$_}};
    if ($type eq "VLAN")
    {
      $OUTPUT .= <<EOF;
    $name {
        description "$desc";
        vlan-id $_;
EOF
      $OUTPUT .= "        l3-interface vlan.$_;\n" if ($_ eq $MgtVL);
      $OUTPUT .= "    }\n";
    }
    else
    {
        warn("Skipped unknown VLAN type ($_ => $name type=$type).\n");
    }
  }
  return($OUTPUT);
}

sub build_vlan_hash
{
  my $VL_CONFIG = read_config_file("vlans");
  # Convert configuration data to hash with VLAN ID as key
  my %VLANS;         # Hash containing VLAN data structure as follows:
                     # %VLANS = {
                     #     <VLANID> => [ <type>, <name>, <IPv6>,
                     #                   <IPv4>, <desc>, <prim>,
                     #			 <bgcolor>, <fgcolor>],
                     #     ...
                     # }
  my %VLANS_byname;  # Hash mapping VLAN Name => ID
  my $OUTPUT = "";

  my $type;   # Type of VLAN (VLAN, PRIM, ISOL, COMM)
              # Where:
              #    VLAN = Ordinary VLAN
              #    PRIM = Primary PVLAN
              #    ISOL = Isolated Secondary PVLAN
              #    COMM = Community Secondary PVLAN
  my $name;   # VLAN Name
  my $vlid;   # VLAN ID (802.1q tag number)
  my $IPv6;   # IPv6 Prefix (For reference and possible future consistency
              #   checks). Not used in config generation for switches..
  my $IPv4;   # IPv4 Prefix (For reference and possible future consistency
              #   checks). Not used in config generation for switches..
  my $desc;   # Description
  my $prim;   # Primary VLAN Name (if this is a secondary (ISOL | COMM) VLAN)
  my $bgco;   # Background Color for access port labels
  my $fgco;   # Text color for access port labels
  my %TRUNKTYPES = ();
  debug(9, "Got ", $#{$VL_CONFIG}, " Lines of VLAN configuraton\n");
  foreach(@{$VL_CONFIG})
  {
    my @TOKENS;
    @TOKENS = split(/\t/, $_);
    $prim = 0;
    $name = $TOKENS[1];
    $name =~ s/^\s*//; # Eliminate accidental space possibly introduced by continuation lines
    debug(9, "Processing VLAN Config line $_ for hashing\n");
    if ($TOKENS[0] eq "VLAN") # Standard VLAN
    {
      $type = $TOKENS[0]; # VLAN
      $vlid = $TOKENS[2];
      $IPv6 = $TOKENS[3];
      $IPv4 = $TOKENS[4];
      $desc = $TOKENS[5];
      $bgco = $TOKENS[6];
      $fgco = $TOKENS[7];
      $VLANS_byname{$name} = $vlid;
      $VLANS{$vlid} = [ $type, $name, $IPv6, $IPv4, $desc, 
                        ($prim ? $prim : undef),
                        $bgco, $fgco ];
      debug(1, "VLAN $vlid => $name ($type) $IPv6 $IPv4 $prim $desc\n");
    }
    elsif ($TOKENS[0] eq "VVRNG") # Vendor VLAN Range Specification
    {
      # Grab color and assign to lowest VLID in range
      $type = "VVRNG";
      my $vlan_range = $TOKENS[2];
      ($vlid, my $rest)  = split(/-/, $vlan_range,2); # Get just the first vlan in the range
      $IPv6=undef;
      $IPv4=undef;
      $desc="Vendor Vlan Range";
      $bgco = $TOKENS[6];
      $fgco = $TOKENS[7];
      $VLANS_byname{$name} = $vlid;
      $VLANS{$vlid} = [ $type, $name, $IPv6, $IPv4, $desc, 
                        ($prim ? $prim : undef),
                        $bgco, $fgco ];
      debug(1, "VVRNG $vlid => $name ($type) $IPv6 $IPv4 $prim $desc\n");
    }
  }
  return (\%VLANS,\%VLANS_byname);
}

sub build_trunktypes_from_config
{
  my $hostname = shift @_;
  my ($VLANS, $VLANS_byname) = build_vlan_hash();
  my $TT = read_config_file("trunktypes");
  %TRUNKTYPES=();	# Reset contents of TRUNKTYPES hash
  foreach(@{$TT})
  {
    my @TOKENS = split(/\t/, $_);
    my $name = $TOKENS[0];
    my $vlans = $TOKENS[1];
    $vlans =~ s/\s*,\s*/,/g;	# Eliminate possible spaces from continuation artifact
    my $fgcolor = $TOKENS[2];
    my $bgcolor = $TOKENS[3];
    my @vlans = split(/,/, $vlans);
    debug(5, "Trunktype $name expanding\n");
    # Validate VLANs for each trunk type are defined
    foreach my $k (@vlans)
    {
      $k =~ s/^\s*//; # Eliminate accidental space possibly introduced by continuation lines
      if (!exists(${$VLANS_byname}{$k}))
      {
        debug(1, "VLAN Build Returned: ". Dumper(%{$VLANS}). " with byname: ". Dumper(%{$VLANS_byname}));
        print "VLANS_byname{$k}->".${$VLANS_byname}{$k}."\n";
        die("ERROR: VLAN \"$k\" not found in VLAN Configuration for Trunk Type $name\n");
      }
    }
    if (exists($TRUNKTYPES{$name}))
    {
      debug(1, "Existing TRUNKTYPES: ".Dumper(%TRUNKTYPES));
      die("ERROR: Multiple definitions of trunktype $name\n");
    }
    $TRUNKTYPES{$name} = [ $vlans, $fgcolor, $bgcolor ];
    debug(4, "Defined TRUNKTYPES{$name} as [ $vlans, $fgcolor, $bgcolor ]\n");
    debug(5, "TRUNKTYPES now: ", Dumper(%TRUNKTYPES),"\n");
  }
  return \%TRUNKTYPES;
}


# Vendor VLAN subroutines
sub VV_get_prefix6
# Return the $VV_COUNT'th /64 prefix from $VV_prefix6 (if possible), or -1 if error.
##FIXME## This subroutine is very hacky. Should actually just do proper arithmetic
##FIXME## After converting the IPv6 prefix to a 64-bit integer and handling. Currently
##FIXME## Assumes prefix is longer than or equal to a /48 and we are issuing /64s.
{
  my $VV_COUNT = shift @_;
  my $VV_prefix6 = shift @_;
  debug(5, "VV_get_prefix6: Count: $VV_COUNT from prefix $VV_prefix6.\n");
  my ($net, $mask) = split(/\//, $VV_prefix6);
  $net = expand_double_colon($net);
  my @quartets = split(/:/, $net);
  my $n_bits = 64 - $mask;
  debug(5, "\tNet: $net Mask: $mask ($n_bits bits to play)\n");
  my $netbase = "";
  my $digitpfx = "";
  if ($n_bits > 16)
  {
    warn("Error: cannot support more than 9999 IPv6 VLANs (>16 bit variable BCD field) for VVRNG\n");
    return -1;
  }
  $netbase = $VV_LOW;
  my $netmax;
  if ($n_bits % 4)
  {
    $netmax = $netbase + 10 ** ($n_bits/4) + (2 ** (($n_bits % 4) -1) * (10 ** ($n_bits/4))) - 1 ;
  }
  else
  {
    $netmax = $netbase + 10 ** ($n_bits/4) - 1;
  }
  debug(5, "IPv6 Netmax (Base = $netbase with $n_bits) $netmax\n");
  my $candidate = $netbase + $VV_COUNT;
  debug(5, "\tCandidate: $candidate\n");
  return -1 if ($candidate > $netmax);
  $candidate = $digitpfx.$candidate; # Restore hex prefix if needed
  debug(5, "\tReturning: ".$quartets[0].":".$quartets[1].":".$quartets[2].":".$candidate."::/64\n");
  return($quartets[0].":".$quartets[1].":".$quartets[2].":".$candidate."::/64");
}

sub VV_get_prefix4
# Return the $VV_COUNT'th /24 prefix from $VV_prefix4 (if possible), or -1 if error.
{
  my $VV_COUNT = shift @_;
  my $VV_prefix4 = shift @_;
  my ($net, $mask) = split(/\//, $VV_prefix4);
  debug(5, "VV_get_prefix4 Count: $VV_COUNT Prefix: $net Mask: $mask\n");
  my @octets = split(/\./, $net);
  my $netbase = ($octets[0] << 24) + ($octets[1] << 16) + ($octets[2] << 8) + $octets[3];
  my $n = ((2 ** (32 - $mask)) / 256);
  debug(5, "\t\tAllows $n Vendor VLANs.\n");
  my $netmax = $netbase + (2 ** (32 - $mask)) -1;
  my $candidate = $netbase + ($VV_COUNT << 8);
  debug(5, "\tBase: $netbase Max: $netmax Candidate: $candidate\n");
  return(-1) if ($candidate > $netmax);
  debug(5, "\tBase:\n");
  debug(5, "\t\t3 -> ($netbase ->)", $netbase % 256, ".\n");
  $octets[3] = ($netbase % 256);
  $netbase >>= 8;
  debug(5, "\t\t2 -> ($netbase ->)", $netbase % 256, ".\n");
  $octets[2] = ($netbase % 256);
  $netbase >>= 8;
  debug(5, "\t\t1 -> ($netbase ->)", $netbase % 256, ".\n");
  $octets[1] = ($netbase % 256);
  $netbase >>= 8;
  debug(5, "\t\t0 -> ($netbase ->)", $netbase % 256, ".\n");
  debug(5, "\tMAX:\n");
  debug(5, "\t\t3 -> ($netmax ->)", $netmax % 256, ".\n");
  $octets[3] = ($netmax % 256);
  $netmax >>= 8;
  debug(5, "\t\t2 -> ($netmax ->)", $netmax % 256, ".\n");
  $octets[2] = ($netmax % 256);
  $netmax >>= 8;
  debug(5, "\t\t1 -> ($netmax ->)", $netmax % 256, ".\n");
  $octets[1] = ($netmax % 256);
  $netmax >>= 8;
  debug(5, "\t\t0 -> ($netmax ->)", $netmax % 256, ".\n");
  $octets[0] = ($netmax % 256);
  debug(5, "\tResult: ".join(".", @octets)."/24.\n");
  debug(5, "\tCandidate:\n");
  debug(5, "\t\t3 -> ($candidate ->)", $candidate % 256, ".\n");
  $octets[3] = ($candidate % 256);
  $candidate >>= 8;
  debug(5, "\t\t2 -> ($candidate ->)", $candidate % 256, ".\n");
  $octets[2] = ($candidate % 256);
  $candidate >>= 8;
  debug(5, "\t\t1 -> ($candidate ->)", $candidate % 256, ".\n");
  $octets[1] = ($candidate % 256);
  $candidate >>= 8;
  debug(5, "\t\t0 -> ($candidate ->)", $candidate % 256, ".\n");
  $octets[0] = ($candidate % 256);
  debug(5, "\tResult: ".join(".", @octets)."/24.\n");
  return(join(".", @octets)."/24");
}

sub VV_get_vlid
# Return the $VV_COUNT'th vlan ID from $VV_LOW to $VV_HIGH (if possible), or -1 if error.
{
  my $VV_COUNT = shift @_;
  my $candidate = $VV_LOW + $VV_COUNT;
  return -1 if ($candidate > $VV_HIGH);
  return $candidate;
}

sub VV_init_firewall
# Return a string contiaing the base firewall configuration fragment for a switch
{
  my  $VV_firewall = <<EOF;
    family inet {
        filter only_to_internet {
            term ping {
                from {
                    destination-address {
                        10.0.0.0/8;
                    }
                    protocol icmp;
                }
                then {
                    accept;
                }
            }
            term dns {
                from {
                    destination-address {
                        10.0.3.0/24;
                        10.128.3.0/24;
                    }
                    destination-port domain;
                }
                then {
                    accept;
                }
            }
            term dhcp {
                from {
                    destination-address {
                        10.0.3.0/24;
                        10.128.3.0/24;
                    }
                    destination-port [ bootps dhcp ];
                }
            }
            term no-rfc1918 {
                from {
                    destination-address {
                        10.0.0.0/8;
                        172.16.0.0/12;
                        192.168.0.0/16;
                    }
                }
                then {
                    reject;
                }
            }
            term to-internet {
                from {
                    destination-address {
                        0.0.0.0/0;
                    }
                }
                then {
                    accept;
                }
            }
        }
        filter only_from_internet {
            term dns {
                from {
                    source-address {
                        10.0.3.0/24;
                        10.128.3.0/24;
                    }
                    source-port domain;
                }
                then {
                    accept;
                }
            }
            term dhcp {
                from {
                    source-address {
                        10.0.3.0/24;
                        10.128.3.0/24;
                    }
                    source-port [ bootps dhcp ];
                }
                then {
                    accept;
                }
            }
            term no-rfc1918 {
                from {
                    source-address {
                        10.0.0.0/8;
                        172.16.0.0/12;
                        192.168.0.0/16;
                    }
                }
                then {
                    discard;
                }
            }
            term to-internet {
                from source-address {
                    0.0.0.0/0;
                }
                then {
                    accept;
                }
            }
        }
    }
    family inet6 {
        filter only_to_internet6 {
          term dns {
                from {
                    destination-address {
                        $PREFIX:103::/64;
                        $PREFIX:503::/64;
                    }
                    destination-port domain;
                }
                then {
                    accept;
                }
          }
	  term ipv6_icmp_basics {
              from {
                  destination-address {
                        $PREFIX::/48
                  }
                  icmp-type [ neighbor-solicit neighbor-advertisement router-solicit packet-too-big time-exceeded ];
              }
              then {
                  accept;
              }
          }
          term ping {
              from {
                  destination-address {
                        $PREFIX::/48
                  }
                  icmp-type [ echo-reply echo-request ];
              }
              then {
                  accept;
              }
          }
          term dhcp {
                from {
                    destination-address {
                        $PREFIX:103::/64;
                        $PREFIX:503::/64;
                    }
                    destination-port [ bootps dhcp ];
                }
                then {
                    accept;
                }
          }
          term no-local {
                from {
                    destination-address {
                        $PREFIX::/48;
                        fc00::/7;
                    }
                }
                then {
                    reject;
                }
          }
          term to-internet {
                from {
                    destination-address {
                        ::/0;
                    }
                }
                then {
                    accept;
                }
            }
        }
        filter only_from_internet6 {
	  term ipv6_icmp_basics {
              from {
                  icmp-type [ neighbor-solicit neighbor-advertisement router-advertisement packet-too-big time-exceeded ];
              }
              then {
                  accept;
              }
          }
          term dns {
                from {
                    source-address {
                        $PREFIX:103::/64;
                        $PREFIX:503::/64;
                    }
                    source-port domain;
                }
                then {
                    accept;
                }
          }
          term dhcp {
                from {
                    source-address {
                        $PREFIX:103::/64;
                        $PREFIX:503::/64;
                    }
                    source-port [ bootps dhcp ];
                }
                then {
                    accept;
                }
          }
          term no-local {
                from {
                    source-address {
                        $PREFIX::/48;
                        fc00::/7;
                    }
                }
                then {
                    discard;
                }
          }
          term to-internet {
                from {
                    source-address {
                        ::/0;
                    }
                }
                then {
                    accept;
                }
          }
        }
    }
EOF
  return $VV_firewall;
}



sub build_vendor_from_config
# Return a reference to a hash containing the following elements:
# "interfaces" -> An interface configuration fragment for all Vendor related VLAN interfaces
# "vlans"      -> A vlan configuration fragment for all Vendor related VLANs
# "vlans_l3"    -> An interface configuration fragment for all Vendor VLAN L3 interfaces
# "defgw_ipv4" -> A routing-options configuration fragment to provide an IPv4 default gateway for the Vendor VLANs
# "firewall"   -> A firewall configuration fragment to provide the necessary filters to prevent Vendor VLANs from attacking others.
# "dhcp"       -> A forwarding-options configuration fragment to provide dhcp-relay configuration
{
  my $hostname = shift @_;
  debug(5, "Building Vendor VLANs for $hostname\n");
  # Retrieve Switch Type Information
  my ($Name, $Number, $MgtVL, $IPv6addr, $Type) = get_switchtype($hostname);
  
  my $port = 0;
  # Read Type file and produce interface configuration
  my $switchtype = read_config_file("types/$Type");
  debug(5, "$hostname: type: $Type, received ", scalar(@{$switchtype}),
      " lines of config\n");
  
  # Local strings to hold configuration fragments
  my $VV_interfaces = "";
  my $VV_vlans = "";
  my $VV_vlans_l3 = "";
  my $VV_defgw_ipv4 = "";
  my $VV_firewall = "";
  my $VV_dhcp = "";
  my $VV_protocols = "";

  # Local scratchpad variables for tracking elements that apply to multiple configuration fragments
  my $VV_portcount = 0;
  my @VV_intlist = ();
  my %VV_v6_map = ();

  # Construct empty hashref to use later for return value
  my $VV_hashref = {
  };

  my $VV_portmap = "";
  my $intnum = 0;
  my ($VLANS, $VLANS_byname) = build_vlan_hash();
  foreach(@{$switchtype})
  {
    my @tokens = split(/\t/, $_); # Split line into tokens
    my $cmd = shift(@tokens);     # Command is always first token.
    debug(5, "\tCommand: $cmd (intnum: $intnum)", join(",", @tokens), "\n");
    if ($cmd eq "RSRVD")
    {
      # Skip -- Not vendor VLAN related, handled elsewhere
      # Need to account for the interfaces, though.
      my $count = $tokens[0];
      $intnum += $count;
      debug(5, "\t\tSkipping $count reserved ports, new intnum $intnum.\n");
    }
    elsif ($cmd eq "TRUNK" || $cmd eq "FIBER")
    {
      # Skip -- Not vendor VLAN related, handled elsewhere
      # Need to account for the interfaces, though.
      my $iname = $tokens[0];
      my ($name,$instance) = split(/-/, $iname);
      my ($fpc, $slot, $port) = split(/\//, $instance);
      $intnum = $port+1 if ($port >= $intnum);
      debug(5, "\t\tFound port definition for $name-$fpc/$slot/$port, new intnum $intnum.\n");
    }
    elsif ($cmd eq "VLAN")
    {
      # Skip -- Not vendor VLAN related, handled elsewhere
      # Need to account for the interfaces, though.
      my $count = $tokens[0];
      $intnum += $count;
      debug(5, "\t\tSkipping $count vlan ports, new intnum $intnum.\n");
    }
    elsif ($cmd eq "VVLAN")
    {
      debug(5, "Command: $cmd ", join(",", @tokens),"\n");
      # Determine number of ports to build out
      my $count = $tokens[0];
      $VV_portcount = $count;
      # Build config fragments for each interface.
      debug(5, "Building $count Vendor Interfaces starting at ge-0/0/$intnum\n");


      # Initialize config fragments. These initialized values (may) get appended to for each interface.
      $VV_interfaces = "";
      my $v4_nexthop = ($MgtVL < 500) ? "10.2.0.1" : "10.130.0.1";
      debug(5, "Vendor v4_nexthop set to $v4_nexthop\n");
      $VV_defgw_ipv4 = <<EOF;
    static {
        route 0.0.0.0/0 next-hop $v4_nexthop;
    }
EOF
      $VV_firewall = VV_init_firewall();
      my $VV_BASE = VV_get_vlid(0); # Get the base Vendor VLAN
      while ($count)
      {
        my $VLID = VV_get_vlid($VV_COUNT);
        debug(5, "$count remaining -- VV_COUNT $VV_COUNT, VLID $VLID.\n");
        if ($VLID < 0)
        {
          die("ERROR: Not enough Vendor VLANs defined in VVRNG.\n");
        }
        my $VL_prefix6 = VV_get_prefix6($VV_COUNT, $VV_prefix6);
        debug(5, "\tVL_prefix6 $VL_prefix6.\n");
        if ($VL_prefix6 < 0)
        {
          die("ERROR: Couldn't get IPv6 prefix for Vendor VLAN ($VV_COUNT)\n");
        }
        my $VL_prefix4 = VV_get_prefix4($VV_COUNT, $VV_prefix4);
        debug(5, "\tVL_prefix4 $VL_prefix4.\n");
        if ($VL_prefix4 < 0)
        {
          die("ERROR: Couldn't get IPv4 prefix for Vendor VLAN ($VV_COUNT)\n");
        }
#	"interfaces"  -> $VV_interfaces,
#       context: interfaces { <here> }
        my $myvlan = $VV_name_prefix.$VLID;
        $VV_interfaces .= <<EOF;
    ge-0/0/$intnum {
        unit 0 {
            description "Vendor VLAN $VLID"
            family ethernet-switching {
                port-mode access;
                vlan {
                    members $myvlan;
                }
            }
        }
    }
EOF
##FIXME## Use colors from file
        my $vlinfo=${$VLANS}{$VV_BASE};
        debug(4, "For $cmd $_ -> Vendor $VLID (pulled from $VV_BASE): ".Dumper(@{$vlinfo})."\n");
        debug(5, "Background: ".${$vlinfo}[6]." -> ".Dumper(parse_hex_color(${$vlinfo}[6]))."\n");
        debug(5, "Text: ".${$vlinfo}[6]." -> ".Dumper(parse_hex_color(${$vlinfo}[7]))."\n");
        my $bgcolor = join(" ", parse_hex_color(${$vlinfo}[6]));
        my $fgcolor = join(" ", parse_hex_color(${$vlinfo}[7]));
        $VV_portmap .= <<EOF;
false $fgcolor (Vnd_$VLID) $bgcolor $intnum DrawPort
EOF
#	"vlans"       -> $VV_vlans,
#	context: vlans { <here> }
        debug(5, "Name_prefix: x$VV_name_prefix"."x VLID: x$VLID"."x\n");
        my $vv_name = $VV_name_prefix.$VLID;
            $VV_vlans .= <<EOF;
    $vv_name {
        vlan-id $VLID
        l3-interface vlan.$VLID;
    }
EOF
#	"vlans_l3"    -> $VV_vlans_l3,
#       context: interfaces { vlan { <here> ... [}] }
        my ($pref,$mask) = split(/\//, $VL_prefix4);
        debug(5, "L3 Interface $VLID v4 = $pref / $mask.\n");
        $pref =~ s/\.0$/.1/;
        debug(5, "\t-> $pref\n");
        my $VL_addr4 = join("/", $pref, $mask);
        ($pref,$mask) = split(/\//, $VL_prefix6);
        debug(5, "L3 Interface $VLID v6 = $pref / $mask.\n");
        $pref =~ s/::$/::1/;
        debug(5, "\t-> $pref\n");
        my $VL_addr6 = join("/", $pref, $mask);
        debug(5, "L3 Interface $VLID -- v4 = $VL_addr4, v6 = $VL_addr6\n");
        $VV_vlans_l3 .= <<EOF;
        unit $VLID {
            family inet {
                address $VL_addr4;
                filter input only_to_internet;
                filter output only_from_internet;
            }
            family inet6 {
                address $VL_addr6;
                filter input only_to_internet6;
                filter output only_from_internet6;
            }
        }
EOF
# These two are simply used in their initialized state (currently)...
#	"defgw_ipv4" -> $VV_defgw_ipv4,
#	"firewall"    -> $VV_firewall,

#	"dhcp"        -> $VV_dhcp,
#       Build list of Vendor VLAN Interfaces for later use to build DHCP forwarders
        push @VV_intlist, "vlan.$VLID";
        $VV_v6_map{"vlan.$VLID"} = $VL_prefix6;
        debug(5, "Mapped $VL_prefix6 to vlan.$VLID\n");

        # Increment / decrement counters
        $intnum++;	# Next interface (ge-0/0/{$intnum})
        $VV_COUNT++;	# Vendor VLAN Counter
        $count--;	# Remaining unprocessed interfaces in this group
      }
    }
    elsif ($cmd eq "VVBB")
    {
      $VV_vlans .= <<EOF;
    vendor_backbone {
        description "Vendor Backbone";
        vlan-id 499;
        l3-interface vlan.499;
    }
EOF
      my $ipv4_suffix = $VV_COUNT + 10;
      $VV_vlans_l3 .= <<EOF;
        unit 499 {
            family inet {
                address 10.1.0.$ipv4_suffix/24;
            }
        }
EOF
    }
  }
  # Finish up strings that need to be terminated (currently just $VV_vlans_l3)
  # Finalize DHCP Forwarder configuration
  my $active_srv_grp = ($MgtVL < 500) ? "Expo" : "Conference";
  # Hack for Hilton (SCaLE 19x)
  #my $active_srv_grp = ($MgtVL < 500) ? "Hilton" : "Conference";
  $VV_dhcp = <<EOF;
forwarding-options {
    dhcp-relay {
        dhcpv6 {
            group vendors {

EOF

  foreach (@VV_intlist)
  {
    $VV_dhcp .= <<EOF;
                interface $_;
EOF

  }

  $VV_dhcp .= <<EOF;
            }
            server-group {
                Conference {
                    $PREFIX:503::5;
                }
                Expo {
                    $PREFIX:103::5;
                }
                Vendors {
                    $PREFIX:103::5;
                }
                Hilton {
                    $PREFIX:103::5;
                }
                AV {
                    $PREFIX:105::10;
                }
            }
            active-server-group $active_srv_grp;
        }
        server-group {
            Conference {
                10.128.3.5;
            }
            Expo {
                10.0.3.5;
            }
            Vendors {
                10.0.3.5;
            }
            Hilton {
                10.0.3.5;
            }
            AV {
                10.0.5.10;
            }
        }
        active-server-group $active_srv_grp;
        group vendors {
EOF

  foreach (@VV_intlist)
  {
    $VV_dhcp .= <<EOF;
                interface $_;
EOF

  }

  $VV_dhcp .= <<EOF;
        }
    }
}
EOF

#    "protocols"    -> $VV_protocols
#   Build OSPF configuration to advertise Vendor VLANs across vendor-backbone network
#   Build router-advertisement configuration for Vendor VLANs
#   Context: protocols { <here> }
  $VV_protocols .= <<EOF;
    router-advertisement {
EOF
  foreach (@VV_intlist)
  {
    my $pfx = $VV_v6_map{$_};
    $VV_protocols .= <<EOF;
        interface $_ {
            other-stateful-configuration;
            dns-server-address $PREFIX:103::5;
            dns-server-address $PREFIX:103::15;
            prefix $pfx {
                on-link;
                autonomous;
            }
        }
EOF
  }
  $VV_protocols .= <<EOF;
    }
    ospf {
        area 0.0.0.0 {
            interface vlan.103;
            interface vlan.499;
EOF
  foreach (@VV_intlist)
  {
     $VV_protocols .= <<EOF;
            interface $_ {
                passive;
            }
EOF
  }

  $VV_protocols .= <<EOF;
        }
    }
    ospf3 {
        area 0.0.0.0 {
            interface vlan.103;
EOF

  foreach (@VV_intlist)
  {
     $VV_protocols .= <<EOF;
            interface $_ {
                passive;
            }
EOF
  }

  $VV_protocols .= <<EOF;
        }
    }
EOF


  if ($VV_portcount == 0) # No VVLAN statement encountered.
  {
    return(0);
  }
  else
  {
    # Put cooked values into initialized hashref
    my $VV_hashref = {
        "interfaces"  => $VV_interfaces,
        "vlans"       => $VV_vlans,
        "vlans_l3"    => $VV_vlans_l3,
        "defgw_ipv4" => $VV_defgw_ipv4,
        "firewall"    => $VV_firewall,
        "dhcp"        => $VV_dhcp,
        "protocols"   => $VV_protocols,
    };
    debug(5, "Returning Vendor parameters:\n");
    debug(5, Dumper($VV_hashref));
    return($VV_hashref, $VV_portmap);
  }
}

# Build POE Configuration from port list
sub build_poe_from_portlist
{
  my $OUTPUT = "";
  foreach(@_)
  {
    $OUTPUT .= "    interface $_;\n";
  }
  return($OUTPUT);
}

# Put it all together
sub build_config_from_template
{
  # Add input variables here:
  my $hostname = shift @_;
  my $root_auth = shift @_;
  $VV_name_prefix = shift @_;
  
  # Add configuration file fetches here:
  my $TRUNK_MACROS = build_trunktypes_from_config($hostname);
  my $USER_AUTHENTICATION = build_users_from_auth();
  my ($INTERFACES_PHYSICAL, $POE_PORTS, $portmap) = build_interfaces_from_config($hostname);
  my $POE_CONFIG = build_poe_from_portlist(@{$POE_PORTS});
  my $VLAN_CONFIGURATION = build_vlans_from_config($hostname);
  my ($vcfg, $portmap_vendor) = build_vendor_from_config($hostname);
  my %VENDOR_CONFIGURATION = {};
  our $PREFIX = get_prefix();
  %VENDOR_CONFIGURATION = %{$vcfg} if (reftype $vcfg eq reftype {});;
  debug(5, "Received Vendor configuration:\n");
  debug(5, Dumper(%VENDOR_CONFIGURATION));
  debug(5, "End Vendor Config\n");
  my ($INTERFACES_LAYER3, $IPV6_DEFGW) = build_l3_from_config($hostname);
  $INTERFACES_PHYSICAL .= ${VENDOR_CONFIGURATION}{"interfaces"};
  $VLAN_CONFIGURATION  .= ${VENDOR_CONFIGURATION}{"vlans"};
  $INTERFACES_LAYER3   .= ${VENDOR_CONFIGURATION}{"vlans_l3"};
  my $IPV4_DEFGW        = ${VENDOR_CONFIGURATION}{"defgw_ipv4"};
  my $FIREWALL_CONFIG   = ${VENDOR_CONFIGURATION}{"firewall"};
  my $DHCP_CONFIG       = ${VENDOR_CONFIGURATION}{"dhcp"};
  my $PROTOCOL_CONFIG   = ${VENDOR_CONFIGURATION}{"protocols"};
  debug(5, "Final IPv4 Gateway = \n".$IPV4_DEFGW."\n<end>\n");
  my $OUTPUT = <<EOF;
system {
    host-name $hostname;
    root-authentication {
        encrypted-password "$root_auth";
    }
    syslog {
        host loghost {
        any any;
        }
    }
    login {
$USER_AUTHENTICATION
    }
    services {
        ssh {
            no-passwords;
            protocol-version v2;
        }
        netconf {
            ssh;
        }
    }
    syslog {
        user * {
            any emergency;
        }
        file messages {
            any notice;
            authorization info;
        }
        file interactive-commands {
            interactive-commands any;
        }
    }
}
chassis {
    alarm {
        management-ethernet {
        link-down ignore;
        }
    }
    fpc 0 {
	pic 1 {
            sfpplus {
                pic-mode 1g;
            }
        }
    }
}
snmp {
    community Junitux {
        authorization read-only;
        clients {
        $PREFIX:103::/64;
        $PREFIX:503::/64;
        }
    }
}
interfaces {
$INTERFACES_PHYSICAL
    vlan {
$INTERFACES_LAYER3
    }
}
$DHCP_CONFIG
routing-options {
    $IPV4_DEFGW
    rib inet6.0 {
        static {
            route ::/0 next-hop $IPV6_DEFGW;
        }
    }
}
poe {
$POE_CONFIG
}
protocols {
    igmp-snooping {
        vlan all;
    }
    rstp;
    lldp {
        interface all;
        port-id-subtype interface-name;
    }
    lldp-med {
        interface all;
    }
$PROTOCOL_CONFIG
}
firewall {
$FIREWALL_CONFIG
}
ethernet-switching-options {
    storm-control {
        interface all;
    }
}
vlans {
$VLAN_CONFIGURATION
}
EOF
  my $postamble = <<EOF;
end %End of local dictionary (SwitchMapDict) for EPS
EOF


  return($OUTPUT, $portmap.$portmap_vendor.$postamble);
}

#my $cf = build_config_from_template("NW-IDF",
#    '$1$qQMsQS3c$DmHnv3mHPwDuE/ILQ.yLl.');
#print $cf;

1;
