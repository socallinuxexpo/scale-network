# Switch Management

configurations, tooling and scripts for the Juniper Switches and Routers running the SCALE network backbone

# Prereqs

THese instructions are obsolete and there are now additional requirements. Please check in the PODs for the
PERL scripts in the config/scripts/ directory and in the config/scripts/README.md file.

Preserved for posterity and no longer particularly relevant.

PERL 5
Ubuntu instructions

```
apt-get install libexpect-perl
apt-get install net-sftp
apt-get install libnet-arp-perl
apt-get install libnet-interface-perl
```

Some scripts have additional dependencies... The POD for each script is the most current information.
There's also documentation of the scripts in config/scripts/README.md that should be reviewed.
There are also extensive comments in most of the scripts in that directory. When in doubt, use the source, Luke.

# Firmware

The latest version of the firmware can be downloaded from `dhcp-01.delong.com`

## Models

### EX4200

We are running the following versions of `junos` and its `bootloader`:

- [jloader 12.1R3](http://dhcp-01.delong.com/images/jloader-ex-3242-12.1R3-signed.tgz)
- [jinstall 15.1R7.9](http://dhcp-01.delong.com/images/jinstall-ex-4200-15.1R7.9-domestic-signed.tgz)

### SRX300

We are running the following versions of `junos` on the router:

- [junos 24.2R1.17](http://dhcp-01.delong.com/images/junos-srxsme-15.1X49-D120.3-domestic.tgz)

## Validate

Current `SHA256` for the juniper firmware:

```
e30b55fa1832be8a1227d0a55a1b2654b42e162ea6182253922793f2243d52a9  jloader-ex-3242-12.1R3-signed.tar.gz
b23864284709b3b9e485628e43f9078075978b341412a79a682857660fb98419  jinstall-ex-4200-15.1R6.7-domestic-signed.tgz
d3cb75afd0bdd260155337027b74c8218fb700a51da6682e49af8b61ec10ec27  jinstall-ex-4200-15.1R7.9-domestic-signed.tar.gz
ed6c23a35cd71412cb73c4b7a826db2d8e4c21e7c93c7736dadc6b1b891c98a5  junos-srxsme-24.2R1.17.tgz
```

### Verification

Grab the `SHA256` to check the image validity:

```
cd <toimagedir>
curl -O http://dhcp-01.delong.com/images/SHA256SUMS
shasum -c SHA256SUMS
```

Expected output:

```
% curl -O http://dhcp-01.delong.com/images/SHA256SUMS
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   423  100   423    0     0  27963      0 --:--:-- --:--:-- --:--:-- 38454
% shasum -c SHA256SUMS
jloader-ex-3242-12.1R3-signed.tar.gz: OK
jinstall-ex-4200-15.1R6.7-domestic-signed.tgz: OK
jinstall-ex-4200-15.1R7.9-domestic-signed.tar.gz: OK
junos-srxsme-24.2R1.17.tgz: OK
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

Note, the actual root password hash has been removed from the repo and lives within the secrets directory.
The one here is a standin that doesn't really work. Check with a senior team member if you need a copy of
the secrets directory.

## config/switchtypes

This file defines the name and type of each switch. It is a  tab delimeted file (tab8
formatting preferred) containing many fields, including the following:

```
	Name	The name of the switch (e.g. conf214a)
	Number	Unique number identifying the switch and its location on the storage cart
		MgtVLAN Management VLAN Number for switch
	IPv6	IPv6 Address for Switch on Management VLAN
	Type	Type of switch (must match a file in config/types/, e.g. Room for a Room switch)
```

See the file itself for the most up to date documentation on these fields.

## config/vlans

## config/vlans.d/<name>

The config/vlans file is the master VLAN configuration file. It may include other files where it
makes sense to subdivide the configuration (e.g. Conference, Expo, etc.). If so, these files should
be stored in the config/vlans.d directory.

Our current structure is to have config/vlans only be a list of files in vlans.d to include in the current configuration.
This allows us to more easily switch venues should that become necessary again.

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

Related to this, there is a special vlan vendor_backbone (499) which is the gateway network all of the vendor VLANs are
routed to on each switch and which is shared amongst the expo switches.

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
TRUNK	<port> <vlan_name>[,<vlan_name>...] <trunktype>
JUNOS	<junos_version>
FIBER   <port> <vlan_name>[,<vlan_name>...] <trunktype>
```

## config/routers/{backups,to_push}/<name>
These directories contain backups of the routers (backups) and staged configurations to be pushed onto the
routers (to_push).

It has been decided not to pursue templated generated configurations for routers because the small number of
routers and the effort to implement such do not make sense. The routers currently use "bespoke" configurations
that are generated/modified by hand.

Any time a configuration is changed on a router, it should be backed up to the routers/backups directory.

The to_push directory should always contain the most current desired configuration in the event a router needs to be
restored.

## Source for Vendor Booth Information:

This link may be out of date and may need updating year to year.

https://docs.google.com/spreadsheets/d/1qbmQh8zbcDD9fi1pmDi-NaYuZ6Y-WcicX4fwMsuYxmU/edit?ts=5a80d55a#gid=1023875758

# Scripts (No User Serviceable Parts inside)

scripts/

However, there is documentation of the scripts in scripts/README.md which should be reviewed.
Also, the comments and POD in the scripts may prove relevant to users of the scripts.

# Standard Operational Procedures

## How to build a set of switch configurations

The procedure below is replaced with a Makefile now. The rest is preserved for historical
purposes and troubleshooting in case of an issue with the make process.

You should be able to go into the switch-configuration directory and simply type 'make'.
This should generate all of the PDFs, Sticker EPS files, Configuraiton, and Map files
needed. 

Once the configuration files are all set up (as described above) and you
have set up authentication parameters as described below, simply run

```
scripts/build_switch_configs.pl
```

The resulting configuration files will be written to the output/switch_confugrations directory.

If you want to rebuild the configuration file for a single switch or a subset
of switches, specify their names as arguments on the command line

```
scripts/build_switch_configs.pl <switch1>[ <switch2>...]
```

Note: The above command will only perform the first step in the postscript generation for sticker and PDF files.
Instructions for the rest of the process are in the Makefile. 

It should also be noted that the Makefile takes care of some prerequisites and validation steps to inform of some
missing dependencies and other issues as well as some other housekeeping. If at all possible, use the Makefile. Doing
this by hand is just unnecessarily painful and not very reliable.

## Loading configurations onto switches

All config loading is now accomplished using the switch_config_loader script. See scripts/README.md for
its documentation.

This should be run from the switch_configration/config directory as scripts/switch_config_loader.

Some quick examples:
Load miniconfig via the serial port (this is the first step for a new switch or one whose config has been reset (amnesiac)):
```
	scripts/switch_config_loader -c miniconfig -t /dev/<serial_port>
```

Load the switch with the appropriate configuration based on its me0 MAC address in switchtypes:
```
	scripts/switch_config_loader -l
```

Load configs on to a bunch of switches (sequentially), monitoring for the ethernet to disconnect and reconnect to
tell when the next switch is ready to be flashed:
```
	scripts/switch_config_loader -b
```

Push updated configurations to all switches live at the show:
```
	scripts/switch_config_loader
```

Push updated configurations to a subset of switches by name (live at the show):
```
	scripts/switch_config_loader <switch_spec>
```
(Where <switch_spec> is any combination of switch names, group names, etc.)


## How to set up a switch initially

##FIXME## This section needs updating and some rework

1. Restore switch to factory defaults

   ```
   https://www.juniper.net/documentation/en_US/release-independent/junos/topics/task/configuration/ex-series-switch-default-factory-configuration-reverting.html#jd0e60
   ```

1. Connect the computer where these scripts are being run to the switch console (serial)

1. Determine the serial port device name on your computer. The examples in this
   section will use __/dev/ttyS6__ as the serial port.

1. Connect switch management ethernet (next to console port)  directly to the computer running
   these scripts.

1. Configure the computer's ethernet port to an address other than 192.168.255.76 on the 192.168.255.0/24
   network. The switch will have address 192.168.255.76 once miniconfig is loaded via serial.

1. Make sure you have an ssh private key (preferably installed in a running agent session)
   that corresponds to an ssh public key that is included in miniconfig
   available for use during this process.

1. Make sure that the switch configuration file is built and correct in the
   output/switch_configurations directory.

1. Run the following command:

   ```
   scripts/switch_config_loader -c miniconfig -t /dev/<serial_port>
   ```

   This will default to logging into the switch as root. If you want to use a different username,
   you can add:
   ```
   ... -u <username>
   ```
   to the command line above. It may also be useful to add the '-p' flag to cause the script to prompt
   for the password to use for authentication.

   It is possible that in the future, miniconfig will be made available via a zero-touch provisioning
   capability which will allow the switch to be factory-initialized and then retrieve miniconfig
   automatically. This will require additional infrastructure.

1. The script will display information about each step as it proceeds. It will perform the
   following steps:

   1. It will validate that it can talk to the CLI of the switch via the serial port.
   1. It will attempt to authenticate onto the switch
   1. It will replace the existing configuration on the switch with the contents of miniconfig

1. When the script exits, review the messages for any errors or problems encountered. If unsuccessful, either
   try again or troubleshoot the problem and correct it manually or correct the problem and retry with the script.

1. Once miniconfig is bootstrapped onto the switch, it can be accessed with SSH and public key authentication
   over the management interface. Use this to upgrade or reinstall the software and/or boot loader onto the switch.

1. Once the correct version of the software is installed, load the switches proper configuration using the following
   command:

   ```
   scripts/switch_config_loader -l
   ```

   Alternatively, if there are several switches with miniconfig or an older show configuration loaded on them
   which need updated configurations via this method, you can use the following command:

   ```
   scripts/switch_config_loader -b
   ```

   In the first case (-l), the script will exit when finished and you should log into the switch and prepare
   it for shutdown using the following switch cli command:
   ```
   request system power-off
   ```

   In the second case (-b), the script will send the power-off command to the switch upon successful completion
   and you should watch for the "SYS" light (middle LED in the group of 3 to the right of the LCD display) to turn
   off, indicating that the switch has halted and is ready for power-off. Once this is done, you can move the
   ethernet cable to the management port of the next switch to be loaded and the script will soon install the
   configuration onto that switch. When all switches are complete, simply use Ctrl-C to exit the script.

   The bulk load (-b) flag thus allows several switches to be powered up and waiting for configuration such that
   all of the switches can be rapidly loaded with their configurations.

## To get the configuration for a switch:

1. ```
    If you haven't already, get a full copy of the repository and build the configuration files.
    A.      Clone the repository
    B.      Get a current copy of the secrets directory from someone.
    C.      Change to the "switch_configuration/config" directory.
    D.      Run "scripts/build_switch_configs.pl"
   ```
1. ```
    Check the number on the labels on the switch and find the
    corresponding line in the config/switchtypes file.
    e.g. for switch 27, the line shows switch name CTF3 (at the
    time of writing).
   ```
1. ```
    The config file will be in the config/output/ directory and
    will be named <name>.conf. So for switch 27 in our above example,
    it would be "config/output/CTF3.conf".
   ```

## To replace the configuration on one of last years switches:
   These instructions are now obsolete... Use switch_config_loader instead.

   They are preserved here in case the switch_config_loader can't be made operable
   and desperate measures are required.

1. ```
    Connect to switch via serial console.
   ```
1. ```
    Log into switch as root.
   ```
1. ```
    Start the cli.
   ```
1. ```
    type "edit"
   ```
1. ```
    Type "load override terminal"  
    to enter a mode where you can paste in the new configuration file.
   ```
1. ```
    Bring up the configuration file from the switch in another window
    and paste about 1 screenful at a time into the switch.
    Be watchful for any error reports. If you encounter an error,
    start back at the previous step (Hit CTRL-D to abort the load if  you didn't
    already, then type rollback 1, then try again from the previous step). If the error
    is persistent, ask for help.
   ```
1. ```
    When done pasting, hit Ctrl-D to exit load mode.
   ```
1. ```
    Type "show | compare".
    A.    Expected output is a diff from last years config. The important
          thing is to make sure the diff looks reasonably sane.
   ```
1. ```
    Type "commit and-quit"
    If the configuration fails to commit, ask for assistance.
   ```
1. ```
   Type "quit"
   You're done with this switch.
   ```

# Important additional data

## Switch Authentication

All on-site switches and routers will use Public Key SSH authentication.

If you are a member of the tech team and believe you should be able to access the switches, please
contact Owen DeLong, David Lang, or Robert Hernandez and provide your SSH public key (do NOT send
private keys) to us along with a phone number where we can verify your key fingerprint.

Public keys are stored in the authentication/keys directory and ARE PUBLIC.

Keys must be at least 2048 bits. ED25519 is preferred, ECDSA and RSA keys are also acceptable
in that order of preference

Public keys will also become visible in all switch and router configurations.

Since these are public keys, publication should not be a security risk. Should it become a security risk,
SCALE will likely be the least of your worries, but we will make every effort to remove visibility to
keys in the repository upon finding out that this is an issue.

If your key becomes compromised, please notify us immediately. We recommend using a different key for SCaLE from
your other activities to minimize the probability of cross-contagion from key compromise.

We reserve the right to remove any key at any time in the event we suspect a key has been compromised.

