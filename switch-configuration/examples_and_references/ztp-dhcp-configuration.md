# KEA DHCP4 Configuration Snippets relevant to Juniper Zero Touch Provisioning with Annotations

## Overview of the Zero Touch Provisioning Process

The easiest way to trigger the zero touch provisioning process on a switch is to reset the switch
to its factory defaults. From the CLI, this can be done with the "request system zeroize" command.

In theory, this should trigger the switch to complete the following steps:

1. Restore the configuration file to factory default.
1. Reboot the switch.
1. Configure the vme.0 and/or irb.0 interfaces via DHCP. (see DHCP notes below)
1. If the appropriate Zero Touch Provisioning parameters are present in the DHCP response,
   begin the Zero Touch Provisioning process:
   1. Download the specified configuration file or script.
   1. Fetch the specified JunOS Installer Image
   1. If necessary, install the new JunOS image and reboot.
   1. At this point, after rebooting, the switch should repeat the zero touch process and
      discover that the installed JunOS matches the image downloaded and continue to
      installing the configuration file or running the configuration script. (We use a script).
      However, some models (notably ex-2300 and ex-4300 series switches so far) seem to
      eliminate the zero touch configuration from the config file during the software upgrade
      and therefore have to be zeroized again after the reboot.
   1. Once the switch boots with a factory config on the specified JunOS version, it will run
      the specified downloaded configuration script to complete the install.
   1. Once the configuration installation succeeds, the installed configuration will no longer
      contain the clause that enables zero touch provisioning and the zero touch process will
      stop, and the switch should have a valid configuration for the show.

## Overview of the DHCP Options used for Zero Touch Provisioning.

### DHCP Generic Options used in Zero Touch Provisioning

- DHCP Option 1 (subnet-mask) (required)
  -- This one is automatically sent based on the subnet configuration.
- DHCP Option 3 (gateway) (required for any off-net communication)
  -- This option is specified in the subnet configuration.
- DHCP Option 6 (domain-name-servers) (required if DNS resolution is desired)
  -- This option contains the IPv4 addresses for resolvers the client should use.
- DHCP Option 7 (log-server) (optional)
  -- This option specifies a SYSLOG style server the client should use for logging.
- DHCP Option 12 (host-name) (optional)
  -- Specifies the clients hostname (if assigned by the server)
- DHCP Option 15 (domain-name) (optional)
  -- This option specifies the domain portion of the FQDN for the client. The host name is prepended with a "." to generate the FQDN.
- DHCP Option 42 (ntp-servers) (optional, may be necessary for ZTP)
  -- Specifies NTP server(s) the client should use for time synchronization. Needed for ZTP if the client clock is far off from reality.
- DHCP Option 43 (vendor-encapsulated-options) (required for ZTP)
  -- This option will contain the encoded Juniper-Specific options specified below.
- DHCP Option 66 (tftp-server-name) (required for ZTP)
  -- This option specifies the IP address of the server from which the client should fetch images and configuration files. Note it must be an
  IP address, not a name for JunOS ZTP.
- DHCP Option 67 (boot-file-name)
  -- For JunOS ZTP, this is actually the name of the configuration file or script and not an actual bootable executable.
- DHCP Option 119 (domain-search) (optional)
  -- This option contains a list of domain suffixes to search when resolving non-fully-qualified names.

### DHCP Vendor-Encapsulated Options for JunOS Zero Touch Provisioning

- We use the namespace "Juniper-ZTP" to indicate Juniper-Specific encoding for Option 43.
- Each suboption is encoded with a specific code within Option 43.
- Juniper-ZTP Code 0 (image-file-name)
  -- The name of the software installation image file for the switch.
- Juniper-ZTP Code 1 (config-file-name)
  -- An alternative to DHCP Option 67. Junos gives precedence to Option 67.
- Juniper-ZTP Code 2 (image-file-type)
  -- Not well documented and not used in our environment. Optional.
- Juniper-ZTP Code 3 (transfer-mode)
  -- Protocol used to transfer configuration and image files. (e.g. HTTP, FTP, TFTP. TFTP is not recommended, we use HTTP)
- Juniper-ZTP code 4 (alt-image-file-name)
  -- Not well documented and not used in our environment. Optional.
- Juniper-ZTP code 5 (http-port)
  -- Port number to use for HTTP transfers. (80)
- Juniper-ZTP code 7 (ftp-timeout)
  -- Timeout for FTP transfers. Not used in our environment. Optional.
- Juniper-ZTP code 8 (proxyv4-info)
  -- HTTP Proxy Information. Not used in our environment. Optional.

### Some notes on Client Classification in KEA

Kea allows very flexible mapping of a client into a class using expressions. Any client can be a member of any number of classes based on matching
the criteria set for the class.

In our case, we use two classes for each switch. The first is a generic Juniper EX-Series class (Juniper-EX-Series) which is determined by
examining the first 10 characters of Option 60 as sent from the client. If they match "Juniper-ex", then the client is a member of the class.

The second is a model-specific classification (e.g. a class for the ex-2300-c series switches ("ex2300-c-series")).

Client classes can specify a variety of configuration parameters specific to the client, but in our case, we use them strictly for setting DHCP
Option strings. In general, the Generic DHCP options which don't vary by model are set in the "Juniper-EX-Series" class and the mode-specific
options are set in the model-specific class (at the moment, strictly the vendor-encapsulated-options and their encoded suboptions).

### Kea Configuration Examples from our current implementation

- Kea DHCP Options that aren't coded into KEA by defaut must be specified with an Option Definition ("option-def" array). We use the following
  option definitions currently:

```
    "option-def": [
        // DHCP4 General Space
        {
            "name":         "vendor-encapsulated-options",
            "code":         43,
            "type":         "empty",
            "encapsulate":  "Juniper-ZTP"
        },
        // Juniper ZTP Custom Space
        {
            "name":         "image-file-name",
            "code":         0,
            "space":        "Juniper-ZTP",
            "type":         "string",
            "record-types": "",
            "array":        false,
            "encapsulate":  ""
        },
        {
            "name":         "config-file-name",
            "code":         1,
            "space":        "Juniper-ZTP",
            "type":         "string",
            "record-types": "",
            "array":        false,
            "encapsulate":  ""
        },
        {
            "name":         "image-file-type",
            "code":         2,
            "space":        "Juniper-ZTP",
            "type":         "string",
            "record-types": "",
            "array":        false,
            "encapsulate":  ""
        },
        {
            "name":         "transfer-mode",
            "code":         3,
            "space":        "Juniper-ZTP",
            "type":         "string",
            "record-types": "",
            "array":        false,
            "encapsulate":  ""
        },
        {
            "name":         "alt-image-file-name",
            "code":         4,
            "space":        "Juniper-ZTP",
            "type":         "string",
            "record-types": "",
            "array":        false,
            "encapsulate":  ""
        },
        {
            "name":         "http-port",
            "code":         5,
            "space":        "Juniper-ZTP",
            "type":         "string",
            "record-types": "",
            "array":        false,
            "encapsulate":  ""
        },
        {
            "name":         "ftp-timeout",
            "code":         7,
            "space":        "Juniper-ZTP",
            "type":         "string",
            "record-types": "",
            "array":        false,
            "encapsulate":  ""
        },
        {
            "name":         "proxyv4-info",
            "code":         8,
            "space":        "Juniper-ZTP",
            "type":         "string",
            "record-types": "",
            "array":        false,
            "encapsulate":  ""
        }
    ],
```

- Once options have been defined, they can be utilized in "option-data" arrays either in the global configuration or
  within a client class or subnet clause.

- We use the following global option-data array:

```
    "option-data": [
        {
            "name": "domain-name-servers",
            "data": "8.8.8.8, 8.8.4.4"
        },
        {
            "code": 15,
            "data": "scale.lan"
        },
        {
            "name": "domain-search",
            "data": "scale.lan"
        },
        {
            "name": "default-ip-ttl",
            "data": "0xf0"
        }
    ],
```

- Here are our current client-class definitions:

```
    "client-classes": [
        {
            "name": "Juniper-EX-Series",
            "test": "substring(option[60].text,0,10) == 'Juniper-ex'",
            "option-data": [
 #               Unfortunately the Juniper-ZTP suboptions must be set in each class
 #               // Juniper ZTP custom options
 #               {
 #                   "name":         "config-file-name",
 #                   "space":        "Juniper-ZTP",
 #                   "data":         "images/switch_initial_loader.sh"
 #               },
 #               {
 #                   "name":         "transfer-mode",
 #                   "space":        "Juniper-ZTP",
 #                   "data":         "http"
 #               },
 #               {
 #                   "name":         "http-port",
 #                   "space":        "Juniper-ZTP",
 #                   "data":         "80"
 #               },
                // General DHCP options
                {
                    "name":         "tftp-server-name",
                    "data":         "192.159.10.49"
                },
                {
                    "name":         "boot-file-name",
                    "data":         "/images/switch_initial_loader.sh"
                },
                {
                    "name":         "log-servers",
                    "data":         "192.159.10.2"
                },
                {
                    "name":         "ntp-servers",
                    "data":         "209.205.228.50"
                }
            ]
        },
        {
            "name": "ex2300-c-series",
            "test": "substring(option[60].text,0,16)  == 'Juniper-ex2300-c'",
            "option-data": [
                 {
                     "name":         "vendor-encapsulated-options"
                 },
                 // Juniper ZTP custom options
                 {
                     "name":         "config-file-name",
                     "space":        "Juniper-ZTP",
                     "data":         "/images/switch_initial_loader.sh"
                 },
                 {
                     "name":         "transfer-mode",
                     "space":        "Juniper-ZTP",
                     "data":         "http"
                 },
                 {
                     "name":         "http-port",
                     "space":        "Juniper-ZTP",
                     "data":         "80"
                },
                {
                    "name":         "image-file-name",
                    "space":        "Juniper-ZTP",
                    "data":         "/images/junos-arm-32-25.2R1.9.tgz"
                }
            ]
        },
        {
            "name": "ex4200-series",
            "test": "substring(option[60].text,0,14) == 'Juniper-ex4200'",
            "option-data": [
                 {
                     "name":         "vendor-encapsulated-options"
                 },
                 // Juniper ZTP custom options
                 {
                     "name":         "config-file-name",
                     "space":        "Juniper-ZTP",
                     "data":         "/images/switch_initial_loader.sh"
                 },
                 {
                     "name":         "transfer-mode",
                     "space":        "Juniper-ZTP",
                     "data":         "http"
                 },
                 {
                     "name":         "http-port",
                     "space":        "Juniper-ZTP",
                     "data":         "80"
                },
                {
                    "name":         "image-file-name",
                    "space":        "Juniper-ZTP",
                    "data":         "/images/jinstall-ex-4200-15.1R7.9-domestic-signed.tar.gz"
                }
            ]
        },
        {
            "name": "ex4300-series",
            "test": "substring(option[60].text,0,14) == 'Juniper-ex4300'",
            "option-data": [
                 {
                     "name":         "vendor-encapsulated-options"
                 },
                 // Juniper ZTP custom options
                 {
                     "name":         "config-file-name",
                     "space":        "Juniper-ZTP",
                     "data":         "/images/switch_initial_loader.sh"
                 },
                 {
                     "name":         "transfer-mode",
                     "space":        "Juniper-ZTP",
                     "data":         "http"
                 },
                 {
                     "name":         "http-port",
                     "space":        "Juniper-ZTP",
                     "data":         "80"
                },
                {
                    "name":         "image-file-name",
                    "space":        "Juniper-ZTP",
                    "data":         "/images/jinstall-ex-4300-21.4R3.15-signed.tgz"
                }
            ]
        }
    ],
```

- Once a client-class is defined, it can be applied to a subnet using a "require-client-classes" statement. Here is an example
  clause from one of our test environments:

```
    "subnet4": [
        {
            "id": 1,
            "subnet": "192.168.101.0/24",
            "match-client-id": false,
            "require-client-classes": [
               "Juniper-EX-Series",
               "ex2300-c-series",
               "ex4200-series",
               "ex4300-series"
            ],
            "pools": [ { "pool": "192.168.101.100 - 192.168.101.254" } ],
            "option-data": [
                {
                    "name": "routers",
                    "data": "192.168.101.1"
                }
            ]
        },
```
