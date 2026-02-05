# shellcheck shell=sh

# Take options ascii options and convert to strings
opt224=$(printf "%b\n" "$(echo "$opt224" | sed 's/\(..\)/\\x\1/g')")
opt225=$(printf "%b\n" "$(echo "$opt225" | sed 's/\(..\)/\\x\1/g')")
opt226=$(printf "%b\n" "$(echo "$opt226" | sed 's/\(..\)/\\x\1/g')")

# Since this is called from other udhcpc scripts this cannot be changed to
# use /bin/bash without also modifying the script that calls this.

# TODO(jared): uncomment all instances of wlan1 stuff, when it works
# TODO(jared): what does config-version.sh do?

handle_wifi() {
	iface=$1
	current_status=$2
	new_status=$3

	if [ -z "$new_status" ]; then
		return
	fi

	if [ "$current_status" != "$new_status" ]; then
		# changing the channel requires disabling the interface first
		hostapd_cli -i "$iface" disable
		if [ "$(echo "$opt224" | tr "[:upper:]" "[:lower:]")" != "off" ]; then
			logger -t "dhcp-wifi" "changed $iface from $wlan0 to $opt224"
			hostapd_cli -i "$iface" set channel "$opt224"
			hostapd_cli -i "$iface" enable
		fi
	fi
}

wifi_status() {
	iface=$1
	status=$(hostapd_cli -i "$iface" status)

	if echo "$status" | grep -q "state=DISABLED"; then
		echo "off"
	else
		echo "$status" | grep "^channel=" | cut -d"=" -f2
	fi
}

case "$1" in
# Same actions for renew or bound for the time being
"renew" | "bound")
	# dump params to run so its easier to troubleshoot
	set >/run/dhcp.params

	wlan0=$(wifi_status wlan0)
	handle_wifi wlan0 "$wlan0" "$opt224"

	# wlan1=$(wifi_status wlan1)
	# handle_wifi wlan1 "$wlan1" "$opt225"

	# populate apinger template
	if [ ! -z "$router" ]; then
		sed "s/@DEFAULTGATEWAY@/$router/g" /etc/apinger.tmpl >/run/apinger.conf
		# Only restart apinger if compare has diff
		if ! cmp /run/apinger.conf /etc/apinger.conf; then
			sleep 5
			# Make sure wifi always starts up since apinger will
			# not trigger an alarm if it pings good but
			# wifi was down to begin with
			wifi up
			install -m0644 /run/apinger.conf /etc/apinger.conf
			pkill -1 apinger
		fi
	fi

	if [ ! -z "$hostname" ]; then
		current_hostname=$(hostname)
		hostname "$hostname"
		logger -t "dhcp-hostname" "changed hostname from $current_hostname to $hostname"
		# TODO(jared): ask why this is needed
		# # reload/restart whatever needs the hostname updated
		# /etc/init.d/system reload
		# service rsyslog restart
		# service lldpd restart
		# # prometheus doesnt understand restart
		# service prometheus-node-exporter-lua stop
		# service prometheus-node-exporter-lua start
	fi

	if [ ! -z "$opt226" ]; then
		true
		# /root/bin/config-version.sh -c $opt226
	fi
	;;
esac
