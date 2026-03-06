# OpenWRT Management

## Overview

This document covers the management of OpenWRT-based wireless access points (APs) used in the SCaLE conference network. OpenWRT provides the firmware for consumer and enterprise-grade APs.

## Supported Hardware

### Currently Supported

| Model | Architecture | Notes |
|-------|--------------|-------|
| Netgear WNDR3700 | ath79 | Dual band, older hardware |
| Netgear WNDR3800 | ath79 | Dual band, more memory |
| Netgear WNDR3800CH | ath79 | Consumer variant |
| Xiaomi Redmi AX6000 | mt798x | WiFi 6, MediaTek |
| Xiaomi AX9000 | mt798x | WiFi 6E, MediaTek |

### Build Targets

- **ath79**: Legacy Atheros devices
- **mt7622**: MediaTek MT7622 (ARM Cortex-A53)
- **mt7986**: MediaTek MT7986 (ARM Cortex-A53)

## OpenWRT Configuration

### Configuration Files

AP configurations are defined in:

- `nix/mixos-configurations/ap/` - NixOS configurations
- `facts/aps/` - AP inventory and facts
- `openwrt/files-*/` - Overlay files

### Key Configuration Options

```nix
# nix/mixos-configurations/ap/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ../options.nix ];
  
  # Network settings
  networking.wireless.radio0 = {
    channel = 36;
    band = "5g";
    mode = "ap";
  };
  
  # Hostname
  networking.hostName = "ap01-expo";
}
```

## Building OpenWRT

### Prerequisites

```bash
# Enter development environment
nix develop

# Install additional dependencies (if needed)
sudo apt-get install subversion gawk flex patchelf
```

### Build Process

1. **Configure Build**
   
   ```bash
   cd openwrt
   make menuconfig
   ```
   
   Select appropriate target and packages.

2. **Build Image**
   
   ```bash
   # Build for specific target
   make target/ath79/generic
    
   # Or build specific profile
   make PROFILE=netgear_wndr3800ch
   ```

3. **Output**
   
   Built images are in:
   ```
   openwrt/bin/targets/<target>/<subtarget>/
   ```

### Custom Packages

Add packages in `openwrt/package/`:

```bash
# Add custom package
mkdir -p package/custom-package
# Create Makefile and source files
make V=s
```

## Flashing Access Points

### Methods

| Method | Use Case | Prerequisites |
|--------|----------|---------------|
| TFTP | Recovery, initial flash | Serial console |
| Web UI | Standard upgrade | Working firmware |
| SSH | Batch operations | SSH access |
| Massflash | Multiple units | SD card reader |

### TFTP Recovery

1. **Connect Serial Console**
   
   ```bash
   # Using serial adapter
   screen /dev/ttyUSB0 115200
   ```

2. **Enter Recovery Mode**
   
   - Power on device
   - Press reset button during boot
   - Device enters TFTP mode

3. **Flash Image**
   
   ```bash
   # Start TFTP server
   atftpd --daemon --port 69 /tftpboot/
   
   # Copy image
   cp openwrt.bin /tftpboot/
   ```

### Web UI Flash

1. Access AP web interface (default: 192.168.1.1)
2. Navigate to System > Backup/Flash Firmware
3. Select firmware file
4. Click "Flash Image"

### SSH Flash

```bash
# Upload firmware
scp openwrt.bin root@10.x.x.x:/tmp/

# SSH into AP
ssh root@10.x.x.x

# Flash
sysupgrade -n /tmp/openwrt.bin
```

### Massflash

For批量 flashing multiple APs:

```bash
# Create massflash image
nix build .#massflash-pi.default.out

# Write to SD card
dd if=result/sd-image.img of=/dev/sdX bs=1M

# Boot Pi connected to AP Ethernet
# AP will automatically flash
```

## AP Configuration Management

### Configuration Files

Per-AP configurations:

```bash
# View AP configuration
cat facts/aps/mt798x-openwrt-show.yaml
```

YAML structure:

```yaml
aps:
  ap01-expo:
    mac: "00:11:22:33:44:55"
    ip: "10.20.1.101"
    scale: 22
    type: mt7986a
    location: "Expo Hall A"
```

### Applying Configurations

1. **Generate Configurations**
   
   ```bash
   nix build .#mixosConfigurations.mt798x.<ap-name>.config.system.build.mixos
   ```

2. **Deploy to AP**
   
   ```bash
   scp result/etc/*.ipk root@10.x.x.x:/tmp/
   ssh root@10.x.x.x "opkg install /tmp/*.ipk"
   ```

## Wireless Configuration

### Channel Planning

Conference wireless uses channel planning to minimize interference:

```bash
# 5GHz channels (preferred)
# UNII-1: 36, 40, 44, 48
# UNII-2: 52, 56, 60, 64 (requires DFS)
# UNII-3: 149, 153, 157, 161, 165

# 2.4GHz channels
# 1, 6, 11 (non-overlapping)
```

### Radio Configuration

Edit in `nix/mixos-configurations/ap/options.nix`:

```nix
wireless.radio0 = {
  channel = 36;
  band = "5g";
  htmode = "HE80";
  txpower = 20;
};
```

### SSID Configuration

```nix
wireless.wireless = {
  interfaces = [
    {
      ssid = "SCaLE22x";
      mode = "ap";
      encryption = "sae";
      key = "conference-password";
    }
  ];
};
```

## Monitoring

### Health Checks

```bash
# SSH to AP
ssh root@10.x.x.x

# Check uptime
uptime

# Check clients
iw dev wlan0 station dump

# Check traffic
iftop

# Check logs
logread -f
```

### Remote Monitoring

Use the monitoring infrastructure:

- **Prometheus**: Metrics collection
- **apinger**: Uptime monitoring
- **Nagios**: Alerting

## Troubleshooting

### Common Issues

#### AP Not Responding

1. Check power
2. Check network cable
3. Try serial console
4. TFTP recovery

#### WiFi Not Broadcasting

```bash
# Check radio status
wifi status

# Check config
cat /etc/config/wireless

# Restart wireless
wifi
```

#### Client Connection Issues

```bash
# Check client associations
iw dev wlan0 station dump

# Check signal strength
iw dev wlan0 station get <client-mac>

# Check for interference
iw dev wlan0 survey dump
```

## Maintenance

### Regular Tasks

- [ ] Firmware updates (before conference)
- [ ] Configuration review
- [ ] Password rotation
- [ ] Log review
- [ ] Backup configurations

### Pre-Conference Checklist

- [ ] Verify all APs online
- [ ] Check channel assignments
- [ ] Verify client capacity
- [ ] Test roaming
- [ ] Update firmware

## Security

### Access Control

- SSH key-based authentication only
- No default passwords
- Root access restricted

### Wireless Security

- WPA3-SAE (preferred)
- WPA2-PSK (fallback)
- Unique passwords per SSID

## Documentation Links

- [openwrt/docs/BUILD.md](../openwrt/docs/BUILD.md) - Build instructions
- [openwrt/docs/AUTOFLASH.md](../openwrt/docs/AUTOFLASH.md) - Auto-flashing
- [openwrt/docs/MASSFLASH.md](../openwrt/docs/MASSFLASH.md) - Mass flashing
- [openwrt/docs/TROUBLESHOOTING.md](../openwrt/docs/TROUBLESHOOTING.md) - Troubleshooting
