#!/bin/sh
# wifi_lua_metrics_test.sh - detect the prometheus-node-exporter-lua wifi
# collector still exposing wifi_network_quality / wifi_network_signal_dbm.
#
# Those metrics are not radio measurements: libiwinfo averages station
# signal and clamps it, so the value is 0 or -255 with no clients. This
# test is behavior-only: it fetches the exporter's /metrics and checks
# what names are present. It does not inspect package versions, patch
# markers, or any particular upstream commit.
#
# PASS when wifi_network_bitrate or wifi_network_noise_dbm is present
# and wifi_network_quality and wifi_network_signal_dbm are absent.
# FAIL when quality or signal is present, or when the exporter is up
# but neither bitrate nor noise is present.
# SKIP when the exporter is not running (cannot fetch /metrics).
#
# Runs ON the AP (busybox ash). Prefers curl, falls back to busybox wget.
#
# Tunables (environment):
#   METRICS_URL   default http://127.0.0.1:9100/metrics
#   CURL          curl binary (optional)
#   WGET          wget binary (optional)

METRICS_URL=${METRICS_URL:-http://127.0.0.1:9100/metrics}

log() { echo "$*"; }
skip() { log "SKIP: $*"; exit 77; }
fail() { log "FAIL: $*"; exit 1; }
pass() { log "PASS: $*"; exit 0; }

ERR=
cleanup() { [ -n "$ERR" ] && rm -f "$ERR"; }
trap cleanup EXIT INT TERM
ERR=$(mktemp /tmp/wifi-lua-metrics.XXXXXX) || exit 1

fetch() {
	if command -v curl >/dev/null 2>&1; then
		curl -s -f --max-time 5 "$METRICS_URL"
		return $?
	fi
	if command -v wget >/dev/null 2>&1; then
		wget -q -O - -T 5 "$METRICS_URL"
		return $?
	fi
	return 127
}

# /metrics itself is the "is the exporter running?" signal. A connection
# error, empty body, or missing curl/wget is SKIP, not FAIL.
OUT=$(fetch 2>"$ERR")
rc=$?
if [ "$rc" -eq 127 ]; then
	skip "neither curl nor wget is available to fetch $METRICS_URL"
fi
if [ "$rc" -ne 0 ] || [ -z "$OUT" ]; then
	skip "prometheus-node-exporter-lua is not running or $METRICS_URL is unreachable (${rc}$([ -s "$ERR" ] && printf '; %s' "$(cat "$ERR")"))"
fi

# Match metric names at the start of a line (Prometheus text format:
# NAME '{' or NAME ' ' or '# TYPE NAME'). Avoid accidental substring
# hits in HELP text of some other family.
has_metric() {
	name=$1
	printf '%s\n' "$OUT" | grep -q -E "^# TYPE ${name} |^# HELP ${name} |^${name}[{ ]"
}

has_bitrate_or_noise=0
has_metric wifi_network_bitrate && has_bitrate_or_noise=1
has_metric wifi_network_noise_dbm && has_bitrate_or_noise=1

has_quality=0
has_signal=0
has_metric wifi_network_quality && has_quality=1
has_metric wifi_network_signal_dbm && has_signal=1

if [ "$has_quality" -eq 1 ] || [ "$has_signal" -eq 1 ]; then
	fail "wifi_network_quality and/or wifi_network_signal_dbm still present (quality=$has_quality signal=$has_signal)"
fi
if [ "$has_bitrate_or_noise" -eq 0 ]; then
	fail "exporter is up but wifi_network_bitrate and wifi_network_noise_dbm are both absent"
fi
pass "wifi_network_bitrate/noise present; wifi_network_quality and wifi_network_signal_dbm absent"
