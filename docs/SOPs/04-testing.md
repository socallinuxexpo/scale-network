# Testing Procedures

## Overview

This document describes the testing procedures for the SCaLE network project. Testing is critical to ensure reliability of the conference network and prevent issues during the event.

## Testing Strategy

The project uses a multi-layered testing approach:

| Layer | Type | Tool | When |
|-------|------|------|------|
| Unit Tests | Fast, isolated | shell, perl, python | Every commit |
| Integration Tests | Service-level | Serverspec | Every PR |
| System Tests | Full build | NixOS tests | Before deployment |
| Manual Tests | Human verification | N/A | Pre-conference |

## Running Tests

### Quick Test Run

```bash
# Enter development shell
nix develop

# Run all verification tests
nix run .#verify-scale-tests
```

### Individual Test Suites

#### Unit Tests

The Python tests in `facts/` test the inventory and configuration data:

```bash
# Python uniqueness tests
nix build .#legacyPackagesTests.x86_64-linux.scale-tests.uniqueness
./result/bin/scale-tests-uniqueness

# Python inventory tests
nix build .#legacyPackagesTests.x86_64-linux.scale-tests.inventory
./result/bin/scale-tests-inventory

# Python datasource tests
nix build .#legacyPackagesTests.x86_64-linux.scale-tests.datasource
./result/bin/scale-tests-datasource
```

These tests verify:
- No duplicate IP/MAC addresses
- Valid inventory data formats
- Data source parsing

#### OpenWRT Unit Tests

```bash
cd tests/unit/openwrt
./test.sh
```

This runs:
- UCI configuration tests
- WiFi configuration tests
- DHCP client script tests

#### Serverspec Tests

```bash
cd tests/serverspec

# Install dependencies
bundle install

# Run all serverspec tests
bundle exec rake spec

# Run specific test file
bundle exec rspec spec/openwrt/init_spec.rb

# Run specific test
bundle exec rspec spec/openwrt/init_spec.rb:42
```

### System Verification

```bash
# Build all system configurations
nix run .#verify-scale-systems

# Build all NixOS configurations
nix build .#nixosConfigurations.x86_64-linux.router-conf.config.system.build.vm
./result/bin/run-nixos-vm

# Run NixOS tests
nix run .#verify-scale-nixos-tests
```

## Test Descriptions

### Python Unit Tests

#### Uniqueness Tests

Verifies that network configurations don't have conflicts:

```bash
# Check for duplicate IPs, MACs, VLANs
nix build .#legacyPackagesTests.x86_64-linux.scale-tests.uniqueness
./result/bin/scale-tests-uniqueness
```

Tests:
- No duplicate IP addresses in inventory
- No duplicate MAC addresses
- No duplicate VLAN IDs
- No overlapping IP ranges

#### Inventory Tests

Validates inventory data:

```bash
nix build .#legacyPackagesTests.x86_64-linux.scale-tests.inventory
./result/bin/scale-tests-inventory
```

Tests:
- Server inventory format validation
- PI inventory validation
- AP inventory validation
- Router inventory validation

#### Datasource Tests

Tests data source handling:

```bash
nix build .#legacyPackagesTests.x86_64-linux.scale-tests.datasource
./result/bin/scale-tests-datasource
```

Tests:
- CSV parsing
- YAML parsing
- Directory scanning

### OpenWRT Unit Tests

Located in `tests/unit/openwrt/`:

| Test | Purpose |
|------|---------|
| test.sh | Main test runner |
| uci/ | UCI configuration tests |
| wifi/ | WiFi configuration tests |
| test_udhcpc.sh | DHCP client tests |

```bash
# Run all OpenWRT tests
cd tests/unit/openwrt
./test.sh

# Run specific test
./test.sh uci
./test.sh wifi
```

### Serverspec Integration Tests

Located in `tests/serverspec/`:

#### OpenWRT Tests

```bash
# Test OpenWRT configuration
bundle exec rspec spec/openwrt/init_spec.rb
```

Tests:
- Network interfaces configured
- DHCP server running
- WiFi radios configured
- SSH access enabled

#### Core Services Tests

```bash
# Test core services
bundle exec rspec spec/core/init_spec.rb
```

Tests:
- DNS resolution
- NTP sync
- SSH access
- User accounts

#### Network Tests

```bash
# Test network services
bundle exec rspec spec/shared/
```

Tests:
- DHCP service
- DNS service
- Network connectivity

## Writing Tests

### Python Tests

Tests use pytest. Example:

```python
# facts/test_uniqueness.py
def test_no_duplicate_ips():
    """Verify no duplicate IP addresses"""
    # Implementation
    assert len(ips) == len(set(ips))
```

### Serverspec Tests

Tests use RSpec. Example:

```ruby
# spec/openwrt/init_spec.rb
require 'spec_helper'

describe 'OpenWRT Init' do
  describe file('/etc/config/network') do
    it { should exist }
    it { should be_file }
  end
end
```

### OpenWRT Shell Tests

Use bash with test framework:

```bash
# tests/unit/openwrt/test_udhcpc.sh
#!/bin/sh
test -f /etc/udhcpc.user && pass || fail
```

## CI Integration

Tests run automatically on:

- Every pull request
- Every push to master
- Scheduled runs (nightly)

### GitHub Actions Workflows

Located in `.github/workflows/`:

| Workflow | Trigger | Tests |
|----------|---------|-------|
| ci.yml | Push/PR | Unit tests, lint |
| ci-nixos.yml | Push/PR | NixOS builds |
| openwrt-build.yml | Manual | OpenWRT builds |

### Viewing Results

1. Go to GitHub repository
2. Click on "Actions" tab
3. Select workflow run
4. View job results

## Test Data

### Test Fixtures

Located in `facts/testdata/`:

| File | Purpose |
|------|---------|
| testpis.csv | PI inventory test data |
| testapuse.csv | AP usage test data |
| testserverlist.csv | Server list test data |

### Golden Files

Located in `tests/unit/openwrt/golden/`:

Reference configurations for testing:
- ath79/ - ATH79 router configs
- Various device profiles

## Troubleshooting Test Failures

### Common Issues

#### Nix Build Failures

```bash
# Clean nix cache
nix clean --all

# Retry build
nix develop
```

#### Serverspec Connection Errors

```bash
# Check SSH connectivity
ssh -v target-host

# Verify Ruby version
ruby --version

# Reinstall gems
bundle install
```

#### Test Data Issues

```bash
# Verify test data format
head -n 1 facts/testdata/testpis.csv

# Compare with expected format
diff facts/testdata/testpis.csv facts/pis.csv
```

## Test Coverage Goals

| Component | Target Coverage |
|-----------|----------------|
| Python scripts | 80% |
| Perl scripts | 70% |
| Shell scripts | 60% |
| Serverspec | All critical services |

## Pre-Conference Testing

Before the conference, run:

```bash
# Full test suite
nix run .#verify-scale-tests

# System builds
nix run .#verify-scale-systems

# Manual verification
# - Test network connectivity to all subnets
# - Verify wireless coverage
# - Test monitoring systems
```

## Reporting Test Results

After running tests, document:

- Date and time of tests
- Who ran the tests
- Test results (pass/fail)
- Any failures or issues
- Actions taken to resolve issues
