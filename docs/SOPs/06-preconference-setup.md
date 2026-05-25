# Pre-Conference Setup

## Overview

This document outlines the pre-conference setup procedures for the SCaLE network infrastructure. These tasks are performed before each SCaLE event to ensure the network is ready for the conference.

## Timeline

### 3-6 Months Before

- [ ] Review and update network team personnel
- [ ] Inventory all equipment
- [ ] Order replacement hardware
- [ ] Review venue network requirements
- [ ] Update network topology maps

### 2-3 Months Before

- [ ] Begin switch configuration updates
- [ ] Update AP firmware
- [ ] Review and update documentation
- [ ] Test new hardware in lab

### 1 Month Before

- [ ] Finalize switch configurations
- [ ] Complete AP configurations
- [ ] Run full test suite
- [ ] Generate network maps
- [ ] Prepare equipment for transport

### 1 Week Before

- [ ] Pack equipment
- [ ] Verify inventory for transport
- [ ] Print labels and documentation
- [ ] Confirm venue access

### Day Before/Day Of

- [ ] Unpack and inventory equipment
- [ ] Set up core network
- [ ] Configure switches
- [ ] Deploy APs
- [ ] Verify network connectivity

## Detailed Procedures

### Inventory and Equipment Preparation

#### Equipment Inventory

```bash
# Review current inventory
cat facts/pi/pis.csv
cat facts/aps/aps.csv
cat facts/servers/serverlist.csv
```

#### Hardware Check

- [ ] Test all switches
- [ ] Test all access points
- [ ] Verify power supplies
- [ ] Check serial cables
- [ ] Verify SFP modules

### Switch Configuration

#### Update Switch Types

```bash
# Edit switch types file
vim switch-configuration/config/switchtypes
```

Format:
```
Name    Number  MgtVLAN IPv6    Type
conf214a   214     10  2001:db8::1  Room
```

#### Update VLANs

```bash
# Edit VLAN configuration
vim switch-configuration/config/vlans.d/<venue>
```

Format:
```
VLAN <name> <id> <prefix6> <prefix4> <comment>
VVRNG <template> <range> <prefix6> <prefix4> <comment>
```

#### Build Configurations

```bash
cd switch-configuration
make
```

This generates:
- Switch configurations in `output/switch_configurations/`
- Maps in `output/maps/`
- Labels in `output/labels/`

#### Review Generated Configs

```bash
# Review diff
git diff output/

# Check specific switch
cat output/switch_configurations/<name>.conf
```

### Access Point Configuration

#### Update AP Inventory

```bash
# Edit AP facts
vim facts/aps/mt798x-openwrt-show.yaml
vim facts/aps/ath79-openwrt-show.yaml
```

#### Update AP Images

```bash
# Build new OpenWRT images
nix develop
cd openwrt
make

# Verify builds
ls -la bin/targets/
```

#### Configure SSIDs

```bash
# Edit SSID configuration
# In nix/mixos-configurations/ap/options.nix
```

Update:
- SSID names (e.g., "SCaLE22x")
- Channel assignments
- Encryption settings

### Network Services Configuration

#### Update DHCP Ranges

Edit in `nix/nixos-modules/services/kea-master.nix`:

```nix
services.kea.dhcpv4 = {
  subnets = [
    {
      subnet = "10.20.0.0/16";
      pools = [
        { pool = "10.20.100.0 - 10.20.199.255"; }
      ];
    }
  ];
};
```

#### Update DNS Records

Edit in `nix/nixos-modules/services/bind-master.nix`:

```nix
services.bind.zones = {
  "scale.lan" = {
    forward = [
      { name = "gateway"; address = "10.20.0.1"; }
    ];
  };
};
```

#### Update NTP Servers

```nix
# In nix/nixos-modules/time.nix
services.time.timeZone = "America/Los_Angeles";
services.ntp.servers = [
  "0.pool.ntp.org"
  "1.pool.ntp.org"
];
```

### Pre-Conference Checklist Review

Review and complete the checklist at [docs/checklists/PRECONF-CHECKLIST.md](../checklists/PRECONF-CHECKLIST.md):

- [ ] Network team keys updated
- [ ] Admin keys updated
- [ ] Scale version updated in AP configs
- [ ] Root secrets updated
- [ ] WiFi passwords updated

### Testing

#### Run Full Test Suite

```bash
# All tests
nix run .#verify-scale-tests

# System builds
nix run .#verify-scale-systems

# OpenWRT tests
cd tests/unit/openwrt
./test.sh
```

#### Manual Testing

- [ ] Test network connectivity
- [ ] Verify DHCP allocation
- [ ] Test DNS resolution
- [ ] Verify WiFi coverage
- [ ] Test guest network isolation
- [ ] Verify monitoring

### Equipment Transport

#### Packing List

- [ ] Switches (with cables)
- [ ] Access points (with mounts)
- [ ] Patch cables
- [ ] SFP modules
- [ ] Serial cables
- [ ] Power strips
- [ ] Network switches
- [ ] Laptops
- [ ] Label maker
- [ ] Documentation

#### Equipment Labels

Generate labels:

```bash
cd switch-configuration
make labels
```

Label format:
```
conf214a
Room 214
```
