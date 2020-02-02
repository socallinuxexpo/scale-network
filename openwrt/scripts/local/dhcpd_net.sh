#!/bin/sh

usage(){
  cat << EOF
usage: $(basename $0) [OPTIONS] ARGS


Simple template of getopts

OPTIONS:
  -h      Show this message
  -d      delete existing dhcpd service

EXAMPLES:
  To print out arg1:

      $(basename $0) arg1

EOF
}

DELETE=1

while getopts "hd" OPTION
do
  case $OPTION in
    d )
      DELETE=0
      ;;
    h )
      usage
      exit 0
      ;;
    \? )
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

CONFIG=$(cat << EOF
option domain-name "example.org";
option domain-name-servers 8.8.8.8, 8.8.4.4;
option subnet-mask 255.255.255.0;

default-lease-time 600;
max-lease-time 72400;
ddns-update-style none;

#subnet 192.168.1.0 netmask 255.255.255.0 {
#  range 192.168.1.50 192.168.1.100;
#  option routers 192.168.1.2;
#}

subnet 192.168.254.0 netmask 255.255.255.0 {
  range 192.168.254.100 192.168.254.200;
  option routers 192.168.254.1;
}
EOF
)

NETIF=${1:-ue0}
# Kill dhcpd if set
if [ $DELETE -eq 0 ];then
  echo "Deleting dhcpd"
  pkill dhcpd
  ifconfig ${NETIF} delete
else
  ifconfig ${NETIF} inet 192.168.254.1 netmask 255.255.255.0
  dhcpd -4 -cf /usr/local/etc/dhcpd.conf -lf /var/db/dhcpd/dhcpd.leases ${NETIF}
fi
