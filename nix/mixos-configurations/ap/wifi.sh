# shellcheck shell=sh

led() {
	led=$1
	echo "$2" >"/sys/class/leds/${led}/brightness"
}

# start with LEDS off
led green:lan 0
led amber:lan 0

case ${1:-} in
up)
	hostapd_cli -i wlan0 enable
	led green:lan 1
	;;
down)
	hostapd_cli -i wlan0 disable
	led amber:lan 1
	;;
*)
	echo "usage: wifi up|down"
	;;
esac
