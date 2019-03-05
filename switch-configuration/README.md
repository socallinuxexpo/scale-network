# Switch Management
configurations, tooling and scripts for the Juniper Switches and Routers running the SCALE network backbone

# Prereqs
PERL 5

# Firmware
The latest version of the firmware can be downloaded from `s3`

## Models
### EX4200
We are running the following versions of `junos` and its `bootloader`:
  * [jloader 12.1R3](http://sarcasticadmin.com/scale/junos/jloader-ex-3242-12.1R3-signed.tgz)
  * [jinstall 15.1R6.7](http://sarcasticadmin.com/scale/junos/jinstall-ex-4200-15.1R6.7-domestic-signed.tgz)

### SRX300
We are running the following versions of `junos` on the router:
  * [junos 15.1X49-D120.3](http://sarcasticadmin.com/scale/junos/junos-srxsme-15.1X49-D120.3-domestic.tgz)

## Validate
Current `SHA256` for the juniper firmware:
```
bddc7d8a0571e3ed7a7379366b55595664300fbd564cf157be20ff4781ef6add  jinstall-ex-4200-15.1R6.7-domestic-signed.tgz
44e1fa5d7b1a09eef4772189cb2c0c0d6e8c0492f655bc5e840bbe0056e2a361  jloader-ex-3242-12.1R3-signed.tgz
9e21098d685eb5a4034645ce5a457c13384003accaa7e0e1e92dd637b6c3021f  junos-srxsme-15.1X49-D120.3-domestic.tgz
```
### Remote
Grab the `SHA256` to check the image validity:
```
cd <toimagedir>
curl -O http://sarcasticadmin.com/scale/junos/SHA256SUMS
shasum -c SHA256SUMS
```

# Configuration Files (User Servicable)
All files have the following features unless expressly stated otherwise:

```
+	All text after // is treated as a comment and ignored by the parser.
+	Any line ending in a space followed by a backslash (matches /\s\\$/)
	will result in the next line being treated as a continuation of the
	existing line. Whitespace at the end of this line and the beginning of the
	next line will be collapsed to a single space by the parser during joining.
	The parser will then parse the entire line as normal, including this treatment
	if the resulting line still ends in a space followed by a backslash.

	e.g.:
		foo \
		bar

	is parsed as 'foo bar'

		this \
		line \
		is \
		continued

	is parsed as 'this line is continued'
+	Parser will ignore one whitespace after a comma so that comma separated lists
	will work equally well with either "foo, bar, blah" or "foo,bar,blah" syntax
	and also so that ", \" continuation constructs won't create arbitrary whitespace
	problems.
```
## config/defaults
This file sets various defaults. All scripts will parse this file first before parsing any others.
Any configuration directive not applicable to the parsing script is ignored silently.
```
SW_JUNOS	<junos_version>				Default JunOS version for switches
RT_JUNOS	<junos_version>				Default JunOS version for routers
rootpw		<encrypted password string>		Root Authentication Password
```
## config/switchtypes
This file defines the name and type of each switch. It is a  tab delimeted file (tab8
formatting preferred) containing the following fields:
```
	Name	The name of the switch (e.g. conf214a)
	Number	Unique number identifying the switch and its location on the storage cart
		MgtVLAN Management VLAN Number for switch
	IPv6	IPv6 Address for Switch on Management VLAN
	Type	Type of switch (must match a file in config/types/, e.g. Room for a Room switch)
```

## config/vlans
## config/vlans.d/<name>
The config/vlans file is the master VLAN configuration file. It may include other files where it
makes sense to subdivide the configuration (e.g. Conference, Expo, etc.). If so, these files should
be stored in the config/vlans.d directory.

The syntax of a config/vlans file (either master or within an included file) is as fillows:
```
#include <filename>				Include <filename> from vlans.d a la macro substitution

VLAN <vlan_name> <vlan_number> <prefix6> <prefix4> <comment>
						Defines a Normal VLAN.

VVRNG 	<template>		<vlan_range>	<prefix6>	<prefix4>	<comment>
						Defines a range of Booth (Vendor) VLANs.

Note: Only one VVRNG statement is allowed globally, even across all included files. The behavior of multiple
VVRNG definitions is undefined.

<template> is the prefix for naming the vlans. These will be dynamically assigned from the booth
list file.

<vlan_range> is a hyphen separated range defining the lowest and highest VLAN ID numbers that can be allocated.

<prefix6> is a shorter than /64 prefix from which /64s will be delegated. It must contain at least as many /64s
as there are numbers between the low and high specfication in <vlan_range> in BCD notation. That is, if you
have a range from 200-399 for VLAN ids, then there should be a /55 or shorter IPv6 prefix. Ideally, the numbers
also line up (e.g. 200-399 VLAN IDs should map to 2001:db8:abcd:0200::/55 which would yield IPv6 networks for
the VLANs of 2001:db8:abcd:200::/64 through 2001:db8:abcd:399::/64.)

<prefix4> is a shorter than /24 prefix from which /24s will be delegated. It must contain at least as many /24s
as there are numbers between the low and high specification in <vlan_range>. Since IPv4 numbers cannot possibly
represent the full range of VLAN IDs in any human readable form, no attempt is made at matching the numbers.
In our example above of VLAN IDs in the range 200-399, a /16 is perfect (e.g. 10.1.0.0/16 would map to 10.1.0.0/24
through 10.1.199.0/24).

[<directive>] // <text>				Any text after a double slash is considered a comment
						to the end of line.  It is ignored by the parser.
```
prefix6 and prefix4 are only needed for LANs that will have in-addr, ip6.arpa, DHCP,
or RADVD managed by the SCALE Tech team.

For other VLANs, they should be set to ::/0 and 0.0.0.0/0, respectively, which will
flag the parser not to create any L3 interfaces or IP related configuration for these
networks.

## config/types/<name>
These files contain the configuration information for each type of switch. They are  tab
delimited (tab8 formatting preferred).

Configuration elements include:
```
RSRVD	<number_of_ports>
VLAN	<vlan_name> <number_of_ports>
VVLAN	<number_of_ports>
TRUNK	<port> <vlan_name>[,<vlan_name>...]
JUNOS	<junos_version>
FIBER   <port> <vlan_name>[,<vlan_name>...]
```

## config/routers/<name>
These files describe the base configuration for a router. The information in
these files is combined with certain assumptions and other data in the other
configuration files to produce a router configuration. This is a work in
progress, as is the script that processes this file. As such, this description
section may lag development slightly. It is unlikely that the script will be
ready to produce full working configurations for the routers by showtime this
year, so focus for now is on biggest bang for the buck. Effort will be focused
in the following priority order.

1.  Basic router template (system parameters, authentication, etc.)
2.  L3 VLAN interface configuration
3.  Bridging configuration for interfaces
4.  Firewall rule configuartion
5.  Other items (TBD)

The basic router template will be built into the code, but will also pull
data from configuration files. This will include building user authentication
based on data in the authentication/keys directory, etc.

The script doing this will be similar to the buildswitches script and
will use the same library (template.pl) to read configuration files.

Each file describes one router and shares the same name as the router for which
the configuraiton is being produced. (E.g. ExMDF will produce the ExMDF router
configuration)

### L3 VLAN configuration Directives

interface   <VL_Name>
or
interfaces  <VL_regexp>
    This directive specifies one (interface) or more (interfaces) VLANs
    to have L3 interfaces on the router in question.

### Bridging Interface Configuration Directives
l2if    <if_name> <mode> <VL_Name>[,<VL_NAME>[...]]
    This directive specifies a physical interface to be a Layer 2 bridging
    interface (family ethernet-switching).

    If no unit is specified in if_name (e.g. ge-0/0/0 instead of ge-0/0/0.4),
    then one of two things will be done, depending on <mode>.

    If <mode> is access, then unit 0 will be used and only a single VL_Name
    parameter is valid. THe first one will be used and any extras will be
    ignored with a warning.

    If <mode> is trunk, then the VL_ID of each specified VLAN name will be
    used as the unit number tagged for that VLAN.

    All trunks will be configured as standard 802.1q.

### Firewall rule configuration

firewall    <VL_Source> <VL_Dest> <Traffic_Class> <Action>
    Specifies a firewall rule to be built.
    VL_Source and VL_Dest can either be literal VLAN names or they can be
    One of the following special VLAN categories:
        ALL     Matches IPv4 0.0.0.0/0 and/or IPv6 ::/0
        INET    Matches non-local addresses (Non-RFC1918 for IPv4,
                outside the show /48 for IPv6)
        LOCAL   Matches local addresses (IPv4 RFC-1918, IPv6 show /48)
        Expo    Matches addresses assigned to Expo Hall
        Conf    Matches addresses assigned to Conference Building

## config/routers/traffic_classes/\*
These files describe traffic classes for firewalls. They are essentially
additional expressions to be placed in a from clase (along with the ones
that cause the Source and Destination to be matched)

e.g. a file named "ICMP" might contain:
```
protocol [ icmp icmp6 ];


## config/routers/actions/\*
These files describe terminating (or non-terminating) actions to take when
a firewall rule is matched. These files contain statements which are
incorporated literally and wholesale into a "then" clause in the firewall
rule produced. The syntax, therefore is identical to a Juniper then clause
in C-Style configuration notation (not in display-set notation).

e.g. a file named "permit_and_log" might contain:
```
permit;
log;
```

## Source for Vendor Booth Information:
https://docs.google.com/spreadsheets/d/1qbmQh8zbcDD9fi1pmDi-NaYuZ6Y-WcicX4fwMsuYxmU/edit?ts=5a80d55a#gid=1023875758

# Scripts (No User Serviceable Parts inside)
scripts/

# Standard Operational Procedures
## How to build a set of switch configurations
Once the configuration files are all set up (as described above) and you
have set up authentication parameters as described below, simply run
```
scripts/buildswitches
```

The resulting configuration files will be written to the output/switch_confugrations directory.

If you want to rebuild the configuration file for a single switch or a subset
of switches, specify their names as arguments on the command line
```
scripts/buildswitches <switch1>[ <switch2>...]
```

## How to mass-update a set of (running) switches
After completing the configuration build (as described in the previous section) review the
generated configuration files and make sure they match expectations. Once you are confident
in the output, simply run
```
scripts/update_switches
```

This will compare the proposed config to the configuration currently on the switch in production
and apply the necessary changes.

## How to build and push a new configuration to a single switch
As in the above section for updating all switches, run the same command, but with the name of
the switch(es) you wish to update as argument(s):
```
scripts/update_switches BallroomG Room126
```

## How to set up a switch initially
1.	Restore switch to factory defaults
    ```
    https://www.juniper.net/documentation/en_US/release-independent/junos/topics/task/configuration/ex-series-switch-default-factory-configuration-reverting.html#jd0e60
    ```
2.	Connect the computer where these scripts are being run to the switch console (serial)
3.	Determine the serial port device name on your computer. The examples in this
	section will use __/dev/ttyS6__ as the serial port.
4.	Connect switch port ge-0/0/0 (top left port) to the network (or to the computer running
	these scripts).
5.	Determine a valid network address the switch can use during this process (this address
	will not remain on the switch after the process is completed)
6.	Make sure that the address in the previous step is one the computer running the script
	can reach.
7.	If the computer is not on the same network as the switch, determine the default gateway
	address needed by the switch to reach the computer.
8.	Make sure you have an ssh private key (preferably installed in a running agent session)
	that corresponds to an ssh public key that is configured for switch authentication
	available for use during this process.
9.	Make sure that the switch configuration file is built and correct in
	output/switch_configurations.
10.	Run the following command:
    ```
    scripts/initialize_switch /dev/ttyS6 <switch_number> <switch_IP_address> [<default_gateway>]
    ```
11.	The script will display information about each step as it proceeds. It will perform the
	following steps:

	1.	It will validate that it can talk to the CLI of the switch via the serial port.
	2.	It will configure the switch with an IP address on VLAN 1.
	3.	It will install the default gateway (if needed).
	4.	It will check the version of JunOS on the switch and compare it to the configured
		version for the specified switch.
	5.	It configure the switch to support administration via SSH using the specified SSH
		public keys.
	6.	It will (if necessary) stage the configured version of JunOS onto the switch for
		installation via SCP.
	7.	It will (if necessary) perform the software upgrade on the switch and reboot the
		switch.
	8.	After rebooting the switch, it will load the generated configuration file
		onto the switch.
	9.	It will shutdown the switch.

12.	Once the switch powers down, you will know that the process is completed and the switch
	should be ready for installation.

## To get the configuration for a switch:
1.  Check the number on the labels on the switch and find the
    corresponding line in the config/switchtypes file.
    e.g. for switch 27, the line shows switch name CTF3 (at the
    time of writing).
2.  The config file will be in the config/output/ directory and
    will be named <name>.conf. So for switch 27 in our above example,
    it would be "config/output/CTF3.conf".
## To replace the configuration on one of last years switches:
1.  Connect to switch via serial console.
2.  Log into switch as root.
3.  Start the cli.
4.  Type "edit" to enter edit mode and perform the following steps:
    A.  delete system
    B.  delete chassis
    C.  delete interfaces
    D.  delete snmp
    E.  delete routing-options
    F.  delete protocols
    G.  delete ethernet-switching-options
    H.  delete vlans
    I.  delete poe
5.  You now have an empty configuraton. Type "load merge terminal"  
    to enter a mode where you can paste in the new configuration file.
6.  Bring up the configuration file from the switch in another window
    and paste about 1 screenful at a time into the switch.
    Be watchful for any error reports. If you encounter an error,
    start back at step 4.A. and repeat the process. If the error
    is persistent, ask for help.
7.  When done pasting, hit Ctrl-D to exit load mode.
8.  Type "show | cmopare".
    A.  Expected output is a diff from last years config. The important
        thing is to make sure the diff looks reasonably sane.
9.  Type "commit and-quit"
    If the configuration fails to commit, ask for assistance.
10. Type "quit"
    You're done with this switch.
# Important additional data

## Switch Authentication
All on-site switches and routers will use Public Key SSH authentication.

If you are a member of the tech team and believe you should be able to access the switches, please
contact Owen DeLong, David Lang, or Robert Hernandez and provide your SSH public key (do NOT send
private keys) to us along with a phone number where we can verify your key fingerprint.

Public keys are stored in the authentication/keys directory and ARE PUBLIC.

Keys must be at least 2048 bits.

Public keys will also become visible in all switch and router configurations.

Since these are public keys, publication should not be a security risk. Should it become a security risk,
SCALE will likely be the least of your worries, but we will make every effort to remove visibility to
keys in the repository upon finding out that this is an issue.

