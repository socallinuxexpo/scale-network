# ar71xx

## Flashing

### Prereq

1. Connect an ethernet cable from your workstation's ethernet port to one
   of the LAN (not WAN) ports on the router.
2. Set  static ip in `192.168.1.1/24` on your workstations ethernet port.
3. Create symlink to `.img` due to tftp being picky about long filenames:

```sh
cd openwrt
ln -s <locationof>.img factory.img
```

4. Start the AP up while holding down the reset button. Once the power lede is
   flashing green you can let go of the reset button.

The AP is now ready to accept a new `.img`, continue with either method below:

### Auto TFTP (Legacy)

Use the `flash` script:

```sh
cd openwrt
./flash
```
> This will also update the .csv with the mac address

### Manual TFTP

Manual interaction with `tftp` client:

```sh
ln -s <locationof.img> factory.img
tftp 192.168.1.1
> bin
> put factory.img
> quit
```

### In-place

Assuming Openwrt is already installed:

```sh
scp <sysupgrade.bin> root@<AP IP>:/tmp/
ssh root@<AP IP>
cd /tmp
sysupgrade -v <sysupgrade.bin> # Wait for the AP to load and reboot
```

Once it comes back online `ssh` back in an confirm the version

```sh
ssh root@<AP IP>
cat /etc/os-release
```
