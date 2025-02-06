if [[ -z "$1" ]]; then
  echo "ERROR: Please pass interface for dhcp server to bind to"
  exit 1
fi

IFACE=$1

sudo ip link add link "$IFACE" name "$IFACE".503 type vlan id 503
sudo ip addr add 192.168.254.1/24 dev "$IFACE".503
sudo ip link set up "$IFACE"
sudo ip link set up "$IFACE".503

if systemctl is-active --quiet service firewall; then
  echo -e "\nWARN: firewall is running so dhcp server might not be able to hand out leases\n\
WARN: consider running: sudo systemctl stop firewall\n"
fi

sudo dnsmasq -i "$IFACE".503 \
  --dhcp-range=192.168.254.100,192.168.254.120,255.255.255.0,120s \
  --dhcp-option=3,192.168.254.1 \
  -p0 -d \
  --dhcp-leasefile=./dnsmasq-lease.log \
  --bind-interfaces
