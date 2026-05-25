# Troubleshooting

## Overview

This document provides troubleshooting procedures for common issues encountered with the SCaLE network infrastructure. Use this guide to diagnose and resolve problems quickly.

## General Troubleshooting Approach

### Diagnostic Steps

1. **Identify the Problem**
   - What is the expected behavior?
   - What is the actual behavior?
   - When did it start?
   - What changed recently?

2. **Gather Information**
   - Check logs
   - Verify configurations
   - Test connectivity
   - Review recent changes

3. **Isolate the Issue**
   - Divide the network into segments
   - Test each component individually
   - Identify the failing component

4. **Implement Fix**
   - Apply the fix
   - Verify resolution
   - Document the issue

5. **Prevent Recurrence**
   - Update documentation
   - Add monitoring
   - Create test cases

## Network Connectivity Issues

### No Network Connectivity

#### Symptoms
- Cannot ping gateway
- Cannot access internet
- No DHCP lease

#### Diagnostic Steps

1. **Check Physical Layer**
   ```bash
   # Check interface status
   ip link show
   ip addr show
   
   # Check cable
   # Verify link lights on port
   
   # Check switch port
   # Show port status on switch
   ```

2. **Check DHCP**
   ```bash
   # Check DHCP lease
   cat /var/lib/dhcp/dhclient.leases
   
   # Check DHCP server
   systemctl status kea-dhcp4-server
   
   # Check DHCP logs
   journalctl -u kea-dhcp4-server -n 50
   ```

3. **Check Routing**
   ```bash
   # Check routes
   ip route show
   
   # Check default gateway
   ip route default
   
   # Ping gateway
   ping -c 4 10.20.0.1
   ```

#### Common Causes
- Cable disconnected
- Switch port disabled
- DHCP server down
- IP conflict
- VLAN misconfiguration

### Intermittent Connectivity

#### Symptoms
- Connectivity drops periodically
- High latency
- Packet loss

#### Diagnostic Steps

```bash
# Check for packet loss
ping -c 100 <gateway>

# Check interface errors
ip -s link show eth0

# Check switch port errors
# Show interface statistics on switch

# Check for congestion
iftop
nethogs
```

#### Common Causes
- Cable degradation
- Switch port issues
- Network congestion
- Power saving features

## Switch Issues

### Cannot Connect to Switch

#### Symptoms
- SSH connection fails
- Cannot ping switch

#### Diagnostic Steps

1. **Verify Network**
   ```bash
   # Check if switch is reachable
   ping <switch-ip>
   
   # Check ARP
   arp -a | grep <switch-ip>
   ```

2. **Check Physical**
   ```bash
   # Verify management VLAN
   # Check cable
   
   # Check switch status lights
   ```

3. **Serial Console**
   ```bash
   # Connect via serial
   screen /dev/ttyUSB0 9600
   
   # Or via network (if configured)
   telnet <switch-ip>
   ```

#### Solutions
- Reset switch to factory defaults
- Use ZTP (Zero Touch Provisioning)
- Load miniconfig via serial

### Switch Configuration Not Applying

#### Symptoms
- Configuration changed but not active
- Errors in configuration commit

#### Diagnostic Steps

```bash
# Connect to switch
ssh <switch-name>

# Check configuration
show configuration
show | compare

# Check for errors
show system messages
```

#### Solutions
- Review syntax errors
- Commit configuration
- Rollback and fix

## Access Point Issues

### AP Not Broadcasting WiFi

#### Diagnostic Steps

```bash
# SSH to AP
ssh root@10.x.x.x

# Check WiFi status
wifi status
iw dev

# Check config
cat /etc/config/wireless

# Check logs
logread | grep wifi
logread | grep wlan
```

#### Solutions

1. **Radio Disabled**
   ```bash
   # Enable radio
   wifi up
   ```

2. **Configuration Error**
   ```bash
   # Regenerate config
   wifi config
   wifi up
   ```

3. **Driver Issue**
   ```bash
   # Check loaded modules
   lsmod
   
   # Reload driver
   rmmod ath10k_pci
   modprobe ath10k_pci
   ```

### Clients Cannot Connect

#### Diagnostic Steps

```bash
# On AP, check associations
iw dev wlan0 station dump

# Check for auth failures
logread | grep auth

# Check signal strength
iw dev wlan0 station get <client-mac>
```

#### Common Causes
- Wrong password
- Too many clients
- Signal too weak
- Channel congestion
- Client driver issue

### AP Not Getting IP

#### Diagnostic Steps

```bash
# Check AP network config
ip addr show
ip route show

# Check DHCP
logread | grep dhcp

# Check AP can reach DHCP server
ping <dhcp-server>
```

## Server Issues

### Service Not Starting

#### Diagnostic Steps

```bash
# Check service status
systemctl status <service>

# Check logs
journalctl -u <service> -n 100

# Check configuration
<service> -t
```

#### Common Solutions

```bash
# Restart service
systemctl restart <service>

# Enable service
systemctl enable <service>

# Check dependencies
systemctl list-dependencies <service>
```

### High Resource Usage

#### Diagnostic Steps

```bash
# Check CPU
top
htop

# Check memory
free -h

# Check disk
df -h
iostat -x 5

# Check network
iftop
nethogs
```

## DNS Issues

### DNS Resolution Failing

#### Diagnostic Steps

```bash
# Test DNS directly
nslookup <hostname> <dns-server>
dig @<dns-server> <hostname>

# Check DNS service
systemctl status bind

# Check logs
journalctl -u bind -n 50
```

#### Solutions
- Restart DNS service
- Check zone files
- Verify forwarders
- Check firewall rules

## Monitoring Issues

### Prometheus Metrics Missing

#### Diagnostic Steps

```bash
# Check Prometheus
curl http://localhost:9090/api/v1/query?query=up

# Check exporter
curl http://localhost:9100/metrics

# Check service
systemctl status prometheus
```

### apinger Alerts

```bash
# Check apinger logs
journalctl -u apinger

# Check apinger config
cat /etc/apinger.conf

# Manual test
ping -c 5 <target>
```

## Emergency Procedures

### Complete Network Outage

1. **Assess**
   - Identify scope of outage
   - Determine affected systems
   - Check power status

2. **Communication**
   - Notify team
   - Update status page if available

3. **Recovery**
   - Start core services first
   - Work outward
   - Verify each service

4. **Documentation**
   - Document incident
   - Post-mortem analysis

### Equipment Replacement

1. **Document**
   - Photograph current setup
   - Note cable connections

2. **Replace**
   - Swap hardware
   - Connect cables

3. **Configure**
   - Apply configuration
   - Verify functionality

4. **Update**
   - Update inventory
   - Update documentation

## Useful Commands

### Network Testing

```bash
# Connectivity
ping -c 4 <host>
traceroute <host>
mtr <host>

# DNS
nslookup <host>
dig <host>
host <host>

# Port testing
nc -zv <host> <port>
telnet <host> <port>

# Bandwidth
iperf3 -s  # server
iperf3 -c <server>  # client
```

### Log Analysis

```bash
# System logs
journalctl -xe
journalctl -u <service>

# Kernel logs
dmesg
dmesg | tail -50

# Application logs
tail -f /var/log/<logfile>
grep -i error /var/log/<logfile>
```

### Configuration

```bash
# Network
ip addr
ip route
ip link

# Wireless
iw dev
iwlist scanning
iw dev wlan0 station dump

# Connections
ss -tulpn
netstat -tulpn
```

## Getting Help

If you cannot resolve the issue:

1. Check documentation
2. Search existing issues
3. Ask on IRC (#scale-tech on libera.chat)
4. Post to mailing list
5. Create GitHub issue

## Issue Reporting

When reporting issues, include:

- Date and time
- Affected systems
- Symptoms
- Steps to reproduce
- What you tried
- Error messages
- Logs (relevant portions)
