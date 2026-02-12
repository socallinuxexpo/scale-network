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
> ls nix/package-sets/top-level | grep verify
verify-scale-network
verify-scale-nixos-tests
verify-scale-systems
verify-scale-tests
```

`verify-scale-network` builds all the packages we add to the `scale-network` scope.
`verify-scale-nixos-tests` builds and runs all the NixOS VM tests.
`verify-scale-systems` builds all the NixOS and MixOS configurations.
`verify-scale-tests` builds a set of checks that verify the correctness of the repository.

You can run any of these checks by running `nix run .#<verify-thing>`.
This will evaluate and build all the derivations therein in parallel.
If you run the command again without changing anything, it will evaluation all the derivations but will not rebuild as the derivations already exist in your Nix store.
To rebuild all the derivations for a given verification derivation run `nix run .#<verify-thing> -- --rebuild`.

_Note_: These will only build/run packages compatible with your host system.

NixOS VM tests can be accessed directly through the `legacyPackagesTests` flake output like so:

```shell-session
nix build .#legacyPackagesTests.<system>.scale-nixos-tests.<test>
```

Checks that verify the correctness of the repository can be accessed directly through the `legacyPackagesTests` flake output like so:

```shell-session
nix build .#legacyPackagesTests.<system>.scale-tests.<test>
```
