# Nix and NixOS configuration

To see all the development shells, packages, and systems configurations available, run:

```shell-session
> nix flake show
```

## Development

There is a consolidated development shell that provides a bunch of tools for doing development in the repository. To start developing, run:

```shell-session
> nix develop
```

## System Configurations

You can see all the system configurations available by running the following.

```shell-session
> nix flake show --json 2>/dev/null | jq '.nixosConfigurations | keys.[]'
"bootstrap-image"
"core-conf"
"core-expo"
"dev-server"
"massflash-pi"
"massflash-x86"
"router-border"
"router-conf"
"router-expo"
"router-scale-br-fmt2"
```

## Build and Run a VM Locally

Generically, to build a system configuration's VM, run:

```shell-session
> nix build .#nixosConfigurations.<hostPlatform>.<name>.config.system.build.vm
```

To build and run the `loghost` system configuration on an x86_64 Linux host, run:

```shell-session
> nix build .#nixosConfigurations.x86_64-linux.loghost.config.system.build.vm
> ./result/bin/run-nixos-vm
```

## Verification

To see all the checks available, run:

```shell-session
> nix flake show --json 2>/dev/null | jq '.checks | to_entries[0].value | keys.[]'
"core"
"duplicates-facts"
"formatting"
"loghost"
"monitor"
"openwrt-golden"
"perl-switches"
"pytest-facts"
"wasgeht"
```

Some of these are NixOS VM Tests.
To perform a test, run:

```shell-session
> nix build .#checks.<hostPlatform>.<checkName> --print-build-logs
```
