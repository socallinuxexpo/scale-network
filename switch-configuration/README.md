# Switch Management
configurations, tooling and scripts for the Juniper Switches and Routers running the SCALE network backbone

# Prereqs
PERL 5

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
JUNOS	<junos_version>				Default JunOS version
```
## config/switchtypes
This file defines the name and type of each switch. It is a  tab delimeted file (tab8
formatting preferred) containing the following fields:
```
	Name	The name of the switch (e.g. conf214a)
	Number	Unique number identifying the switch and its location on the storage cart
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

<vlan_name> <vlan_number> <prefix6> <prefix4> <comment>
						Defines a VLAN.

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
VLAN	<vlan_name> <number_of_ports> [<ip6_address> [<ip4_address>]]
TRUNK	<port> <vlan_name>[,<vlan_name>...]
JUNOS	<junos_version>
```


# Scripts (No User Serviceable Parts inside)
scripts/

# Standard Operational Procedures
## How to build a set of switch configurations
Once the configuration files are all set up (as described above) and you have set up
authentication parameters as described below, simply run
```
scripts/buildswitches
```

The resulting configuration files will be written to the output/switch_confugrations directory.

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

