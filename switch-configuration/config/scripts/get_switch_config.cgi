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

# Load libraries
use lib "$REPO/switch-configuration/config/scripts";
use switch_template;

# Parse the Query String from the web server
$QUERY = $ENV{'QUERY_STRING'};
parse_query($QUERY);

# Step 1: Move current working directory to repo
chdir("$REPO") || send_abort("Failed to enter repository.", "$!");

# Step 2: Refresh the repo and make sure we are on current master
system("git checkout master") == 0 || send_abort("Failed git checkout.", "$? : $!");
system("git fetch origin master") == 0 || send_abort("Failed git fetch.", "$? : $!");; 
system("git reset --hard origin/master") == 0 || send_abort("Failed hard reset of git repo to origin/master.", "$? : $!");

# Step 3: Build any updated files
chdir("switch-configuration") || send_abort("Failed to enter switch-configuration directory.", "$? : $!");
if ($CLEAN)
{
    system("make clean") == 0 || send_abort("Failed specified cleaning process, configuration files may be invalid.", "$? : $!");
}
system("make") == 0 || send_abort("Failed make process, configuration files may be invalid.", "$? : $!");

# Step 4: identify the switch
#   load the switch configuration database
get_switchtype("anonymous");
#   Identify switch from MAC address
my @switches = get_switch_by_mac($MAC);
if (scalar(@switches) < 1)
{
    send_abort("No match found for MAC Address: \"$MAC\".");
}
elsif (scalar(@switches) > 1)
{
    send_abort("Error: Multiple matches for MAC Address: \"$MAC\":",@switches);
}
#   Retrieve switch configuration file
my $file = "$REPO"."/switch_configuration/config/output/".$switch.".conf";
open(CONFIG, "<$file") || send_abort("Couldn't read configuration file.", "$!");
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
print join("\n<P>", @_);
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
	if ($A eq "MAC" || $A eq "CLEAN")
	{
            print STDERR "Evaluating \'\$\'.$A.\" = $V\"\n";
            eval('$'.$A." = $V");
	    print STDERR "Result: ($A) ($V) ($MAC) ($CLEAN)\n";
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

