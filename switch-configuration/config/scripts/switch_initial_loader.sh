#!/bin/sh
#
# This script is intended to run on a Juniper script to download and install the
# current configuration file onto the switch. It is sent ot the switch as a
# "config file" specified by the DHCP server (downlaoded via http). The switch
# will then execute it to perform the following steps:
#
# 1. Get the current MAC address for the vme interface.
# 2. Verify that the switch has an IP address on the vme interface and can
#    connect to the scale-ztpserver.delong.com host to download information.
# 3. Use curl to download the switch configuration into /tmp from a CGI script
#    which will ultimately use the MAC address to determine which configuration
#    file to send and send that file as a text/plain document via HTTP. The
#    URL will be:r
#       http://scale-ztpserver.delong.com/cgi-bin/get_switch_config.cgi?MAC=<MACaddr>
#    (where MACaddr is the vme MAC address obtained in step 1).
# 4. Use the CLI and "load override <filename>" to replace the current switch
#    configuration with the one just downloaded and commit it.
# 5. Exit with a status of 0 to tell the JunOS ZTP process that it completed
#    successfully.
#
#
# Get current vme MAC address
MAC=`cli show interface vme | sed -n -e 's/^.*Current address: \(.*\), Hardware.*/\1/p'`
BRANCH='master'

# Verify I can reach scale-ztpserver.delong.com
ping -J4 -c 1 -i 1 scale-ztpserver.delong.com
result=$?
if [ "$result" -ne 0 ]; then
  echo "Cannot reach provisioning server -- Aborting."
  exit $result
fi

# Download the file to /tmp/config.txt
if [ -z "$BRANCH" ]; then
  BRANCH="master"
fi
curl -o /tmp/config.txt "http://scale-ztpserver.delong.com/cgi-bin/get_switch_config.cgi?MAC=$MAC&BRANCH=$BRANCH"
result=$?
if [ "$result" -ne 0 ]; then
  echo "Failure downloading configuration -- Aborting."
  exit $result
fi
grep '<HTML>' /tmp/config.txt
result=$?
if [ "$result" eq 0 ]; then
  echo "Configuration CGI returned error:"
  cat /tmp/config.txt | sed -e 's/^/	error: /'
  exit 256
fi

# Apply the new configuration
cat <<EOF | cli
edit
load override /tmp/config.txt
commit and-quit
EOF
result=$?
if [ "$result" -ne 0 ]; then
  echo "Failure loading configuration -- Aborting."
  exit $result
fi
echo "Review the following for potential errors:"
cat /var/log/script_output
echo "End of script output"

# Additional sanity checks to see if the configuration loaded properly.
HOSTNAME=`grep '^\s+host-name' /tmp/config.txt | sed -e 's/^.*name \(.*\);$/\1/'`
IHN=`hostname`
if [ "$HOSTNAME" != "$IHN" ]; then
  echo "Hostnames (Configured: $HOSTNAME, Installed: $IHN) don't match, possible config error."
  exit 1
fi
LOAD=`grep '^load complete' /var/log/script_output`
if [ "$LOAD" != "load complete" ]; then
  echo "At end of load, got message \"$LOAD\", possible config errors."
  exit 2
fi
CHECK=`grep 'configuration check' /var/log/script_output`
if [ "$CHECK" != "configuration check succeeds" ]
  echo "Configuration check reported \"$CHECK\" instead of success, possible config errors."
  exit 3
fi
COMMIT=`grep 'commit complete' /var/log/script_output`
if [ "$COMMIT" != "commit complete" ]; then
  echo "Commit reported \"$COMMIT\" instead of success, possible config errors."
  exit 4
fi

# Indicate success to the ZTP process
exit 0;

