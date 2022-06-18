# Massflash

## Overview

Leverages `openwrt/scripts/massflash` and `kea` to provide a way to flash openwrt APs with new images prior to the scale conference

## Prereqs

Place the following files in `openwrt/scripts/massflash`:

1. `flash.bin` - An openwrt img for the sysupgrade.bin thats produced during a build. Currently the massflash is unable to distinguish
   between multiple boards/architectures. 
2. `passwords.txt` - A file that contains the ssh user password credentials. If you want it to try multiple then add one per line.
3. `id_priv` - The private key for the ssh user credentials. This will probably be the main way to get in going forward. Might have to
   support multiple keys in the future.
4. `kea.tmpl` - Copy template to `kea.json` and update values accordingly based on your interfaces and file paths. Leverage tagged vlan `503`. Example values:

```
<INTERFACE> = enp5s0.503
<LIBRUNSCRIPT> = /nix/store/5qr44w8fm0vf5whsa683444wv4q0bwns-kea-2.0.2/lib/kea/hooks/libdhcp_run_script.so
<MASSFLASH> = /home/user/scale-network/scripts/massflash/massflash
```

Outside of the necessary files:

5. Juniper switch needs to be setup for tagged vlan 503 on all ports
6. Setup interface 503 vlan for dhcp on the massflash host:

```
sudo ip link add link enp5s0 name enp5s0.503 type vlan id 503
sudo ip addr add 192.168.254.1/22 dev enp5s0.503
sudo ip link set up enp5s0.503
```
> if you include a subnet mask during ip addr add then it wont default to 32
> otherwise you need to add the route explicitly:
> "ip route add 192.168.254.0/22 dev enp5s0.503"
> 
> if need to del route: "ip route del 192.168.254.0/24 dev enp5s0.503"

## Start up

```
nix-shell
sudo env "PATH=$PATH" kea-dhcp4 -c ./openwrt/scripts/massflash/kea.json
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

- Hardcoded paths. These will get cleaned up in followups to the repo. Right now they will be left in for as references.
