#!/usr/bin/python3
"""
WiFi Scan Gatherer - Collects iwinfo + iwinfo scan data from multiple APs via SSH (sequential)

Purpose:
  Reads a CSV (default apuse.csv), extracts IP addresses from a specified column,
  SSHes to each AP sequentially, runs 'iwinfo' to capture device status,
  identifies interfaces broadcasting the target SSID, then runs
  'iwinfo <interface> scan' on each (or a specific --radio if provided),
  prefixes every line with the hostname, and collects output.

Usage:
  python3 gather-wifi-scans.py --ssid <SSID> [options]

Examples:
  # Default: scan all matching phy's, output to stdout
  python3 gather-wifi-scans.py --ssid scale-public-slow

  # Save to file, verbose progress, 2-second delay between hosts
  python3 gather-wifi-scans.py --ssid scale-public-fast -o scans-fast.txt -v -d 2

  # Specific radio, longer command timeout
  python3 gather-wifi-scans.py --ssid scale-public-slow --radio phy0-ap0 --timeout 120

  # Filter input lines (regex on whole CSV line)
  python3 gather-wifi-scans.py --ssid scale-public-slow --filter 'Rm10[1-9]-' -v

  # Use different IP column (by name or number)
  python3 gather-wifi-scans.py --ssid scale-public-slow -c ipv4
  python3 gather-wifi-scans.py --ssid scale-public-slow -c 4

Sample output lines (both iwinfo status and scans included):
  Rm101-a phy0-ap0 ESSID: "scale-public-slow"
  Rm101-a          Access Point: 20:05:b6:ff:81:24
  Rm101-a Cell 01 - Address: xx:xx:xx:xx:xx:xx
  ...

Full help: python3 gather-wifi-scans.py --help
"""

import sys
import re
import argparse
import csv
import paramiko
import socket
import time

def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Gather iwinfo + iwinfo scan data from multiple APs via SSH (sequential)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__.split("Sample output lines (both")[0].strip()
    )
    parser.add_argument("--ssid", required=True,
                        help="SSID to look for in iwinfo output (used to find relevant interfaces)")
    parser.add_argument("-i", "--input", default="apuse.csv",
                        help="Input CSV file (default: apuse.csv)")
    parser.add_argument("-o", "--output", default=None,
                        help="Output file for scan results (default: stdout)")
    parser.add_argument("-c", "--ip-column", default="3",
                        help="IP address column: number (1-based) or header name (default: 3)")
    parser.add_argument("--filter", default=None,
                        help="Regex to filter CSV lines before processing (applied to whole line)")
    parser.add_argument("--radio", default=None,
                        help="Specific radio to scan (e.g. phy0-ap0). If omitted, scans all matching phy*")
    parser.add_argument("--timeout", type=int, default=60,
                        help="Max seconds for each SSH command to run (default: 60)")
    parser.add_argument("--connect-timeout", type=float, default=5.0,
                        help="Max seconds to wait for SSH connection (default: 5.0)")
    parser.add_argument("-d", "--delay", type=float, default=0.0,
                        help="Seconds to wait between hosts (default: 0)")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Print detailed progress messages to stderr (basic progress is always shown)")

    return parser.parse_args()

def get_ip_column_index(csv_path, ip_col_spec):
    with open(csv_path, 'r', newline='') as f:
        reader = csv.reader(f)
        header = next(reader, None)
        if header is None:
            raise ValueError("CSV file is empty")

        try:
            col_num = int(ip_col_spec)
            if col_num < 1 or col_num > len(header):
                raise ValueError(f"Column number {col_num} out of range (1-{len(header)})")
            return col_num - 1  # 0-based
        except ValueError:
            try:
                idx = header.index(ip_col_spec)
                return idx
            except ValueError:
                raise ValueError(f"Column '{ip_col_spec}' not found in CSV header: {header}")

def get_servers(csv_path, ip_col_idx, line_filter=None):
    servers = []
    with open(csv_path, 'r', newline='') as f:
        reader = csv.reader(f)
        next(reader, None)  # skip header
        for row in reader:
            if len(row) <= ip_col_idx:
                continue
            line = ','.join(row)
            if line_filter and not re.search(line_filter, line):
                continue
            ip = row[ip_col_idx].strip()
            if ip:
                servers.append(ip)
    return servers

def ssh_scan_host(host, ssid, radio=None, connect_timeout=5.0, cmd_timeout=60,
                  username="root", verbose=False):
    """SSH to host, capture iwinfo + scans, return output lines + error (if any)"""
    output_lines = []
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        if verbose:
            print(f"Connecting to {host}...", file=sys.stderr)
        client.connect(
            host,
            username=username,
            allow_agent=True,
            look_for_keys=True,
            timeout=connect_timeout,
            banner_timeout=connect_timeout,
            auth_timeout=connect_timeout
        )

        # Always capture full plain iwinfo output first
        if verbose:
            print(f"  Capturing plain iwinfo output...", file=sys.stderr)
        stdin, stdout, stderr = client.exec_command("iwinfo", timeout=cmd_timeout)
        iwinfo_out = stdout.read().decode(errors='ignore')
        for line in iwinfo_out.splitlines():
            output_lines.append(f"{host} {line.rstrip()}")

        stderr_out = stderr.read().decode(errors='ignore')
        if stderr_out:
            output_lines.append(f"{host} ERROR (iwinfo): {stderr_out.rstrip()}")

        # Determine interfaces to scan
        interfaces = []
        if radio is None:
            for line in iwinfo_out.splitlines():
                if ssid in line and 'ESSID:' in line:
                    m = re.match(r'(\S+)\s+ESSID:', line.strip())
                    if m:
                        interfaces.append(m.group(1))
            if not interfaces:
                raise RuntimeError(f"No interfaces found broadcasting '{ssid}'")
        else:
            interfaces = [radio]

        if verbose:
            print(f"  Starting scan on {host} ({len(interfaces)} interface(s))", file=sys.stderr)

        for iface in interfaces:
            cmd = f"iwinfo {iface} scan 2>&1"
            if verbose:
                print(f"    Scanning {iface}...", file=sys.stderr)
            stdin, stdout, stderr = client.exec_command(cmd, timeout=cmd_timeout)
            for raw_line in iter(stdout.readline, b''):
                line = raw_line.decode(errors='ignore')
                output_lines.append(f"{host} {line.rstrip()}")
            stderr_out = stderr.read().decode(errors='ignore')
            if stderr_out:
                output_lines.append(f"{host} ERROR ({iface} scan): {stderr_out.rstrip()}")

        return output_lines, None

    except socket.timeout:
        return [], f"Connection timeout after {connect_timeout}s"
    except paramiko.AuthenticationException:
        return [], "Authentication failed (check keys)"
    except paramiko.SSHException as e:
        if 'timeout' in str(e).lower():
            return [], f"Command execution timeout after {cmd_timeout}s"
        else:
            return [], f"SSH error: {str(e)}"
    except RuntimeError as e:
        return [], str(e)
    except Exception as e:
        return [], f"Unexpected error: {str(e)}"
    finally:
        client.close()

def main():
    args = parse_arguments()

    # Get IP column index
    try:
        ip_col_idx = get_ip_column_index(args.input, args.ip_column)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    # Load and filter servers
    servers = get_servers(args.input, ip_col_idx, args.filter)
    if not servers:
        print("No servers found after filtering.", file=sys.stderr)
        sys.exit(1)

    print(f"Scanning {len(servers)} hosts for SSID '{args.ssid}' sequentially", file=sys.stderr)

    all_output = []
    failures = []

    for i, host in enumerate(servers, 1):
        print(f"Processing {host}... ({i}/{len(servers)})", file=sys.stderr)  # always print basic progress

        output, err = ssh_scan_host(
            host=host,
            ssid=args.ssid,
            radio=args.radio,
            connect_timeout=args.connect_timeout,
            cmd_timeout=args.timeout,
            verbose=args.verbose
        )

        all_output.extend(output)

        if err:
            failures.append((host, err))
            if args.verbose:
                print(f"  → {err}", file=sys.stderr)
        else:
            if args.verbose:
                print(f"  → Completed", file=sys.stderr)

        # Delay if requested
        if args.delay > 0 and i < len(servers):
            if args.verbose:
                print(f"  Waiting {args.delay}s...", file=sys.stderr)
            time.sleep(args.delay)

    # Write output
    output_stream = open(args.output, 'w') if args.output else sys.stdout
    try:
        for line in all_output:
            print(line, file=output_stream)
    finally:
        if args.output:
            output_stream.close()
            print(f"Scan results saved to: {args.output}", file=sys.stderr)

    # Report failures
    if failures:
        print("\nHosts that timed out or failed:", file=sys.stderr)
        for host, reason in failures:
            print(f"  {host}: {reason}", file=sys.stderr)
        print(f"\nTotal failures: {len(failures)}/{len(servers)}", file=sys.stderr)

if __name__ == "__main__":
    main()
