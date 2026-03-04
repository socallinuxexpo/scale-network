#shellcheck disable=SC2086
FILENAME="$(basename $0)"

usage(){
  cat << EOF
usage: $FILENAME [OPTIONS] ARGS

dhcpd service for adhoc dhcp

OPTIONS:
  -h      Show this message

EXAMPLES:
  Create a tagged interface and start dhcpd:

      $FILENAME enp7s0f4u2.503

  To print out this message:

      $FILENAME -h

EOF
}

while getopts "h" OPTION
do
  case $OPTION in
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

if [[ -z "$1" ]]; then
  echo "ERROR: Please pass interface for dhcp server to bind to"
  exit 1
fi

IFACE=$1

if [[ "$IFACE" == *.* ]]; then
  #shellcheck disable=SC2046
  sudo ip link add link $(echo "$IFACE" | cut -d . -f1) name "$IFACE" type vlan id $(echo "$IFACE" | cut -d . -f2)
fi
sudo ip addr add 192.168.254.1/24 dev "$IFACE"
if [[ "$IFACE" == *.* ]]; then
  #shellcheck disable=SC2046
  sudo ip link set up $(echo "$IFACE" | cut -d . -f1)
fi
sudo ip link set up "$IFACE"

if systemctl is-active --quiet service firewall; then
  echo -e "\nWARN: firewall is running so dhcp server might not be able to hand out leases\n\
WARN: consider running: sudo systemctl stop firewall\n"
fi

sudo dnsmasq -i "$IFACE" \
  --dhcp-range=192.168.254.100,192.168.254.120,255.255.255.0,120s \
  --dhcp-option=3,192.168.254.1 \
  -p0 -d \
  --dhcp-leasefile=./dnsmasq-lease.log \
  --bind-interfaces
