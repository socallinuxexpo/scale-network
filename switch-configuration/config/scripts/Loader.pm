#!/usr/bin/perl
#
# Library to aid in loading configurations onto switches
#
# Provides a number of (POD documented) functions to aid
# in the loading of configurations onto switches.
#
# Dependencies:
#       switch_template.pl      -- Switch Configuration Library
#       FileHnadle              -- Allows use of scalar variables for Files
#       IPC::Open2              -- Allows simplification of Pipe opens
#       Net::Ping               -- Ping without system()
#       Expect                  -- PERL Expect Library - simplifies communication with switches
#       Term::ReadKey           -- Simlifies password requests and similar
#       Net::SSH                -- ssh without system()
#       Net::SFTP               -- sftp without system()
#       Net::ARP                -- arp without system()
#       Time::HiRes             -- Used for usleep (sleep for microseconds)

# Pull in dependencies
use strict;
require "./scripts/switch_template.pl";
use FileHandle;
use IPC::Open2;
use Net::Ping;
use Expect;
use Term::ReadKey;
use Net::SSH;
use Net::SFTP;
use Net::ARP;
use Time::HiRes;

package Loader;
=pod

=head1 Loader -- A set of routines desinged to help load configurations onto Juniper Switches

Implements an object oriented interface and provides a class to make it easy to maintain state.

=over

=item

my $OBJ = new Loader()

=over

Creates a new Loader object

=back

=back

=cut

BEGIN
{
        $Loader::VERSION = '1.0';
        $Loader::line_dely = 50 * 1000; # Delay 50 milliseconds between lines sent to /dev (presumably serial line)
}

=pod

=over

=item

version(required_ver)

=over

Compares Configured VERSION string to required_ver and calls warn() if (VERSION\<required_ver)

=back

=back

=cut

sub version
{
        my ($version) = @_;

        warn "Version $version is later than $Expect::VERSION. It may not be supported."
                if ( defined($version) && ( $version > $Expect::VERSION ) );

}

sub new
{
        my ($class, @args) = @_;

        $class = ref($class) if ref($class); # Allows calling as $exp->new()

        STDERR->autoflush(1);   # Turn on autoflush for STDERR
        get_switchtype("anonymous");
        $Loader::ping = Net::Ping->new("icmp");
        $Loader::DefaultIP = "192.168.255.76"; # Switch target management IP
        $Loader::line_dely = 50 * 1000; # Delay 50 milliseconds between lines sent to /dev (presumably serial line)
}

=pod

=over

=item

$OBJ->detect_switch([$target])

=over

Detects the presence of a (pingable) switch. If $target is suppplied, must be an IP or hostname which can
be pased to Net::Ping(). This method will block until the object becomes responsive to ICMP and then return.
This must be on a directly connected network and cannot require routing because the arp talbe must contain
the MAC address of the device after pinging.  Once the object begins responding, the Mac address will be
used to identify the object and return the Name of the attached switch. (This is useful for bulk loading
many switches in rapid succession).

=back

=back

=cut

sub detect_switch
{
  my $IP = shift @_; # Check for optional IP argument
  $IP = $Loader::DefaultIP unless $IP; # Default to Package Default IP if not specified
  while (1) {
    
    # delete ARP entry for 192.168.255.76 (Requires sudo for privileges)
    # Turns out to be unnecessary and annoying.
    # system("sudo", "arp","-d","$IP");
    
    # ping $IP until success
    my $success = 0;
    print "Looking for switch on line.\n";
    do {
        my $result = $ping->ping($IP);
        $success++ unless($result);
        sleep 1; # Retry every second until success.
    } until($success);
    
    print "Switch detected, identifying.\n";

#    my $arp = `arp -n $IP | grep $IP`;
#    chomp($arp);
#    $arp = lc($arp);
#    # Harry regex to support differing arp outputs (BSD vs. Linux vs. MacOS)
#    $arp =~ s@^.*(at|ether)\s+([0-9a-f:]+)\s+.*$@\2@m;
#    if ($arp =~ /\n/)
#    {
#        warn("Multiple ARP table entries for address $IP:\n");
#        foreach(split(/\n/, $arp))
#        {
#            warn("\t$_\n");
#        }
#        warn("Basing configuration load on first one.\n");
#        $arp =~ s/\n.*//;
#    }
    my $arp = Net::ARP::arp_lookup(undef, $IP) || die("Couldn't arp $IP\n");;

    
    print "Looking for MAC $arp in switchtypes table...";
    my @switchname = get_switch_by_mac($arp);
    print "Got ", scalar(@switchname), " names back from get_switch_by_mac($arp)\n";
    
    if (scalar(@switchname) < 1)
    {
        print STDERR "Error: No switchtype entry matching $arp\n";
        sleep 10;
        next; # Retry -- until file is corrected or a valid switch is provided
    }
    elsif (scalar(@switchname) > 1)
    {
        print STDERR "Error: $arp matches multiple switches (", join(", ", @switchname),").\n";
        sleep 10;
    get_switchtype("anonymous");
        continue; # Retry -- until file is corrected or a valid switch is provided
    }
    print "Found: $switchname[0].\n";
    my $switch = $switchname[0];

    return $switch;
  }
}

=pod

=over

=item

sftp_progress()

=over

This is primarily intended as an internal function. Used as a callback for Net::SFTP to provide a progress
report on in-progress file transfers.

=back

=back

=cut

sub sftp_progress
{
    my($sftp, $data, $offset, $size) = @_;
    print "Config: $offset / $size bytes |". "#" x int(($offset*1.0/$size*1.0) * 100.0) ."|\r";
}

=pod

=over

=item

override_switch($switch, $target, [$staged[, $config_file]])

=over

This function does the bulk of the work. It requires a switch name and a reachable target for the $switch
(IP address or [Serial] Device).

=over

=item

$switch contains the name of the switch (to be looked up to identify the default configuration and other things)

=item

$target contains the IP address or /dev/<name> to use to connect to $switch

=item

$staged if specified is a boolean value which, if true, will prevent the configuration from being committed on the switch

=item

$config_file if specified is the name of a file which will be loaded on to the switch as a configuration.

=back

A successful return from this function will have the required configuration loaded onto the switch and
committed. If the switch is attached by serial, the configuration will load very slowly (one line every
50 milliseconds or so). If by IP, then SCP will be used to copy the file to the switch and then SSH
via Expect will be used to apply the configuration to the switch.

=back

=back

=cut

sub override_switch
{
  my $switch = shift @_; # Required argument Switch Name
  my $target = shift @_; # SSH Reachable Target for configuration [1]
  my $staged = shift @_; # Optional argument -- True for -n staging/testing, False to actually scribble on switch
  my $config_file = shift @_; # Optional configuration file name

    # Assertions:
    #   output/$switch.conf (or $config_file) contains valid configuration files for this switch
    #   Switch is accessible via SSH at $target [1]
    #
    # [1] If $target matches /^\/dev\// then $target is treated as a direct attached TTY and the
    #   Load Override is done via a (slow) timed expect->send() sequence.
    #
    # Phase 1: Push new configuration file to switch.
    # Phase 2: Apply new configuration file using "load override <filename>" and commit it.
    #
    $SIG{PIPE} = \&catch_pipe;
    
    my ($Name, $Num, $MgtVL, $IPv6Addr, $Type);
    print "Looking up switch $switch\n";
    ($Name, $Num, $MgtVL, $IPv6Addr, $Type) = (get_switchtype($switch));
    die("Error: Couldn't get type for $switch (got $Name)\n") unless $Name eq $switch; 
    print "Got Entry:  $Name, $Num, $MgtVL, $IPv6Addr, $Type for $switch\n";

    # Phase 1: Copy configuration to device
    $config_file = "output/$Name.conf" unless $config_file;
    if (!-f "$config_file")
    {
        die("Error: Couldn't read configuration file $config_file for $Name");
    }
    print STDERR "Sending configuration file to $Name\n";
    my $JUNIPER = new Expect;
    my ($pos, $err, $matched, $before, $after);
    $JUNIPER->raw_pty(1);
    if ($target =~ /^\/dev\//)
    {
        # Send configuration via expect directly (skip $SWITCH_COMMANDS)
        open JDEVICE, "+<$target" || die("Failed to open $target for $Name\n");
        open CONFIG, "<$config_file" || die("Couldn't open $config_file for $Name: $!\n");
        $JUNIPER->exp_init(\*JDEVICE);
        Loader::Login($JUNIPER);
        Loader::Edit($JUNIPER);
        $JUNIPER->send("load override terminal\n");
        foreach my $c (<CONFIG>)
        {
            $JUNIPER->send($c);
            usleep($line_delay);
        }
        $JUNIPER->send("\n\cD\n");
        ($pos, $err, $matched, $before, $after) = $JUNIPER->expect(30,
            '# '
        );
        die("Did not get command pormpt back from $target after load override for $Name\n") if ($err);
        print STDERR "Activating...\n";
    }
    else
    {
        # Send cconfiguration file via SFTP, then use Expect to send $SWITCH_COMMANDS to activate
        my $result;
        my $sftp = Net::SFTP->new($target) || die("Failed to initiate SFTP to $target ($Name)\n");
        $sftp->put("$config_file", "/tmp/new_config.conf", &sftp_progress) ||
                die("Failed to send config to $target ($Name)\n");;
        print STDERR "Activating...\n";
        $JUNIPER->spawn($SSH, $target);
        Loader::Login($JUNIPER);    # Get to the CLI prompt
        Loader::Edit($JUNIPER);     # Transition from CLI to Edit Mode
        $JUNIPER->send("load override /tmp/new_config.conf\n");
        ($pos, $err, $matched, $before, $after) = $JUNIPER->expect(30,
                'load complete'
        );
        die("Did not receive \"load complete\" after loading config: $err for $Name\n") if ($err);
        ($pos, $err, $matched, $before, $after) = $JUNIPER->expedt(30,
                '# '
        );
        die("Did not receive Prompt after loading config: $err for $Name\n") if ($err);
    }
    # Here the direct device and SSH paths merge and $JUNIPER remains a filehandle to the switch
    # being configured regardless of whether serial or SSH.
    
    $JUNIPER->send("show | compare\n");
    ($pos, $err, $matched, $before, $after) = $JUNIPER->expect(30,
            '# '
    );
    die("Did not receive Prompt after \"show | compare\": $err for $Name\n") if ($err);
    print STDERR "Configuration Compares:\n";
    $before =~ s/[\r\n]+.*$//;
    print STDERR $before."\n";

    if ($staged)
    {
      # Roll it back rather than commit it.
      $JUNIPER->send("rollback\nquit\n");
    }
    else
    {
      # Commit it.
      $JUNIPER->send("commit and-quit\n");
    }
    ($pos, $err, $matched, $before, $after) = $JUNIPER->expect(30,
            '> '
    );
    die("Did not receive Prompt after finalizing: $err for $Name\n") if ($err);
    $JUNIPER->send("quit\n");
    $JUNIPER->soft_close();
    print STDERR "Successful completion of configuration for $Name\n";
}

=pod

=over

=item

Login($expect_object)

=over

Requires an Expect object as an argument. The Expect object must have been spawmned or initialized and the
device must be at a point where it is prepared to accept authentication. The routine tries to be pretty
flexible about all possible phases and methods of authentication, but as a result, it may infinitely loop
if it never gets an actual prompt that it expects (or never gets one that it believes indicates it is logged
in).

It does account for "%" (Root logged into shell), ">" (expected logged in), "ogin:" (needs username),
"passphrase" (SSH Key needs passphrase) and "password:" (password prompt from switch) states. Any other
state will likely trigger it's error response, which will send a newline to the switch in hopes of getting
something it understands.

Will die() on most serious errors. Does not provide a return value.

=back

=back

=cut

sub login
{
    my $JUNIPER = shift @_;
    my $logged_in = 0;
    do
    {
      # Initial connect will get us one of five possible situations:
      my ($pos, $err, $matched, $before, $after) = $JUNIPER->expect(30,
          'ogin:',
          'WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!',
          'Are you sure you want to continue connecting',
          'Enter passphrase',
          'password:',
          '% ',
          '> ');
      if ($err)
      {
        # In case we get stuck and missed the prompt or haven't seen
        # anything for some reason, warn and send a newline to the switch
        warn("Error: $err looking for authentication prompt\n");
        $JUNIPER->send("\n");
        next;
      }
      # Remote Key Change
      if ($matched =~ /ogin:/)
      {
        print "Remote Host requires username: ";
        my $username = ReadLine(0);
        chomp($username);
        $JUNIPER->send($username."\n");
      }
      elsif ($matched =~ /REMOTE HOST IDENTIFICATION/)
      {
        die("Error: Remote Host Key change detected, cannot continue. Please check ~/.ssh/known_hosts.\n");
      }
      # Handle prompt for host key not recognized
      elsif ($matched =~ /continue connecting/)
      {
        warn("Host key changed, accepting new key.\n");
        $JUNIPER->send("yes\n");
        # Look for next response
        ($pos, $err, $matched, $before, $after) = $JUNIPER->expect(30,
            'Enter passphrase',
            'password:',
        '> ');
      }
      # Handle prompt for passphrase (for key) or password (host)
      elsif ($matched =~ /pass/)
      {
          print "(More) authentication required:\n");
          print $before. $matched. $after;
          # Get password from STDIN
          ReadMode('noecho');
          my $pass = ReadLine(0);
          ReadMode('normal');
          chomp($pass);
          print "\n";
          $JUNIPER->send($pass,"\n");
      }
      elsif ($matched =~ /% /)
      {
        print "We are apparently logged into the switch as root. Starting CLI.\n";
        print "Note: This is generally NOT recommended.\n";
        $JUNIPER->send("clear ; cli\n");
      }
      else
      {
          $logged_in++;
      }
    } until ($logged_in);
    # Finally at the router prompt, logged in.
    return;
}

=pod

=over

=item

Edit($expect_object)

=over

Requires an Expect object as an argument. Expect Object should be a logged in switch ready
to accept CLI commands. In the correct entry state, at exit, the switch will be in edit
mode. An incorrect entry state will likely produce a die() result.

Does not return a value.

=back

=back

=cut

sub Edit
{
    my $JUNIPER = shift(@_);
    $JUNIPER->send("edit\n");
    my ($pos, $err, $matched, $before, $after) = $JUNIPER->expect(30,
        '# ');
    die("Failed to enter edit mode: $err\n");
    return;
}

=pod

=over

=item

wait_offline([$IP])

=over

Takes an optional IP address or host name ($IP) argument. If specified, pings that IP/Hostname.
If not specified, the package DefaultIP is used ($Loader::DefaultIP). This is the target.

Will ping the (specified|default) target every second until it stops responding. Will
then return.

=back

=back

=cut

sub wait_offline
{
    my $IP = shift @_;
    $IP = $Loader::DefaultIP unless($IP);
    # Wait for the switch to go off line before trying to find next switch.
    $success = 1;
    do {
        my $result = $ping->ping($IP);
        $success=0 if($result);
        sleep 1; # Retry every second until success.
    } while($success);
    return;
}

=pod

=over

=item

catch_pipe($signame)

=over

Minimal signal handler (intended to be package internal) used to prevent
SIGPIPE from causing die() behavior.

=back

=back

=cut

# Minimal signal handler to prevent SIGPIPE from causing die() behavior
sub catch_pipe {
    my $signame = shift;
    print STDERR "Pipe signal caught ($signame) $! $?\n";
}

