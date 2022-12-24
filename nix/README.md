# Nix and NixOS configuration

## Local VMs

To build and run the `loghost` machine via nix on NixOS:

```
nix build ".#nixosConfigurations.x86_64-linux.loghost.config.system.build.vm"
./result/bin/run-nixos-vm
```
