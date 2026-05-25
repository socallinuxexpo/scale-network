# SCaLE Network Standard Operating Procedures

This directory contains the official Standard Operating Procedures (SOPs) for the SCaLE network project. These documents provide step-by-step instructions and guidelines for all team members.

## Table of Contents

### Getting Started
- [01-Project-Overview](./01-project-overview.md) - Introduction to the SCaLE network infrastructure
- [02-Development-Setup](./02-development-setup.md) - Setting up your development environment

### Core Operations
- [03-Deployment-Release](./03-deployment-release.md) - Deployment and release procedures
- [04-Testing](./04-testing.md) - Testing procedures and validation
- [05-OpenWRT-Management](./05-openwrt-management.md) - Managing OpenWRT access points
- [06-PreConference-Setup](./06-preconference-setup.md) - Pre-conference preparation checklist

### Troubleshooting
- [07-Troubleshooting](./07-troubleshooting.md) - Common issues and resolution procedures

## Quick Reference

### Common Commands

```bash
# Enter development shell
nix develop

# Build all system configurations
nix run .#verify-scale-systems

# Run all tests
nix run .#verify-scale-tests

# Build switch configurations
cd switch-configuration && make

# Run OpenWRT unit tests
cd tests/unit/openwrt && ./test.sh
```

### Key Contacts

- **Tech Mailing List**: https://lists.linuxfests.org/cgi-bin/mailman/listinfo/tech
- **GitHub Repository**: https://github.com/socallinuxexpo/scale-network
- **IRC Channel**: #scale-tech on irc.libera.chat

## Contributing to SOPs

These SOPs are maintained by the SCaLE Tech team. To propose changes:

1. Create a feature branch following the [GitHub Flow](./CONTRIBUTING.md)
2. Make your changes
3. Submit a pull request with `[READY]` prefix
4. Wait for review and approval from a team member

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2024-03-05 | SCaLE Tech Team | Initial SOP documentation |
