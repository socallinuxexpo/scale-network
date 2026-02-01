#!/usr/bin/env perl
#
# This script is the server side of the ZTP switch configuratoin process.
#
# It will process the query string to pull out the MAC address (MAC= variable)
# to identify the correct switch name from the switchtypes file. It will then
# send the necessary headers for a text/plain document and then send the correct
# configuration file for the switch.
#
# The script depends on having a copy of the SCALE networking Repository in a known location
# (/var/www/scale-repo/scale-network).

BEGIN {
    # Define global varialbes and placeholders
    our $REPO = "/var/www/scale-repo/scale-network";
}
my $QUERY = "";
my $MAC = "";
my $CLEAN = "";
my $BRANCH = "master";

# Load libraries
use lib "$REPO/switch-configuration/config/scripts";
use switch_template;
set_debug_level(0);

# Parse the Query String from the web server
$QUERY = $ENV{'QUERY_STRING'};
parse_query($QUERY);
if ( -z "$BRANCH" )
{
  $BRANCH="master";
}

# Step 1: Move current working directory to repo
chdir("$REPO") || send_abort("Failed to enter repository.", "$!");

# Step 2: Refresh the repo and make sure we are on current master
my $git_success = 0;
my $git_retries = 0;
my $abort_string = "";
until ($git_success > 0 || $git_retries > 3)
{
  $git_success = 1;
  $git_retries++;
  unless(system("git checkout $BRANCH >/dev/null") == 0)
  {
    $abort_string .= "Retry: $git_retries" . join("\n", "Failed git checkout of $BRANCH.", "$? : $!");
    $git_success = 0;
  }
  unless(system("git fetch origin $BRANCH >/dev/null") == 0)
  {
    $abort_string .= join("\n", "Failed git fetch of $BRANCH.", "$? : $!");
    $git_success = 0;
  }
  unless(system("git reset --hard origin/$BRANCH >/dev/null") == 0)
  {
    $abort_string .= join("\n", "Failed hard reset of git repo to origin/$BRANCH.", "$? : $!");
    $git_success = 0;
  }
}
unless($git_success)
{
  send_abort($abort_string);
  print STDERR "Potential git issues: $abort_string\n";
}
else
{
  print STDERR "git success: $git_success ($git_retries) ($abort_string)\n";
}

# Step 3: Build any updated files
chdir("switch-configuration") || send_abort("Failed to enter switch-configuration directory.", "$? : $!");
if ($CLEAN)
{
    system("make clean") == 0 || send_abort("Failed specified cleaning process, configuration files may be invalid.", "$? : $!");
}
system("make 2>/dev/null >/dev/null") == 0 || send_abort("Failed make process, configuration files may be invalid.", "$? : $!");

# Step 4: identify the switch
#   load the switch configuration database
chdir("config") || send_abort("Failed to chdir into config directory.", "$? : $!");
get_switchtype("anonymous");
#   Identify switch from MAC address
#   Unfortunately, Juniper doesn't make this easy. The VME interface doesn't have a consistent MAC address or a consistent offset from the base MAC address.
#   We can, however, usually get away with the following assumptions:
#      The base MAC address (or something close enough to it) can be assumed to be the reported MAC address with the last nibble zeroed.
#        (xx:xx:xx:xx:xx:yy -> xx:xx:xx:xx:xx:y0)
#      If we search all of the values between 0 and f for that last octet, we are unlikely to hit more than one switch.
#      If we search all of the values between 0 and f, the first one that hits should be a valid match to our switch.
#
# Fuzzy MAC search loop:
#  Get base MAC address (ish) from MAC
my @M = split(/:/, $MAC);
$M[5] =~ s/^(.).$/\1/;
print STDERR "Found base MAC \"", join(":", @M)."0", "\" from $MAC\n";
my @switches;
foreach my $m (0..0xf)
{
  my @MM = @M; # Copy the base MAC
  $MM[5] .= sprintf ("%1x", $m);
  my $MAC = join(":", @MM);
  print STDERR "Trying against MAC $MAC\n";
  print STDERR "get_switch_by_mac($MAC)\n";
  @switches = get_switch_by_mac($MAC);
  print STDERR "get_switch_by_mac($MAC) returned \"", join(",", @switches), "\"\n";
  next if(scalar(@switches) < 1); # Try the next entry.
  send_abort("Error: Multiple matches for MAC address \"$MAC\":", @switches) if(scalar(@switches) > 1);
  last;
}
if (scalar(@switches) < 1)
{
  my @MM = @M;
  if ($MM[5] < 0x80)
  {
    $MM[5] = "7f";
  {
  else
  {
    $MM[5] = "ff";
  }
  my $MAC = join(":", @MM);
  print STDERR "Last Ditch attempt against MAC $MAC\n";
  @switches = get_switch_by_mac($MAC);
  print STDERR "get_switch_by_mac($MAC) returned \"", join(",", @switches), "\"\n";
  send_abort("Error: Multiple matches for MAC address \"$MAC\":", @switches) if(scalar(@switches) > 1);
  if (scalar(@switches < 1)
  {
    send_abort("No match found for MAC Address: \"$MAC\".", @switches);
  }
}
#   Retrieve switch configuration file
my $file = "$REPO"."/switch-configuration/config/output/".$switches[0].".conf";
open(CONFIG, "<$file") || send_abort("Couldn't read configuration file.", "$file", "$!");
send_plain_header();
foreach(<CONFIG>)
{
    print $_;
}
close CONFIG;
exit 0;

# Send an HTML page containing the reaosn things failed.
sub send_abort
{
    send_html_header();
    print <<EOF;
    <HTML>
        <HEAD>
            <TITLE>ERROR Page</TITLE>
        </HEAD>
        <BODY>
            <H1>ERROR Encountered</H1>
	    <P>
EOF
print join("\n            <P>", @_);
print "\n";
print <<EOF;
        </BODY>
    </HTML>
EOF
exit 1;
}

# Brute force approach to parsing simple QUERY_STRING from web server. Should use a library and do something more elegant
# in the future.
sub parse_query
{
    my $QUERY = shift(@_);
    my @Q = split('&', $QUERY);
    foreach(@Q)
    {
	my $qs = $_;
        my ($A, $V) = split('=');
	if ($A eq "MAC" || $A eq "CLEAN" || $A eq "BRANCH")
	{
            my $S = '$'.$A." = \"$V\"";
	    eval($S);
	}
	else
	{
            send_abort("Invalid query. ($QUERY) ($qs) $A ($V)");
	}
    }
}

# Send a basic HTTP header for an HTML document to follow.
sub send_html_header
{
    print <<EOF;
Content-type: text/html; charset=iso-8859-1

EOF
}

# Send a basic HTTP header for a text/plain document to follow.
sub send_plain_header
{
    print <<EOF;
Content-type: text/plain; charset=iso-8859-1

EOF
}

