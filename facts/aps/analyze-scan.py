#!/usr/bin/env python3
# WiFi Channel Planner - Effective dBm Power-Sum Method (with real Noise Floor)
#
# PURPOSE
# Analyzes iwinfo + iwinfo scan output from multiple APs to recommend channels
# for a given SSID, minimizing real co-channel interference.
# Uses physically correct power addition (not naive dBm summing).
# Now uses the actual "Noise: -xx dBm" value reported by each AP as the base
# interference floor instead of the arbitrary -120 dBm.
#
# USAGE
#   python3 analyze-scan.py <ssid> <data_file> [options]
#
# EXAMPLES
#   # Show plan + before/after statistics
#   python3 analyze-scan.py "scale-public-slow" scan-results.txt
#
#   # Generate plan and update CSV with suggested channels
#   python3 analyze-scan.py "scale-public-slow" scan-results.txt --update apuse.csv
#
#   # Show this help
#   python3 analyze-scan.py --help
#
# OUTPUT
#   - Current (Before) interference stats based on existing channels from data file
#   - Suggested (After) channel assignments and interference stats
#   - Before/after histograms of individual co-channel signal strengths
#   - If --update used: confirmation of new .auto-channel file
#
# INTERFERENCE MATH EXPLANATION
# dBm is logarithmic. Interference adds in linear power domain, NOT dBm.
#
# Correct combination (effective_dBm):
#   1. Convert each dBm → mW: power = 10^(dBm / 10)
#   2. Sum powers: total_mW = Σ power_i
#   3. Back to dBm: effective_dBm = 10 * log10(total_mW)
#
# Now includes the real "Noise: -xx dBm" from iwinfo as the base floor for each AP.
# When co-channel signals are present, they are added to the noise floor in the
# power domain before converting back to dBm. This gives the true total noise+interference
# each AP experiences.
#
# Examples:
#   Noise -95 dBm + one -70 dBm co-channel → effective ≈ -69.6 dBm
#   Noise -95 dBm + two -70 dBm → effective ≈ -66.8 dBm
#
# ----------------------------------------------------------------------

import sys
import re
import math
import csv
import os
import statistics
from collections import defaultdict
import random
import argparse

def parse_own_ap(lines, start):
    ap = {}
    line = lines[start]
    m = re.search(r'(phy\d+-ap\d+) ESSID: "(.*?)"', line)
    if m:
        ap['interface'] = m.group(1)
        ap['ssid'] = m.group(2)
    i = start + 1
    while i < len(lines) and not (lines[i].startswith('phy') and 'ESSID:' in lines[i]) and not lines[i].startswith('Cell '):
        l = lines[i].strip()
        if 'Access Point:' in l:
            m = re.search(r'Access Point: ([\w:]+)', l)
            if m:
                ap['bssid'] = m.group(1).lower()
        elif 'Channel:' in l:
            m = re.search(r'Channel: (\d+)', l)
            if m:
                ap['channel'] = int(m.group(1))
                ch = ap['channel']
                if ch <= 14:
                    ap['band'] = '2.4'
                else:
                    ap['band'] = '5'
        elif 'Noise:' in l:
            m = re.search(r'Noise: (-?\d+) dBm', l)
            if m:
                ap['noise_floor'] = int(m.group(1))
        i += 1
    ap['end_index'] = i
    return ap

def parse_scan(lines, start):
    scan = {}
    line = lines[start]
    m = re.search(r'Cell \d+ - Address: ([\w:]+)', line)
    if m:
        scan['bssid'] = m.group(1).lower()
    i = start + 1
    while i < len(lines) and not (lines[i].startswith('phy') and 'ESSID:' in lines[i]) and not lines[i].startswith('Cell '):
        l = lines[i].strip()
        if 'ESSID:' in l:
            m = re.search(r'ESSID: "(.*?)"', l)
            if m:
                scan['ssid'] = m.group(1)
        elif 'Channel:' in l:
            m = re.search(r'Channel: (\d+)', l)
            if m:
                scan['channel'] = int(m.group(1))
                ch = scan['channel']
                if ch <= 14:
                    scan['band'] = '2.4'
                else:
                    scan['band'] = '5'
        elif 'Signal:' in l:
            m = re.search(r'Signal: (-?\d+) dBm', l)
            if m:
                scan['signal'] = int(m.group(1))
        i += 1
    scan['end_index'] = i
    return scan

def effective_dbm(signals_list):
    if not signals_list:
        return -120.0
    total_power = sum(10 ** (sig / 10.0) for sig in signals_list)
    return 10 * math.log10(total_power)

def compute_total_effective(assignment, signals, devs):
    per_channel = defaultdict(list)
    for dev1 in devs:
        for dev2 in signals.get(dev1, {}):
            if assignment.get(dev1) == assignment.get(dev2):
                per_channel[assignment[dev1]].append(signals[dev1][dev2])
    total_eff = 0
    for ch_signals in per_channel.values():
        total_eff += effective_dbm(ch_signals)
    return total_eff

def compute_per_channel_stats(assignment, signals, devs, avail, noise_floors):
    per_ch = {}
    for ch in avail:
        aps_on_ch = [dev for dev in devs if assignment.get(dev) == ch]

        # Channel-wide total (all directed pairs)
        all_signals_on_ch = []
        for dev1 in aps_on_ch:
            for dev2 in signals.get(dev1, {}):
                if assignment.get(dev2) == ch:
                    all_signals_on_ch.append(signals[dev1][dev2])
        channel_eff = effective_dbm(all_signals_on_ch)

        # Per-AP effective interference (noise + co-channel signals received by this AP)
        per_ap_eff = []
        for ap in aps_on_ch:
            ap_signals = []
            # Add co-channel signals this AP hears
            for other in aps_on_ch:
                if other != ap and other in signals.get(ap, {}):
                    ap_signals.append(signals[ap][other])
            # Combine with this AP's own noise floor
            noise = noise_floors.get(ap, -95)
            total_power = 10 ** (noise / 10.0)
            for sig in ap_signals:
                total_power += 10 ** (sig / 10.0)
            per_ap_eff.append(10 * math.log10(total_power))

        if per_ap_eff:
            avg = statistics.mean(per_ap_eff)
            med = statistics.median(per_ap_eff)
            worst = max(per_ap_eff)
        else:
            avg = med = worst = None

        per_ch[ch] = {
            'effective_dbm': channel_eff,
            'ap_count': len(aps_on_ch),
            'average_per_ap_dbm': avg,
            'median_per_ap_dbm': med,
            'worst_per_ap_dbm': worst,
            'pair_count': len(all_signals_on_ch)
        }
    return per_ch

def compute_histogram(cochannel_signals):
    bins = {
        '>= -50': 0,
        '-51 to -60': 0,
        '-61 to -70': 0,
        '-71 to -80': 0,
        '-81 to -90': 0,
        '-91 to -100': 0,
        '<= -101': 0
    }
    for sig in cochannel_signals:
        if sig >= -50:
            bins['>= -50'] += 1
        elif -60 <= sig <= -51:
            bins['-51 to -60'] += 1
        elif -70 <= sig <= -61:
            bins['-61 to -70'] += 1
        elif -80 <= sig <= -71:
            bins['-71 to -80'] += 1
        elif -90 <= sig <= -81:
            bins['-81 to -90'] += 1
        elif -100 <= sig <= -91:
            bins['-91 to -100'] += 1
        else:
            bins['<= -101'] += 1
    return bins

def get_cochannel_signals(assignment, signals, devs):
    co_signals = []
    for dev1 in devs:
        for dev2 in signals.get(dev1, {}):
            if assignment.get(dev1) == assignment.get(dev2):
                co_signals.append(signals[dev1][dev2])
    return co_signals

def assign_channels(devs, avail, signals, incoming):
    assignment = {}
    assigned_to = defaultdict(list)
    order = list(devs)
    random.shuffle(order)
    for dev in order:
        costs = {}
        for ch in avail:
            signals_on_ch = []
            for u in assigned_to[ch]:
                if u in signals.get(dev, {}):
                    signals_on_ch.append(signals[dev][u])
                if u in incoming.get(dev, {}):
                    signals_on_ch.append(incoming[dev][u])
            costs[ch] = effective_dbm(signals_on_ch)
        min_cost = min(costs.values())
        best_chs = [ch for ch, c in costs.items() if c == min_cost]
        best_chs = sorted(best_chs, key=lambda c: len(assigned_to[c]))
        chosen_ch = best_chs[0]
        assignment[dev] = chosen_ch
        assigned_to[chosen_ch].append(dev)
    return assignment

def update_csv(csv_path, assignment, band, verbose=False):
    output_path = csv_path + ".auto-channel"
    if not os.path.exists(csv_path):
        print(f"Error: CSV file not found: {csv_path}", file=sys.stderr)
        return

    with open(csv_path, 'r', newline='') as f_in:
        reader = csv.DictReader(f_in)
        fieldnames = reader.fieldnames
        rows = list(reader)

    # Build IP → suggested channel map
    ip_to_ch = {dev: ch for dev, ch in assignment.items()}

    updated_count = 0
    changed_count = 0

    with open(output_path, 'w', newline='') as f_out:
        writer = csv.DictWriter(f_out, fieldnames=fieldnames, lineterminator='\n')
        writer.writeheader()

        for row in rows:
            ip = row.get('ipv4', '').strip()
            if not ip:
                writer.writerow(row)
                continue

            if ip in ip_to_ch:
                new_ch = ip_to_ch[ip]
                if band == '2.4':
                    col = '2.4Ghz_chan'
                    if col in row:
                        old_val = row[col].strip()
                        row[col] = str(new_ch)
                        updated_count += 1
                        if old_val != str(new_ch):
                            changed_count += 1
                            if verbose:
                                name = row.get('name', ip)
                                print(f"  Updated {name} (IP {ip}): {old_val} → {new_ch} ({col})", file=sys.stderr)
                else:
                    col = '5Ghz_chan'
                    if col in row:
                        old_val = row[col].strip()
                        row[col] = str(new_ch)
                        updated_count += 1
                        if old_val != str(new_ch):
                            changed_count += 1
                            if verbose:
                                name = row.get('name', ip)
                                print(f"  Updated {name} (IP {ip}): {old_val} → {new_ch} ({col})", file=sys.stderr)
            writer.writerow(row)

    print(f"Output CSV written to: {output_path}")
    print(f"Rows matched and updated: {updated_count}")
    print(f"Rows with actual channel value change: {changed_count}")

    if verbose and changed_count == 0 and updated_count > 0:
        print("  (No value changes — suggested channels matched current values in CSV)", file=sys.stderr)

# ──────────────────────────────────────────────────────────────────────────────
# Command-line parsing
# ──────────────────────────────────────────────────────────────────────────────

parser = argparse.ArgumentParser(
    description="WiFi channel planner using effective dBm power-sum interference model",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog="""
Examples:
  # Show plan and statistics only
  python3 channel_planner.py "scale-public-slow" scan-results.txt

  # Generate plan and update CSV
  python3 channel_planner.py "scale-public-fast" scan-results.txt --update apuse.csv

  # Show this help
  python3 channel_planner.py --help
"""
)

parser.add_argument("ssid", help="SSID to analyze")
parser.add_argument("data_file", help="Input file with concatenated iwinfo output")
parser.add_argument("--update", metavar="CSVFILE",
                    help="CSV file to update with new channels (creates CSVFILE.auto-channel)")

args = parser.parse_args()

ssid = args.ssid
data_file = args.data_file
update_csv_path = args.update

# ──────────────────────────────────────────────────────────────────────────────
# Parse the data file
# ──────────────────────────────────────────────────────────────────────────────

devices = defaultdict(lambda: {'own_aps': [], 'scans': [], 'lines': []})

with open(data_file, 'r') as f:
    for line in f:
        if not line.strip():
            continue
        parts = line.split(None, 1)
        if len(parts) < 2:
            continue
        dev, cont = parts
        cont = cont.strip()
        if cont:
            devices[dev]['lines'].append(cont)

for dev in devices:
    lines = devices[dev]['lines']
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith('phy') and 'ESSID:' in line:
            ap = parse_own_ap(lines, i)
            if 'ssid' in ap and 'bssid' in ap and 'channel' in ap and 'band' in ap:
                devices[dev]['own_aps'].append(ap)
            i = ap['end_index']
        elif line.startswith('Cell '):
            scan = parse_scan(lines, i)
            if 'bssid' in scan and 'channel' in scan and 'band' in scan and 'signal' in scan:
                devices[dev]['scans'].append(scan)
            i = scan['end_index']
        else:
            i += 1

# Keep only first matching own-AP per device + store noise floor
our_aps = {}
bssid_to_dev = {}
noise_floors = {}
for dev in devices:
    for ap in devices[dev]['own_aps']:
        if ap['ssid'] == ssid:
            if dev not in our_aps:
                our_aps[dev] = ap
                bssid_to_dev[ap['bssid']] = dev
                noise_floors[dev] = ap.get('noise_floor', -95)  # default if missing
                break

if not our_aps:
    print(f"No APs found for SSID: {ssid}")
    sys.exit(0)

bands = {ap['band'] for ap in our_aps.values()}
if len(bands) > 1:
    print("Error: SSID operates on multiple bands across devices.")
    sys.exit(1)
band = next(iter(bands))

# Strongest signal per pair
signals = defaultdict(lambda: defaultdict(lambda: -200))
for dev1 in devices:
    for scan in devices[dev1]['scans']:
        if 'ssid' in scan and scan['ssid'] == ssid:
            bssid = scan['bssid']
            if bssid in bssid_to_dev:
                dev2 = bssid_to_dev[bssid]
                if dev1 != dev2:
                    sig = scan['signal']
                    if sig > signals[dev1][dev2]:
                        signals[dev1][dev2] = sig

incoming = defaultdict(lambda: defaultdict(lambda: -200))
for dev1 in signals:
    for dev2 in signals[dev1]:
        incoming[dev2][dev1] = signals[dev1][dev2]

devs = list(our_aps.keys())

if band == '2.4':
    avail = [1, 6, 11]
else:
    avail = [36, 40, 44, 48, 52, 56, 60, 64, 100, 104, 108, 112, 116, 120, 128, 132, 136, 140, 149, 153, 157, 161, 165]

# Current assignment from data
current_assignment = {}
for dev in devs:
    if dev in our_aps and 'channel' in our_aps[dev]:
        current_assignment[dev] = our_aps[dev]['channel']
    else:
        print(f"Warning: No current channel found for {dev}", file=sys.stderr)

# Compute before stats (with real noise floors)
total_eff_current = compute_total_effective(current_assignment, signals, devs)
per_ch_current = compute_per_channel_stats(current_assignment, signals, devs, avail, noise_floors)
co_signals_current = get_cochannel_signals(current_assignment, signals, devs)
hist_current = compute_histogram(co_signals_current)

# Suggested assignment
num_attempts = 10000
best_total_eff = float('inf')
best_assignment = None

for attempt in range(num_attempts):
    assignment = assign_channels(devs, avail, signals, incoming)
    total_eff = compute_total_effective(assignment, signals, devs)
    if total_eff < best_total_eff:
        best_total_eff = total_eff
        best_assignment = assignment

# Compute after stats (with real noise floors)
per_ch_suggested = compute_per_channel_stats(best_assignment, signals, devs, avail, noise_floors)
co_signals_suggested = get_cochannel_signals(best_assignment, signals, devs)
hist_suggested = compute_histogram(co_signals_suggested)

# Output current (before)
print("\nCurrent (Before) Interference Statistics:")
print(f"Total effective interference: {total_eff_current:.2f} dBm")
print("\nPer-Channel Statistics (per-AP experienced):")
for ch in sorted(avail):
    info = per_ch_current.get(ch, {'effective_dbm': -120.0, 'ap_count': 0,
                                   'average_per_ap_dbm': None, 'median_per_ap_dbm': None,
                                   'worst_per_ap_dbm': None, 'pair_count': 0})
    print(f"Channel {ch}:")
    print(f"  Channel-wide effective dBm: {info['effective_dbm']:.2f} dBm")
    print(f"  APs assigned: {info['ap_count']}")
    if info['ap_count'] > 0 and info['average_per_ap_dbm'] is not None:
        print(f"  Average interference per AP: {info['average_per_ap_dbm']:.2f} dBm")
        print(f"  Median interference per AP: {info['median_per_ap_dbm']:.2f} dBm")
        print(f"  Worst interference per AP: {info['worst_per_ap_dbm']:.2f} dBm")
    else:
        print("  No measurable interference on this channel")
    print()

print("\nHistogram of individual co-channel signal strengths (before):")
for bin_name, count in hist_current.items():
    print(f"{bin_name}: {count}")

# Output suggested (after)
print(f"\nChannel Allocation Plan for SSID: {ssid} (Band: {band} GHz)")
print("Device\t\tSuggested Channel")
for dev in sorted(best_assignment):
    print(f"{dev}\t\t{best_assignment[dev]}")

print(f"\nSuggested (After) Interference Statistics:")
print(f"Total effective interference: {best_total_eff:.2f} dBm")
print("\nPer-Channel Statistics (per-AP experienced):")
for ch in sorted(avail):
    info = per_ch_suggested.get(ch, {'effective_dbm': -120.0, 'ap_count': 0,
                                     'average_per_ap_dbm': None, 'median_per_ap_dbm': None,
                                     'worst_per_ap_dbm': None, 'pair_count': 0})
    print(f"Channel {ch}:")
    print(f"  Channel-wide effective dBm: {info['effective_dbm']:.2f} dBm")
    print(f"  APs assigned: {info['ap_count']}")
    if info['ap_count'] > 0 and info['average_per_ap_dbm'] is not None:
        print(f"  Average interference per AP: {info['average_per_ap_dbm']:.2f} dBm")
        print(f"  Median interference per AP: {info['median_per_ap_dbm']:.2f} dBm")
        print(f"  Worst interference per AP: {info['worst_per_ap_dbm']:.2f} dBm")
    else:
        print("  No measurable interference on this channel")
    print()

print("\nHistogram of individual co-channel signal strengths (after):")
for bin_name, count in hist_suggested.items():
    print(f"{bin_name}: {count}")

# Update CSV if requested
if args.update:
    update_csv(args.update, best_assignment, band, verbose=True)
