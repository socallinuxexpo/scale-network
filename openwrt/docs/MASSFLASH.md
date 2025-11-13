# Massflash

## Overview

Leverages `openwrt/scripts/massflash` and `kea` to provide a way to flash openwrt APs with new images prior to the
scale conference.

## Prereqs

We have nixos configurations defined for both x86 and Raspberry Pi.

### x86

Build the livecd:

```
$ nix build .#nixosConfigurations.massflashX86.config.system.build.isoImage
```

### Raspberry Pi

Build a Raspberry Pi image:

```
$ nix build .#nixosConfigurations.massflashPi.config.system.build.sdImage
```

## Next steps

Connect the flashing interface to the bridge:

```
~$ sudo addtobr enp0s26u1u2
```

Setup wifi:

```
~$ sudo systemctl start wpa_supplicant
```

Add wireless config:

```
wpa_passphrase <SSID> <password> | sudo tee /etc/wpa_supplicant.conf
```

Trigger a reload:

```
~$ wpa_cli reconfigure
```

Create the directory layout expected for flashing. (You might want to run
this on your personal machine and copy this to the massflash machine via USB):

```
$ nix run .#massflash-generate-persist -- [id_priv] /persist/massflash
```

Where `id_priv` is a path to the private key used to log into the APs.

## Known issues

- DHCP client requests are duplicated on AP startup. You may see this in the logs, but there is no issue with this happening.
  In the future it might be a good idea to investigate to see why the interfaces are yoyo'ing at boot and sending multiple requests.
- `massflash` assumes it's being called by kea script plugin. The following arg is passed to the `massflash` script and environment variables
  are assumed to be present:

```
arg: lease4_renew
env: QUERY4_TYPE, LEASE4_ADDRESS, LEASE4_HWADDR
```

## Running oneoff

One off to run the `massflash`:

```
export QUERY4_TYPE=DHCPREQUEST
export LEASE4_ADDRESS=<IP>
massflash lease4_renew
```
