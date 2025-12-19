# ar71xx

## Flashing

### Prereq

1. Connect an ethernet cable from your workstation's ethernet port to one of the LAN (not WAN) ports on the router.
   The router will be on 192.168.1.1.
1. Set static ip in `192.168.1.5/24` on your workstation's ethernet port.
1. Create symlink to `.img` due to tftp being picky about long filenames:

```sh
cd openwrt
ln -s <locationof>.img factory.img
```

4. Hold down the reset button.
   While continuing to hold the reset button, press the power button.
   Initially, the power LED will flash orange.
   Once the power LED is flashing green you can let go of the reset button.

The AP is now ready to accept a new `.img`, continue with either method below:

### Auto TFTP (Legacy)

Use the `flash` script and follow the prompts:

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

1. It will take a while for the flashing to finish.
   Initially, the power light and LAN light where the cable is connected will be solid green.
   After about 1 minute, the power light will quickly flash between green and orange.
   This completes the flashing process.

1. The AP will now reboot.
   Wait for a solid green light on the power.

1. Move the ethernet cable from the LAN port to the WAN port.

   > The AP WAN needs a tagged VLAN.
   > We must setup a DHCP server on the workstation.

1. Start up a temporarily DHCP server on the tagged vlan the AP expects:

   ```shell
   make-dhcpd <nic>
   ```

   > Make sure your firewall allows port 67-68 or temporarily disable
   > firewall

1. The DHCP server will assign the AP an address and output in the log.

1. `ssh` into the AP and check `/etc/scale-release`

1. Then run serverspec against the AP to confirm the image works as
   intended:

   ```shell
   cd tests/serverspec
   rake spec TEST_TYPE=openwrt TARGET_HOST=<AP IP>
   ```

   > This assumes you have your ssh keys in the show image or its a
   > none show image with the default scale password

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
