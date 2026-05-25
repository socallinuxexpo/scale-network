# Project Overview

## Introduction

The SCaLE Network project provides the complete network infrastructure for the Southern California Linux Expo (SCaLE). This includes all wired and wireless networking equipment, configurations, tooling, and automation scripts required to deploy and operate a conference network serving thousands of attendees.

## Scope

This project encompasses:

- **Network Equipment Configuration**: Juniper switches and routers
- **Wireless Access Points**: OpenWRT-based access points
- **Server Infrastructure**: NixOS-based servers and routers
- **Management Tools**: Perl and Python scripts for network operations
- **Testing Infrastructure**: Automated testing with Serverspec and unit tests
- **CI/CD Pipelines**: GitHub Actions and GitLab CI integration

## Architecture Overview

### Network Topology

The SCaLE conference network consists of three main tiers:

1. **Core Layer**: Central routers and switches that manage the backbone
2. **Distribution Layer**: Switches that aggregate access layer connections
3. **Access Layer**: Switches and wireless APs that connect end devices

### Key Components

#### NixOS Configurations

The project uses NixOS for declarative system configuration. All server and router configurations are defined in `nix/nixos-configurations/`:

- `core-conf/` - Core conference network servers
- `core-expo/` - Expo area servers
- `router-border/` - Border routers
- `router-conf/` - Conference area routers
- `router-expo/` - Expo area routers
- `router-scale-br-fmt2/` - Secondary border router
- `dev-server/` - Development server
- `massflash-pi/` - Raspberry Pi massflash image
- `massflash-x86/` - x86 massflash image

#### OpenWRT Access Points

OpenWRT builds for wireless access points are maintained in `openwrt/`. Supported hardware includes:

- **ATH79**: Netgear WNDR3700, WNDR3800, WNDR3800CH
- **MT798X**: MediaTek MT7981X and MT7986X based devices

#### Switch Configuration

Juniper switch configurations are generated from templates in `switch-configuration/`:

- **EX2300**: 24-port and 48-port variants
- **EX4200**: Legacy stackable switches
- **EX4300**: Modern stackable switches
- **SRX300**: Border routers

## Project Structure

```
scale-network/
├── .github/workflows/       # GitHub Actions CI/CD
├── docs/                    # Documentation and SOPs
│   └── checklists/          # Pre-conference checklists
├── facts/                   # Network facts, inventory, keys
│   ├── aps/                 # Access point inventory
│   ├── pi/                  # Raspberry Pi inventory
│   ├── servers/             # Server inventory
│   ├── routers/             # Router inventory
│   ├── keys/                # SSH public keys
│   └── testdata/            # Test data for unit tests
├── nix/                     # NixOS and Nix configurations
│   ├── nixos-configurations/  # Server/router configurations
│   ├── nixos-modules/         # Custom NixOS modules
│   ├── package-sets/           # Custom packages
│   └── mixos-configurations/  # Access point configurations
├── openwrt/                 # OpenWRT builds and configs
├── switch-configuration/    # Switch config generation
├── tests/                  # Test suites
│   ├── serverspec/        # Integration tests
│   └── unit/              # Unit tests
└── .kermit/               # Serial connection scripts
```

## Team Structure

### Roles and Responsibilities

- **Tech Lead**: Overall project coordination, security oversight
- **Network Engineers**: Switch and router configuration
- **Systems Engineers**: NixOS and server management
- **Wireless Engineers**: OpenWRT AP management
- **Developers**: Tooling and automation

### Communication Channels

- **Mailing List**: tech@lists.linuxfests.org
- **IRC**: #scale-tech on irc.libera.chat
- **GitHub Issues**: For bug tracking and feature requests

## Technology Stack

| Component | Technology | Version Notes |
|-----------|------------|---------------|
| System Configuration | NixOS | Latest stable |
| Access Points | OpenWRT | 23.05 branch |
| Switch OS | Junos | Per model in README |
| CI/CD | GitHub Actions | + GitLab mirroring |
| Testing | Serverspec, shell | Latest stable |
| Scripting | Perl, Python, Bash | POSIX compliant |

## Related Documentation

- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
- [CI.md](../CI.md) - CI/CD pipeline documentation
- [MAPS.md](../MAPS.md) - Network maps and diagrams
- [RELEASE.md](../RELEASE.md) - Release procedures
- [switch-configuration/README.md](../switch-configuration/README.md) - Switch management
- [openwrt/README.md](../openwrt/README.md) - OpenWRT documentation

## Key Resources

- **Firmware Downloads**: scale-ztpserver.delong.com/images
- **DHCP Server**: scale-ztpserver.delong.com
- **Network Maps**: MAPS.md
- **Pre-Conference Checklist**: docs/checklists/PRECONF-CHECKLIST.md
