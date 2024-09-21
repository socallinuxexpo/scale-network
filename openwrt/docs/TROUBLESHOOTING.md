# Troubleshooting

## Identifying successful flashes

WPS Led is setup for the following:

```
even scale conferences - LED ON 
odd scale conferences  - LED OFF
```

## Static IP interface

Dedicated static IP access on AP is possible via WAN(yellow) port and setting a static interface with the following configs:

```
~$ ip link add link enp5s0 name enp5s0.3517 type vlan id 3517
~$ ip addr add 192.168.255.1/24 dev enp5s0.3517
~$ ip link set enp5s0.3517 up
```

> Assumes interface is enp5s0

## Confirming AP OS version

The following should match the commit hash the images were built from and the version of openwrt. Confirm that the build is
latest:

```
~$ cat /etc/scale-release
```
