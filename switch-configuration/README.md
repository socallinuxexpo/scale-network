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
VLAN <vlan_name> <vlan_number> <comment>	Defines a VLAN.
[<directive>] // <text>				Any text after a double slash is considered a comment
						to the end of line.  It is ignored by the parser.
```

## config/types/<name>
These files contain the configuration information for each type of switch. They are  tab
delimited (tab8 formatting preferred).

Configuration elements include:
```
RSRVD	<number_of_ports>
VLAN	<vlan_name> <number_of_ports> [<ip6_address> [<ip4_address>]]
TRUNK	<port> <vlan_name>[,<vlan_name>...]
JUNOS	<junos_version>



# Scripts (No User Serviceable Parts inside)

# How to build a set of switch configurations

# How to mass-update a set of switches

# How to build and push a new configuration to a single switch

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

