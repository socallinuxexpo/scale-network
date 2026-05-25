# Deployment and Release Procedures

## Overview

This document outlines the deployment and release procedures for the SCaLE network infrastructure. All deployments follow a structured workflow to ensure reliability and traceability.

## Deployment Types

| Type | Description | When Used |
|------|-------------|-----------|
| Configuration Push | Update switch/router configs | During conference prep |
| System Rebuild | Rebuild NixOS systems | Major changes or hardware replacement |
| OpenWRT Flash | Update AP firmware | New OpenWRT release or hardware |
| Full Deployment | Complete infrastructure refresh | Pre-conference setup |

## Pre-Deployment Checklist

Before any deployment, complete these steps:

- [ ] Review all changes in the pull request
- [ ] Verify all tests pass in CI
- [ ] Confirm backup of current configurations exists
- [ ] Notify team members of planned deployment
- [ ] Verify access to target equipment
- [ ] Review rollback procedure

## Configuration Deployment

### Switch Configuration Updates

1. **Generate Configurations**
   
   ```bash
   cd switch-configuration
   make
   ```

2. **Review Generated Configs**
   
   ```bash
   # Review changes
   git diff output/
   
   # Check specific switch config
   cat output/switch_configurations/<switch_name>.conf
   ```

3. **Backup Current Configs**
   
   ```bash
   # Copy current configs from switches
   # See switch-configuration/README.md for details
   ```

4. **Deploy to Switches**
   
   ```bash
   # Deploy to single switch
   scripts/switch_config_loader <switch_name>
   
   # Deploy to all switches
   scripts/switch_config_loader
   ```

5. **Verify Deployment**
   
   ```bash
   # Connect to switch and verify
   ssh <switch_name> "show configuration | display json"
   ```

### NixOS System Deployment

1. **Build Configuration**
   
   ```bash
   # Build the system configuration
   nix build .#nixosConfigurations.<host>.<system>.config.system.build.toplevel
   ```

2. **Deploy via NixOS Rebuild**
   
   ```bash
   # On the target system
   sudo nixos-rebuild switch --flake .#<hostname>
   
   # Or build VM for testing first
   nix build .#nixosConfigurations.<host>.<system>.config.system.build.vm
   ./result/bin/run-nixos-vm
   ```

3. **Verify Deployment**
   
   ```bash
   # Check system is running correctly
   nixos-rebuild test --flake .#<hostname>
   
   # Check critical services
   systemctl status networking
   systemctl status kea-dhcp4
   systemctl status frr
   ```

## OpenWRT Deployment

### Building OpenWRT Images

See [openwrt/docs/BUILD.md](../openwrt/docs/BUILD.md) for detailed build instructions.

```bash
# Enter development environment
nix develop

# Build OpenWRT
cd openwrt
make

# Output will be in openwrt/bin/targets/
```

### Flashing Access Points

#### Using Massflash

For批量 flashing multiple APs:

```bash
# Create massflash image
nix run .#massflash-pi.default.out

# Or for x86
nix run .#massflash-x86.default.out
```

#### Using Individual Flash

1. **Prepare Image**
   
   ```bash
   # Copy image to accessible location
   cp openwrt/bin/targets/.../openwrt-*.img.gz /tmp/
   ```

2. **Flash via TFTP**
   
   ```bash
   # Set AP to TFTP recovery mode
   # Connect serial console
   # Run flashing procedure per hardware model
   ```

3. **Verify Flash**
   
   ```bash
   # SSH to AP after reboot
   ssh root@10.x.x.x
   cat /etc/os-version
   ```

### Using /tux Command (PR Flash)

For flashing APs from pull requests:

1. Generate wormhole link:
   
   ```bash
   wormhole send /path/to/openwrt-image.img
   # Note the code (e.g., 8-amusement-drumbeat)
   ```

2. Post in PR:
   
   ```
   /tux openwrt flash 8-amusement-drumbeat
   ```

3. CI will flash the device and report status

## Release Procedures

### Release Checklist

- [ ] Update version numbers in relevant files
- [ ] Run full test suite
- [ ] Generate release notes
- [ ] Create GitHub release
- [ ] Tag repository
- [ ] Update documentation

### Creating a Release

1. **Update Version**
   
   ```bash
   # Edit RELEASE.md
   vim RELEASE.md
   
   # Update facts/aps/*-openwrt-show.yaml
   ```

2. **Run Tests**
   
   ```bash
   nix run .#verify-scale-tests
   nix run .#verify-scale-systems
   ```

3. **Create GitHub Release**
   
   ```bash
   # Create tag
   git tag -a release-x.y.z -m "Release x.y.z"
   
   # Push tag
   git push origin release-x.y.z
   ```

4. **Verify CI Passes**
   
   Monitor GitHub Actions to confirm all workflows pass.

## Rollback Procedures

### Switch Rollback

```bash
# Deploy previous configuration
cd switch-configuration

# Restore from backup
cp backups/<date>/<switch_name>.conf output/switch_configurations/
scripts/switch_config_loader <switch_name>
```

### NixOS Rollback

```bash
# Rollback to previous generation
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration /nix/var/nix/profiles/system/profile

# Or use nixos-rebuild
sudo nixos-rebuild rollback --flake .#<hostname>
```

### OpenWRT Rollback

```bash
# Flash previous image
# Use TFTP recovery with previous image
# See openwrt/docs/AUTOFLASH.md
```

## Emergency Procedures

### Network Outage Response

1. **Assess Situation**
   - Identify affected systems
   - Determine scope of outage
   - Check recent changes

2. **Communication**
   - Notify team via IRC/mailing list
   - Update status if appropriate

3. **Recovery**
   - Implement fix or rollback
   - Verify services restored
   - Document incident

### Equipment Failure

1. **Identify Failed Equipment**
   - Check monitoring alerts
   - Verify physical status

2. **Replace Hardware**
   - Swap with spare equipment
   - Apply appropriate configuration

3. **Document**
   - Record incident
   - Plan for permanent fix

## Post-Deployment Verification

After any deployment, verify:

- [ ] Network connectivity
- [ ] DHCP functioning
- [ ] DNS resolution
- [ ] Wireless access points online
- [ ] Monitoring showing healthy status
- [ ] Team members can access equipment

## Documentation Updates

After deployment, update:

- [ ] Network maps if topology changed
- [ ] Configuration documentation
- [ ] Release notes
- [ ] Pre-conference checklist for any changes
