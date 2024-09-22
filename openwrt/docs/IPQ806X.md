# TPLINK C2600

> **NOTE:** Currently broken on the latest upstream Openwrt reference: 87b14bc6c289e7e80052b344c0f0c35e95ced267
> Will be fixing as soon as possible but not in time for SCaLE 18x

# Configuration

Currently the default configuration for `network` and `wireless` need to be applied

# Flashing

The following is needed to flash the `c2600`:

- TFTP server
- Static IP address `192.168.0.66`

## Linux

> Assuming you are on raspbian

Setup the interface for the expected IP (\`eth0 in this case):

```
auto eth0
iface eth0 inet static
	address 192.168.0.66/24
```

Reboot the host to set the new interface up

nstall following packages.

```
sudo apt-get install xinetd tftpd tftp tcpdump
```

Create /etc/xinetd.d/tftp and put this entry

```
service tftp
{
protocol        = udp
port            = 69
socket_type     = dgram
wait            = yes
user            = nobody
server          = /usr/sbin/in.tftpd
server_args     = /tftpboot
disable         = no
}
```

Create a folder /tftpboot this should match whatever you gave in server_args. mostly it will be tftpboot

```
sudo mkdir /tftpboot
sudo chmod -R 777 /tftpboot
sudo chown -R nobody /tftpboot
```

Restart the xinetd service.

newer systems:

```
sudo service xinetd restart
```

## FreeBSD

> Currently this is how a flash the routers

Setup the interface for the correct static IP (`ue0` in this case):

```
ifconfig ue0 inet 192.168.0.66 netmask 255.255.255.0 
```

Configure the `tftpd` daemon in `inetd`:

```
cat << EOF >> /etc/inetd.conf
tftp   dgram   udp     wait    nobody  /usr/libexec/tftpd      tftpd /tftpboot
EOF
service inetd onestart
```

Add the necessary files to `/tftpboot/`:

```
cp <image>-squashfs-factory.bin /tftpboot/
ln -s <image>-squashfs-factory.bin ArcherC2600_1.0_tp_recovery.bin
```

> *NOTE*: This has to be called `ArcherC2600_1.0_tp_recovery.bin` since tftp
> client from AP only looks for that name

Setup `tcpdump` to watch for traffic on the interface being connected to AP:

```
tcpdump -i ue0 -n udp port 69 -X 
```

> *NOTE*: Keep this running in a separate window as you'll see the image be pulled
> on a successful flash

On the AP:

- Connect ethernet to any LAN port on AP
- While holding down reset, power on device and keep reset pressed for 15 sec
- Check tcpdump for activity, a successful flash take about 5 min to apply. Top
  power symbol light will flash signalling successful apply

After a successful flash, reconfigure the interface for `dhcp` or `static` depending
on your needs:

```
ifconfig ue0 delete
ifconfig ue0 down
ifconfig ue0 inet 192.168.254.1 netmask 255.255.255.0
ifconfig ue0 up
```

Setup dhcp server:

```
sudo apt-get install isc-dhcp-server
```
