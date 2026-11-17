#!/bin/sh
# wifi_scan_spin_test.sh - detect the ucode nl80211 waitfor() busy-spin that
# hung `iwinfo <if> scan` on SCALE 23x (March 2026) APs (and the related "iwinfo accepts
# the scan-done event of the other radio" bug).
#
# Runs ON the AP (busybox ash is enough; no `timeout`, `iw` or float `sleep`
# needed). Every child is killed by the script's own deadline.
#
# Test A (library):   trigger a 5 GHz scan and nl80211.waitfor() it exactly
#                     like iwinfo.uc does; trigger a 2.4 GHz scan 1 s later.
#                     FAIL if the waiting process burns > SPIN_TICKS ticks.
# Test B (end-to-end): `iwinfo <5g-if> scan`, 2.4 GHz scan 1 s later.
#                     FAIL if iwinfo is still running at the deadline, burns
#                     > SPIN_TICKS ticks in any 1 s window after start-up or
#                     > MAX_TOTAL_TICKS overall, returns while its own 5 GHz
#                     scan is still running (= it took the 2.4 GHz event), or
#                     prints any 2.4 GHz cell for the 5 GHz interface.
#
# Exit: 0 PASS, 1 FAIL, 77 SKIP (e.g. no 5 GHz AP iface, scan EBUSY on DFS).
#
# Tunables (environment):
#   IF5 / IF2           5 GHz / 2.4 GHz interface (default: auto-detect AP
#                       ifaces via nl80211, normally phy1-ap0 / phy0-ap0)
#   SPIN_TICKS=20       max CPU ticks (USER_HZ, 100/s) for test A and per 1 s
#                       window in test B
#   MAX_TOTAL_TICKS=150 max total iwinfo ticks in test B
#   DEADLINE=12         seconds before a test's process is declared hung/killed
#   SETTLE=8            seconds to let scans finish between tests
#   STRICT_OWN_SCAN=1   FAIL test B if iwinfo returned before its own scan ended
#   REQUIRE_5G_RESULTS=0  1: test B must also print >=1 "Band: 5 GHz" cell
#                       (needs 5 GHz neighbours in the lab). A 2.4 GHz cell in
#                       the 5 GHz scan is always a FAIL.
#   TESTS="A B"         which tests to run
#   UCODE=ucode IWINFO=iwinfo  binaries (overridable for harness self-tests)

SPIN_TICKS=${SPIN_TICKS:-20}
MAX_TOTAL_TICKS=${MAX_TOTAL_TICKS:-150}
DEADLINE=${DEADLINE:-12}
SETTLE=${SETTLE:-8}
STRICT_OWN_SCAN=${STRICT_OWN_SCAN:-1}
REQUIRE_5G_RESULTS=${REQUIRE_5G_RESULTS:-0}
TESTS=${TESTS:-"A B"}
UCODE=${UCODE:-ucode}
IWINFO=${IWINFO:-iwinfo}

T=$(mktemp -d /tmp/scanspin.XXXXXX) || exit 1
FAILS=0
SKIPS=0
cleanup() {
	for f in "$T"/*.pid; do
		[ -f "$f" ] && kill -9 "$(cat "$f")" 2>/dev/null
	done
	rm -rf "$T"
}
trap cleanup EXIT INT TERM

log() { echo "$*"; }

# ---- ucode helpers ---------------------------------------------------------
cat > "$T/detect.uc" <<'UC'
import * as nl80211 from 'nl80211';
let ifs = nl80211.request(nl80211.const.NL80211_CMD_GET_INTERFACE, nl80211.const.NLM_F_DUMP) || [];
let if2, if5;
for (let i in ifs) {
	if (i.iftype != 3 || !i.wiphy_freq) continue;	/* NL80211_IFTYPE_AP, up */
	if (!if2 && i.wiphy_freq < 3000) if2 = i.dev;
	if (!if5 && i.wiphy_freq > 4900 && i.wiphy_freq < 5950) if5 = i.dev;
}
print(`${if5 ?? ''} ${if2 ?? ''}\n`);
UC

# trigger a scan the way iwinfo.uc does (AP flag, wildcard SSID), no wait
cat > "$T/trigger.uc" <<'UC'
import * as nl80211 from 'nl80211';
let r = nl80211.request(nl80211.const.NL80211_CMD_TRIGGER_SCAN, 0,
	{ dev: getenv('SCAN_IF'), scan_flags: 4, scan_ssids: [ '' ] });
if (r === false) { print(`TRIGGER_FAIL ${nl80211.error()}\n`); exit(1); }
print('TRIGGERED\n');
UC

# test A: same trigger + waitfor sequence as iwinfo.uc scan() at OPENWRT_VER
cat > "$T/waitprobe.uc" <<'UC'
import * as nl80211 from 'nl80211';
let dev = getenv('SCAN_IF');
let r = nl80211.request(nl80211.const.NL80211_CMD_TRIGGER_SCAN, 0,
	{ dev, scan_flags: 4, scan_ssids: [ '' ] });
if (r === false) { print(`TRIGGER_FAIL ${nl80211.error()}\n`); exit(1); }
let res = nl80211.waitfor([ nl80211.const.NL80211_CMD_NEW_SCAN_RESULTS,
			    nl80211.const.NL80211_CMD_SCAN_ABORTED ], 5000);
if (!res) { print(`WAIT_TIMEOUT ${nl80211.error()}\n`); exit(0); }
print(`WAIT_RESULT cmd=${res.cmd} dev=${res.msg?.dev}\n`);
UC

# ---- helpers ---------------------------------------------------------------
# prints "<state> <utime+stime>" of a pid, nothing if gone
proc_ticks() {
	[ -n "$1" ] && [ -r "/proc/$1/stat" ] || return 1
	read -r line < "/proc/$1/stat" 2>/dev/null || return 1
	line=${line#*) }	# strip "pid (comm) "
	set -- $line		# $1=state ... $12=utime $13=stime
	echo "$1 $(( ${12} + ${13} ))"
}

is_busy() { grep -qi 'busy' "$1"; }

# measure <name> <cmd...>
# Runs <cmd> under a wrapper shell whose cutime/cstime collect the child's
# CPU ticks after it exits; samples the live child once per second; triggers
# the 2.4 GHz scan at t=1 s; kills everything at DEADLINE.
# Sets: M_HUNG M_STATE M_TOTAL M_MAXDELTA M_OWNBUSY
measure() {
	name=$1; shift
	OUTF="$T/$name.out" PIDF="$T/$name.pid" RCF="$T/$name.rc"
	STATF="$T/$name.stat" PROBEF="$T/$name.probe"
	rm -f "$OUTF" "$PIDF" "$RCF" "$STATF" "$PROBEF"
	OUTF="$OUTF" PIDF="$PIDF" RCF="$RCF" STATF="$STATF" PROBEF="$PROBEF" \
	SCAN_IF5="$IF5" TRIG="$T/trigger.uc" UCODE="$UCODE" \
	sh -c 'export SCAN_IF="$SCAN_IF5"; "$@" >"$OUTF" 2>&1 &
		c=$!; echo $c >"$PIDF"; wait $c; echo $? >"$RCF"
		cat /proc/$$/stat >"$STATF"
		SCAN_IF="$SCAN_IF5" "$UCODE" "$TRIG" >"$PROBEF" 2>&1' sh "$@" &
	W=$!
	echo $W > "$T/$name.wpid"

	M_HUNG=0 M_STATE=- M_MAXDELTA=0 M_TOTAL=0 M_OWNBUSY=0
	prev=
	t=0
	while [ $t -lt "$DEADLINE" ]; do
		sleep 1
		t=$((t + 1))
		if [ $t -eq 1 ]; then
			SCAN_IF="$IF2" "$UCODE" "$T/trigger.uc" >"$T/$name.trig2g" 2>&1
		fi
		c=$(cat "$PIDF" 2>/dev/null)
		s=$(proc_ticks "$c") || break
		set -- $s
		M_STATE=$1
		if [ -n "$prev" ]; then
			d=$(( $2 - prev ))
			[ $d -gt $M_MAXDELTA ] && M_MAXDELTA=$d
		fi
		prev=$2
		M_TOTAL=$2
	done

	c=$(cat "$PIDF" 2>/dev/null)
	if s=$(proc_ticks "$c"); then
		set -- $s
		M_HUNG=1 M_STATE=$1 M_TOTAL=$2
		[ -n "$prev" ] && [ $(( $2 - prev )) -gt $M_MAXDELTA ] && M_MAXDELTA=$(( $2 - prev ))
		kill -9 "$c" 2>/dev/null
		kill -9 "$W" 2>/dev/null
	fi
	# wrapper: wait at most 3 s more for the post-exit probe, then kill it
	i=0
	while kill -0 "$W" 2>/dev/null && [ $i -lt 3 ]; do sleep 1; i=$((i + 1)); done
	kill -9 "$W" 2>/dev/null
	wait "$W" 2>/dev/null
	rm -f "$PIDF" "$T/$name.wpid"

	if [ $M_HUNG -eq 0 ] && [ -r "$STATF" ]; then
		line=$(cat "$STATF"); line=${line#*) }; set -- $line
		M_TOTAL=$(( ${14} + ${15} ))	# cutime + cstime of the wrapper
	fi
	[ -r "$PROBEF" ] && is_busy "$PROBEF" && M_OWNBUSY=1
	log "  [$name] hung=$M_HUNG last_state=$M_STATE total_ticks=$M_TOTAL max_ticks_per_s=$M_MAXDELTA rc=$(cat "$RCF" 2>/dev/null || echo killed)"
	log "  [$name] 2.4GHz trigger: $(cat "$T/$name.trig2g" 2>/dev/null)"
	log "  [$name] own-scan probe after exit: $(cat "$PROBEF" 2>/dev/null | head -n1)"
	log "  [$name] output (first lines):"; head -n 5 "$OUTF" 2>/dev/null | sed 's/^/    /'
}

# ---- main ------------------------------------------------------------------
if [ -z "$IF5" ] || [ -z "$IF2" ]; then
	set -- $("$UCODE" "$T/detect.uc" 2>/dev/null)
	IF5=${IF5:-$1}; IF2=${IF2:-$2}
fi
log "wifi scan spin test: IF5=${IF5:-none} IF2=${IF2:-none} SPIN_TICKS=$SPIN_TICKS DEADLINE=${DEADLINE}s TESTS=$TESTS"
if [ -z "$IF5" ] || [ -z "$IF2" ]; then
	log "RESULT: SKIP (need an active 5 GHz and 2.4 GHz AP interface)"
	exit 77
fi

for test in $TESTS; do
	case $test in
	A)
		log "Test A: nl80211.waitfor() on $IF5 with a $IF2 scan at +1 s"
		measure A "$UCODE" "$T/waitprobe.uc"
		if grep -q TRIGGER_FAIL "$T/A.out"; then
			log "  A: SKIP - cannot trigger a scan on $IF5 (DFS/CAC channel?)"
			SKIPS=$((SKIPS + 1))
		elif [ $M_HUNG -eq 1 ] || [ "$M_TOTAL" -gt "$SPIN_TICKS" ]; then
			log "  A: FAIL - waitfor() burned $M_TOTAL ticks (limit $SPIN_TICKS), hung=$M_HUNG state=$M_STATE"
			FAILS=$((FAILS + 1))
		else
			log "  A: PASS - waitfor() slept ($M_TOTAL ticks)"
		fi
		grep -q "WAIT_RESULT.*dev=$IF2" "$T/A.out" &&
			log "  A: note - raw waitfor() returned $IF2's event (expected; iwinfo.uc must filter, see test B)"
		;;
	B)
		log "Test B: $IWINFO $IF5 scan with a $IF2 scan at +1 s"
		measure B "$IWINFO" "$IF5" scan
		reason=
		if is_busy "$T/B.out"; then
			log "  B: SKIP - $IF5 scan EBUSY (DFS/CAC channel or scan already running)"
			SKIPS=$((SKIPS + 1))
		else
			[ $M_HUNG -eq 1 ] && reason="$reason hung(state=$M_STATE)"
			[ "$M_MAXDELTA" -gt "$SPIN_TICKS" ] && reason="$reason spin($M_MAXDELTA ticks/s)"
			[ "$M_TOTAL" -gt "$MAX_TOTAL_TICKS" ] && reason="$reason cpu($M_TOTAL ticks)"
			[ "$STRICT_OWN_SCAN" = 1 ] && [ $M_HUNG -eq 0 ] && [ $M_OWNBUSY -eq 1 ] &&
				reason="$reason returned-before-own-scan-finished"
			n24=$(grep -c 'Band: 2.4 GHz' "$T/B.out")
			n5=$(grep -c 'Band: 5 GHz' "$T/B.out")
			[ "$n24" -gt 0 ] && reason="$reason 2.4GHz-cells-in-5GHz-scan($n24)"
			[ "$REQUIRE_5G_RESULTS" = 1 ] && [ "$n5" -eq 0 ] && reason="$reason no-5GHz-cells"
			if [ -n "$reason" ]; then
				log "  B: FAIL -$reason"
				FAILS=$((FAILS + 1))
			else
				log "  B: PASS ($(grep -c '^Cell' "$T/B.out") cells: $n5 x 5 GHz, $n24 x 2.4 GHz; $M_TOTAL ticks)"
			fi
		fi
		;;
	esac
	sleep "$SETTLE"
done

if [ $FAILS -gt 0 ]; then
	log "RESULT: FAIL ($FAILS failed, $SKIPS skipped)"
	exit 1
elif [ $SKIPS -gt 0 ]; then
	log "RESULT: SKIP ($SKIPS skipped)"
	exit 77
fi
log "RESULT: PASS"
exit 0
