#!/bin/sh
# hostapd_rnr_same_ssid_test.sh - detect the hostapd bug that omits
# same-SSID neighbor APs from beacon Reduced Neighbor Report (IE 201).
#
# Stock hostapd_eid_nr_db() / hostapd_eid_nr_db_len() skip every nr_db
# entry whose short_ssid matches this BSS, so a same-ESS neighbor never
# appears in the beacon. The fix skips only this BSS's own BSSID.
#
# This test is behavior-only: it does not inspect package versions,
# patch markers, or any particular upstream commit. It injects a fake
# neighbor with this AP's SSID and a different (locally administered)
# BSSID, captures this AP's beacons on a temporary monitor, and looks
# for that BSSID in the captured frames. rrm_nr_list / rrm_nr_get_own
# cannot prove the beacon contents (the list already skips only own
# BSSID), so a short-lived monitor is required.
#
# It does not enable rnr (SKIP if rnr is not already 1 on a running
# BSS). It does not enable rrm_beacon_report. Calling rrm_nr_get_own /
# rrm_nr_set may enable the Neighbor Report *capability* bit; that is
# not a beacon report and is left as hostapd leaves it.
#
# Runs ON the AP (busybox ash + ubus + jq + tcpdump + iw). The neighbor
# list and monitor iface are always restored on exit.
#
# Exit: 0 PASS, 1 FAIL, 77 SKIP (no hostapd ubus object, rnr off,
# missing tools, cannot capture, etc.).
#
# Tunables (environment):
#   IFACE            hostapd BSS iface (default: first with rnr=1)
#   FAKE_BSSID       locally administered BSSID to inject
#                    (default 02:00:00:de:ad:01)
#   MON_IF           temporary monitor name (default mon-rnr0)
#   BEACONS=8        tcpdump packet count
#   CAPTURE_SEC=4    seconds to wait for beacons
#   CONF_GLOB        hostapd conf glob (default: /tmp/run/hostapd*.conf
#                    and /var/run/hostapd*.conf)

FAKE_BSSID=${FAKE_BSSID:-02:00:00:de:ad:01}
MON_IF=${MON_IF:-mon-rnr0}
BEACONS=${BEACONS:-8}
CAPTURE_SEC=${CAPTURE_SEC:-4}

T=$(mktemp -d /tmp/rnrssid.XXXXXX) || exit 1
RESTORED=0
MON_ADDED=0
IFACE_USED=
ORIG_LIST=

cleanup() {
	if [ "$MON_ADDED" -eq 1 ]; then
		ip link set "$MON_IF" down 2>/dev/null
		iw dev "$MON_IF" del 2>/dev/null
	fi
	if [ -n "$IFACE_USED" ] && [ "$RESTORED" -eq 0 ] && [ -n "$ORIG_LIST" ]; then
		ubus call "hostapd.$IFACE_USED" rrm_nr_set "$ORIG_LIST" >/dev/null 2>&1
		ubus call "hostapd.$IFACE_USED" update_beacon >/dev/null 2>&1
		RESTORED=1
	fi
	rm -rf "$T"
}
trap cleanup EXIT INT TERM

log() { echo "$*"; }
skip() { log "SKIP: $*"; exit 77; }
fail() { log "FAIL: $*"; exit 1; }
pass() { log "PASS: $*"; exit 0; }

command -v ubus >/dev/null 2>&1 || skip "ubus not found"
command -v jq >/dev/null 2>&1 || skip "jq not found"
command -v tcpdump >/dev/null 2>&1 || skip "tcpdump not found"
command -v iw >/dev/null 2>&1 || skip "iw not found"

# ---- pick a hostapd BSS that already has rnr=1 --------------------------------
# Print rnr value for a BSS iface from hostapd conf, or empty if unset.
rnr_for_iface() {
	iface=$1
	val=
	for f in /tmp/run/hostapd*.conf /var/run/hostapd*.conf; do
		[ -f "$f" ] || continue
		val=$(awk -v iface="$iface" '
			BEGIN { FS="=" }
			$1=="interface" || $1=="bss" { cur=$2 }
			$1=="rnr" && cur==iface { print $2 }
		' "$f")
		[ -n "$val" ] && { printf '%s\n' "$val"; return 0; }
	done
	return 1
}

list_hostapd_ifaces() {
	ubus list 2>/dev/null | sed -n 's/^hostapd\.//p'
}

if [ -n "${IFACE:-}" ]; then
	CANDIDATES=$IFACE
else
	CANDIDATES=$(list_hostapd_ifaces)
fi
[ -n "$CANDIDATES" ] || skip "no hostapd ubus object"

IFACE=
for cand in $CANDIDATES; do
	val=$(rnr_for_iface "$cand" || true)
	if [ "$val" = 1 ]; then
		IFACE=$cand
		break
	fi
	log "iface $cand rnr=${val:-unset}"
done
[ -n "$IFACE" ] || skip "rnr is not 1 on any running hostapd BSS (will not enable it)"
log "using $IFACE (rnr=1)"
IFACE_USED=$IFACE

# ---- snapshot neighbor list, inject a same-SSID fake BSSID --------------------
if ! ubus call "hostapd.$IFACE" rrm_nr_get_own > "$T/own.json" 2>"$T/own.err"; then
	skip "rrm_nr_get_own failed: $(cat "$T/own.err")"
fi
if ! ubus call "hostapd.$IFACE" rrm_nr_list > "$T/orig.json" 2>"$T/list.err"; then
	skip "rrm_nr_list failed: $(cat "$T/list.err")"
fi
ORIG_LIST=$(cat "$T/orig.json")

OWN_BSSID=$(jq -r '.value[0] // empty' "$T/own.json")
OWN_SSID=$(jq -r '.value[1] // empty' "$T/own.json")
OWN_NR=$(jq -r '.value[2] // empty' "$T/own.json")
[ -n "$OWN_BSSID" ] && [ -n "$OWN_NR" ] || skip "rrm_nr_get_own returned no BSSID/NR"

own_hex=$(printf '%s' "$OWN_BSSID" | tr -d ':' | tr 'A-F' 'a-f')
fake_hex=$(printf '%s' "$FAKE_BSSID" | tr -d ':' | tr 'A-F' 'a-f')
nr_lc=$(printf '%s' "$OWN_NR" | tr 'A-F' 'a-f')
NEW_NR=$(printf '%s' "$nr_lc" | sed "s/${own_hex}/${fake_hex}/")
[ -n "$NEW_NR" ] || skip "could not rewrite own neighbor report for the fake BSSID"

jq -n --arg b "$FAKE_BSSID" --arg s "$OWN_SSID" --arg n "$NEW_NR" \
	'{list:[[$b,$s,$n]]}' > "$T/set.json"
if ! ubus call "hostapd.$IFACE" rrm_nr_set "$(cat "$T/set.json")" >"$T/set.out" 2>"$T/set.err"; then
	skip "rrm_nr_set failed: $(cat "$T/set.err")$(cat "$T/set.out")"
fi
ubus call "hostapd.$IFACE" update_beacon >/dev/null 2>&1 || true

# ---- temporary monitor on the same phy ----------------------------------------
PHY=$(iw dev "$IFACE" info 2>/dev/null | awk '/wiphy/{print "phy"$2; exit}')
[ -n "$PHY" ] || skip "could not find phy for $IFACE"

# Re-use a leftover name if a previous run died hard.
iw dev "$MON_IF" del >/dev/null 2>&1 || true
if ! iw phy "$PHY" interface add "$MON_IF" type monitor >"$T/mon.out" 2>"$T/mon.err"; then
	skip "cannot add monitor $MON_IF on $PHY: $(cat "$T/mon.err")"
fi
MON_ADDED=1
if ! ip link set "$MON_IF" up; then
	skip "cannot bring $MON_IF up"
fi

tcpdump -i "$MON_IF" -c "$BEACONS" -s 0 -n -l -xx \
	type mgt subtype beacon and wlan addr3 "$OWN_BSSID" \
	> "$T/cap.xx" 2>"$T/cap.err" &
TD_PID=$!
# busybox sleep is integer-only; CAPTURE_SEC is seconds.
sleep "$CAPTURE_SEC"
# If tcpdump is still around, it did not hit -c; kill it and inspect.
if kill -0 "$TD_PID" 2>/dev/null; then
	kill "$TD_PID" 2>/dev/null
	wait "$TD_PID" 2>/dev/null || true
else
	wait "$TD_PID" 2>/dev/null || true
fi

hex=$(sed -n 's/^[ \t]*0x[0-9a-fA-F]*:[ \t]*//p' "$T/cap.xx" | tr -d ' \t\n' | tr 'A-F' 'a-f')
[ -n "$hex" ] || skip "no beacons captured for $OWN_BSSID on $MON_IF ($(cat "$T/cap.err"))"

case $hex in
*"$fake_hex"*)
	pass "beacon from $OWN_BSSID contains same-SSID neighbor $FAKE_BSSID"
	;;
*)
	fail "captured beacons from $OWN_BSSID but $FAKE_BSSID is absent (same-SSID neighbor dropped from RNR)"
	;;
esac
