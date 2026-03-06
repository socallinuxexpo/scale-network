# Development Setup

## Prerequisites

Before starting development on the SCaLE network project, ensure you have:

- **Operating System**: Linux or macOS (NixOS preferred)
- **Hardware**: x86_64 architecture
- **Network Access**: Ability to clone GitHub repositories
- **Time**: Approximately 30-60 minutes for initial setup

## Required Software

### Core Requirements

1. **Nix Package Manager**
   
   The project uses Nix for development environments and system configurations. Install Nix:
   
   ```bash
   # Install Nix (single-user installation)
   sh <(curl -L https://nixos.org/nix/install) --no-daemon
   
   # Verify installation
   nix --version
   ```

2. **Git**
   
   ```bash
   # Most Linux distributions have git pre-installed
   git --version
   
   # If not installed (Debian/Ubuntu)
   sudo apt-get install git
   
   # If not installed (macOS)
   brew install git
   ```

3. **SSH Keys**
   
   You need SSH keys configured for GitHub access:
   
   ```bash
   # Check for existing keys
   ls -la ~/.ssh/
   
   # Generate new ED25519 key (preferred)
   ssh-keygen -t ed25519 -C "your_email@example.com"
   
   # Add to ssh-agent
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

4. **Wormhole** (for OpenWRT flashing)
   
   ```bash
   # Install via pip
   pip install wormhole
   
   # Or via nix develop shell (included)
   ```

## Repository Setup

### Clone the Repository

```bash
# Clone the scale-network repository
git clone git@github.com:socallinuxexpo/scale-network.git

# Navigate to the project directory
cd scale-network
```

### Enter Development Shell

The project provides a comprehensive development environment via Nix:

```bash
# Enter the development shell
nix develop

# This provides all necessary tools:
# - git, curl, wget
# - perl (with Net modules)
# - python3 (with pytest, pylint, jinja2, pandas)
# - ruby (for serverspec tests)
# - nix, flakes support
# - Various network tools (iperf3, dnsmasq, etc.)
```

The development shell includes:

| Tool | Purpose |
|------|---------|
| git | Version control |
| perl | Switch configuration scripts |
| python3 | Inventory and facts scripts (pytest, pylint, jinja2, pandas) |
| ruby | Serverspec tests |
| nix | Build system |
| iperf3, dnsmasq, tftp-hpa | Network utilities |
| gomplate | Template generation |

## Verify Development Environment

### List Available Commands

After entering the development shell:

```bash
# Show available packages
nix flake show

# List development tools
type -a perl
type -a python3
type -a ruby
```

### Test Basic Functionality

```bash
# Verify nix flake evaluation
nix flake metadata

# List NixOS configurations
nix flake show --json 2>/dev/null | jq '.nixosConfigurations | keys.[]'

# Run a simple build check
nix build .#legacyPackagesTests.x86_64-linux.scale-tests.uniqueness
```

## Project-Specific Setup

### SSH Key Registration

To access network equipment, register your SSH public key:

1. Generate an SSH key (ED25519 preferred)
2. Add the public key to `facts/keys/<username>_id_ed25519.pub`
3. Submit a pull request following the contribution guidelines
4. After merge, a team lead will deploy the key to equipment

### Perl Dependencies (Optional)

For switch configuration scripts, install Perl dependencies:

```bash
# Switch to development directory
cd switch-configuration

# Install Perl modules (if not using nix develop)
# See config/scripts/README.md for requirements
cpan Net::SSH2
cpan Getopt::Long
cpan Pod::Usage
```

### Python Dependencies (Optional)

For inventory and facts scripts:

```bash
# Install Python dependencies (if not using nix develop)
pip3 install -r facts/requirements.txt
```

## Common Development Tasks

### Building System Configurations

```bash
# Build a specific NixOS configuration
nix build .#nixosConfigurations.x86_64-linux.router-conf.config.system.build.vm
./result/bin/run-nixos-vm

# Build all configurations
nix run .#verify-scale-systems
```

### Running Tests

```bash
# Run all tests
nix run .#verify-scale-tests

# Run specific test
nix build .#legacyPackagesTests.x86_64-linux.scale-tests.uniqueness
./result/bin/scale-tests-uniqueness
```

### Building Switch Configurations

```bash
# Generate switch configurations
cd switch-configuration
make

# Output will be in switch-configuration/output/
```

### OpenWRT Development

```bash
# Build OpenWRT (see openwrt/docs/BUILD.md for details)
cd openwrt
make

# Run OpenWRT unit tests
cd tests/unit/openwrt
./test.sh
```

## Editor Configuration

### VS Code

Recommended extensions:

- Nix (Nix language support)
- Perl (language server)
- Python (language server)
- Ruby (language server)

### Emacs

Use nix-mode and/or direnv:

```elisp
;; Add to .emacs
(use-package nix-mode)
(use-package direnv)
```

### Vim/Neovim

```vim
" Recommended plugins
Plug 'LnL7/vim-nix'
```

## Troubleshooting

### Nix Issues

**Problem**: `nix command not found`

```bash
# Source nix in your shell profile
echo 'source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' >> ~/.bashrc
source ~/.bashrc
```

**Problem**: Flakes not enabled

```bash
# Enable flakes
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' > ~/.config/nix/nix.conf
```

### Permission Issues

**Problem**: Cannot access GitHub repository

```bash
# Verify SSH key is added to GitHub
ssh -T git@github.com

# Check SSH agent
ssh-add -l
```

### Build Failures

**Problem**: Build fails with dependency errors

```bash
# Clean and retry
nix clean --all
nix develop
```

## Next Steps

After setting up your development environment:

1. Read [03-Deployment-Release](./03-deployment-release.md) to understand deployment procedures
2. Read [04-Testing](./04-testing.md) to understand testing requirements
3. Review [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution workflow

## Support

- **IRC**: #scale-tech on irc.libera.chat
- **Mailing List**: tech@lists.linuxfests.org
- **GitHub Issues**: Open an issue for bugs or questions
