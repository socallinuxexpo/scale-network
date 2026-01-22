# Switch Configuration Scripts

Part of [SCaLE's](https://www.socallinuxexpo.org/) on-site expo network configurations, tooling and scripts

## Zero Touch Provisioning Process
- Introduction
  -- Zero Touch Provisioning is a process by which a switch with no configuration on it at all can be brought to a known, configured state with a pre-defined software version installed on the switch simply by booting the switch with the management interface connected to an access port on a network that is configured to support Zero Touch Provisioning.
  -- Prerequisites
    --- DHCP Server with an appropriate configuration (see "Kea Template" below)
    --- Web Server with appropriate JunOS Software images and configuration files or scripts. In our case, we use a multistage process where we first send a helper script (sh) to the device which invokes curl to query a CGI script on the same web server with the MAC address from the switch's management interface (vme) and download and install the actual configuration file. Both the helper script and the CGI script are maintained in this directory, though the helper script needs to be made part of the images directory on the web server and the CGI script has to be placed in the web-server's CGI executable directory.
  -- User Process
    1. Connect switch management ethernet interface to appropriate network as described above.
    1. Connect to the Console port via appropriate serial cable
    1. If necessary, gain access to the switch and use the "request system zeroize" command to reset the switch to factory defaults. Alternatively, if command line access is impossible, reset the switch through other (hardware, password recovery, etc.) means. Such processes are out of scope for this document.
    1. Monitor the console as the switch goes through the ZTP process. It should execute the following steps:
      --- Boot up into an unconfigured state.
      --- If necessary, download and install the specified firmware and reboot.
      --- Download the configuration file (script) specified in the DHCP parameters.
      --- If script, execute the script.
        ---- In our case, the script is the above specified helper script which will then execute the CGI call to retrieve the switch-specific configuration file and install it.
    1. Once the configuration file is installed, the switch is ready for deployment.

## KEA Templates (for ZTP)
- The following configuration snippets should be added to the KEA DHCP4 configuration in order to support ZTP:
```
# The stanzas below go inside of the "Dhcp4" section
    # Define all needed DHCP options that are not already built into KEA
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
    # Define client classes and the DHCP information that should be sent to each class
    # Clients can be a member of more than one class and will receive the superset of
    # options specified. Collisions in option data should be avoided.
    "client-classes": [
        {
            # This class supports options applicable to ALL models of Juniper ex series switch.
            # By using the Juniper-ZTP namespace, we tie these options to the above definitions
            # so that they get properly encoded in the Vendor Specific Options.
            "name": "Juniper-EX-Series",
            "test": "substring(option[60].text,0,10) == 'Juniper-ex'",
            "option-data": [
                // Juniper ZTP custom options
                {
                    "name":         "config-file-name",
                    "space":        "Juniper-ZTP",
                    "data":         "config/autoconf.sh"
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
                // General DHCP options
                {
                    "name":         "tftp-server-name",
                    "data":         "scale-ztp.delong.com"
                },
                {
                    "name":         "log-servers",
                    "data":         "192.159.10.2"
                },
                {
                    "name":         "ntp-servers",
                    "data":         "209.205.228.50"
                },
                {
                    "name":         "vendor-encapsulated-options"
                }
            ]
        },
	# Options specific only to the ex2300-c-series switches (not the ex-4200 or ex-4300, for example)
        # Note use of the same Juniper-ZTP namespace, but unique sub-option(s).
        {
            "name": "ex2300-c-series",
            "test": "substring(option[60].text,0,16)  == 'Juniper-ex2300-c'",
            "option-data": [
                {
                    "name":         "image-file-name",
                    "space":        "Juniper-ZTP",
                    "data":         "images/junos-arm-32-25R1.9.tgz"
                }
            ]
        },
	# Options specific only to the ex-4200-series switches (not the ex2300-c or ex-4300, for example)
        # Note use of the same Juniper-ZTP namespace, but unique sub-option(s).
        {
            "name": "ex4200-series",
            "test": "substring(option[60].text,0,14) == 'Juniper-ex4200'",
            "option-data": [
                {
                    "name":         "image-file-name",
                    "space":        "Juniper-ZTP",
                    "data":         "images/jinstall-ex-4200-15.1R7.9-domestic-signed.tar.gz"
                }
            ]
        },
        # Options specific to the ex-4300 series switches
        {
            "name": "ex4300-series",
            "test": "substring(option[60].text,0,14) == 'Juniper-ex4300'",
            "option-data": [
                {
                    "name":         "image-file-name",
                    "space":        "Juniper-ZTP",
                    "data":         "images/jinstall-ex-4300-21.4R3.15-signed.tgz"
                }
            ]
        }
    ]
```
## Scripts

- Introduction
  -- This directory contains any scripts related to the switch configuration process. This includes scripts and libraries for building the configurations, scripts for buiding the documentary port maps which are used to produce stickers for the tops of the switches as well as reference documents for the cable team, scripts for managing (loading) the various configs on to the switches through various means, and finally scripts related to the "Zero Touch Provisioning" process which we are hoping to adopt in the near future.

- Needed updates:
  -- Add documentation for ../../Makefile
  -- Add documentation for switch_config_loader
  -- Add documentation for Loader.pm
  -- Review documentation of other scripts and update as needed

- ../../Makefile
  -- There is a Makefile which will do all that is needed to generate all of the switch configuration files and the postscript and PDF map files. Its primary documentation lives in ../../README.md

- build_switch_configs.pl
  -- This is the first script to run in the manual process. Use Make instead, you will be happier. It will create the output directory if it doesn't exist. It will clean it out if it does. Then it will generate all of the switch configuration files. It will also produce the EPS files that can be combined/printed to produce human-readable port references for the tops of the switches. If you give it any arguments, it will treat those as switch names and generate only those files.

- generate_ps_maps.pl
  -- This script will take the EPS files generated by the build_switch_configs.pl script and generate a printable postscript file. It will place 5 switch maps per page formatted for a landscape 11x17" printer page.

- generate_ps_stickers.pl
  -- This script will take the EPS files generated by the build_switch_configs.pl script and generate a postscript file suttable for printing and cutting actual switch labels on a SummaGraphics DC4. The intent is for printing (and cutting) adhesive vinyl labels which can be placed on the tops of the switches to provide a useful port map. The resulting file may work with other vinyl printer/cutters as well. It uses spot colors (50% cyan and 50% magenta) for cutting lines and process colors for all printed material. On the DC4, there is a cut line around each sticker that cuts through the vinyl, but not the backing paper and a cut line around each "page" of stickers that will cut through the vinyl and the backing paper leaving tabs to hold the backing paper together until deliberately removed.

- generate_ps_refs.pl
  -- This script takes the EPS files generated by the build_switch_configs.pl script and generates a file containing pages of switch reference maps intended for viewing on a laptop. It can be viewed on a phone, but is not optimized or likely to provide a particularly good user experience in a phone environment.

- switch_template.pm
  -- PERL module to support other scripts here. Most of the actual work occurs inside these library functions, especially reading and interpreting the various configuration files and generating actual configuration data for the switches.

- switch_pinger
  -- This script attempts to ping every switch and displays the status of each one.

- override_switches -- Deprecated, use switch_config_loader instead

- bulk_local_load_switches -- Deprecated, use switch_config_loader instead

## Contributing

SCaLE happens once a year but the team has ongoing projects and prep year round.
If you are interested in volunteering please request to join our mailing list:
https://lists.linuxfests.org/cgi-bin/mailman/listinfo/tech

> NOTE:
> If you are contributing and need to debug problems with generated PostScript code,
> edit the Makefile two levels up and take out the > /dev/null redirects on the gs
> calls. This will make PostScript error reports and stdout messages visible.
>
> PostScript code can be instrumented using "(string) print" commands and "pstack()="
> can be used to dump the current contents of the operand stack. If you need a newline,
> you can use "() print". (no newlines are added if () is not empty).
>
> A little instrumentation and being able to see the messages from GS can go a long
> way in helping debug the code. Look for pstack() (commented out at this time) in
> the switch_template.pm file for examples of instrumentation.
