#!/bin/sh

usage(){
  cat << EOF
usage: $(basename $0) [OPTIONS] ARGS


Simple template of getopts

OPTIONS:
  -h      Show this message
  -d      delete existing dhcpd service

EXAMPLES:
  To print out this message:

      $(basename $0) -h

  Run script in FreeBSD using doas

      doas ./$(basename $0) ue0
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

subnet 192.168.254.0 netmask 255.255.255.0 {
  range 192.168.254.100 192.168.254.200;
  option routers 192.168.254.1;
}
EOF
)

NETIF=${1:-ue0}
# Kill dhcpd if set
if [ $DELETE -eq 0 ];then
  echo "Deleting all dhcpd instances"
  pkill dhcpd
  sleep 2
  #TODO should make this cleaner
  rm -rf /tmp/dhcpd*
  ifconfig ${NETIF} delete
else
  tmp_file=$(mktemp -d -t dhcpd)
  echo $tmp_file
  ifconfig ${NETIF} inet 192.168.254.1 netmask 255.255.255.0
  #dhcpd -4 -cf /usr/local/etc/dhcpd.conf -lf /var/db/dhcpd/dhcpd.leases ${NETIF}
  # Need to create leases file before dhcpd starts
  touch $tmp_file/dhcpd.leases
  echo $CONFIG > $tmp_file/dhcpd.conf
  dhcpd -4 -cf $tmp_file/dhcpd.conf -lf $tmp_file/dhcpd.leases ${NETIF}
fi
