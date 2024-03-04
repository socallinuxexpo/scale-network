# Massflash

## Overview

Leverages `openwrt/scripts/massflash` and `kea` to provide a way to flash openwrt APs with new images prior to the
scale conference

## Prereqs

Build the `massflash` livecd:

```
~$ nix build ".#nixosConfigurations.x86_64-linux.massflash.config.system.build.isoImage"
```

Connect the flashing interface to the bridge:

```
~$ sudo addtobr enp0s26u1u2
```

Setup wifi:

```
~$ sudo systemctl start wpa_supplicant
```

Add wireless config directly to `/var/run/wpa_supplicant/wpa_supplicant.conf`
```
network={
  ssid="<name>"
  psk="<password>"
}
```

Trigger a reloading of config:

```
~$ wpa_cli reconfigure
```

Create the dir layout expected for flashing:

```
~$ mkdir -p /persist/massflash
```

Under `/persist/massflash`:

```
flash_sha # commit hash used to build latest openwrt images
id_priv # private key used to log into the APs
wndr3700-v2/flash.bin # dir for this model of ap and its sysupgrade.bin
wndr3800/flash.bin
wndr3800ch/flash.bin
```

## Known issues

- DHCP client requests are duplicated on AP startup. Its not uncommon to see this in the logs but there is no issue with this happening.
  In the future it might be a good idea to investigate to see why the interfaces are yoyo'ing at boot and sending multiple requests.
- `massflash` assumes its being called by kea script plugin. The following arg is passed to the `massflash` script and environment variables
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
