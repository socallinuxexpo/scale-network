# Bhyve Hypervisor

We have two hypervisor hosts runnig bhyve and FreeBSD.

## Configuration

Add the following to a fresh version of FreeBSD `12.1`:

```
40fad0c2454a94a334a128163deb82803b59d6da6b08cd0d3bc4acadddd49c1b  FreeBSD-12.1-RELEASE-amd64-memstick.img
```

Setup interfaces in `/etc/rc.conf`:

```
ifconfig_igb0="inet 192.168.1.100 netmask 255.255.255.255"
ifconfig_igb0_ipv6="inet6 accept_rtadv"
```
> NOTE: Set stateic IP interface for ipv4 to appropriate value

Install the complete set of pkgs that we need:

```
pkg install beadm \
            vm-bhyve \
            qemu-utils \
            cdrkit-genisoimage \
            grub2-bhyve \
            dmidecode \
            tmux
```
Configure a boot environment before we continue to configure the system:

```
beadm create slotA
```

Clone down the scale repo:

```
cd ~
git clone https://github.com/socallinuxexpo/scale-network.git
```

Create vm zfs filesystem:

```
zfs create zroot/vm
sysrc vm_enable="YES"
sysrc vm_dir="zfs:zroot/vm"
vm init
vm switch create public
vm switch add public igb0
```

Configure serial port for via loader.conf:

```
cat << EOF >> /boot/loader.conf
boot_multicons="YES"
boot_serial="YES"
comconsole_speed="115200"
console="comconsole,vidconsole"
EOF
```

Grab the `Ubuntu 18.04` image that we'll be using for the linux guests:

```
mkdir ~/imgs
cd ~/imgs
fetch http://cloud-images.ubuntu.com/bionic/20200130.1/bionic-server-cloudimg-amd64.img
fetch http://cloud-images.ubuntu.com/bionic/20200130.1/SHA256SUMS
shasum -a 256 -c SHA256SUMS --ignore-missing
qemu-img convert -f qcow2 -O raw bionic-server-cloudimg-amd64.img bionic-server-cloudimg-amd64.raw
```
> NOTE: At the time of doing this the SHA256SUM for this img was
> 32297cc70f405168d9c989c445cc0e1feab1ad37164ec821bcfc64fbc2899e6d

Once converted the SHA256 bionic-server-cloudimg-amd64.img have conversion:

```
32297cc70f405168d9c989c445cc0e1feab1ad37164ec821bcfc64fbc2899e6d  bionic-server-cloudimg-amd64.img
```

Add the default vm templates and mix in some of the ones from this repo:

```
cp /usr/local/share/examples/vm-bhyve/* /zroot/vm/.templates/
cp ~/scale-network/ansible/roles/bhyve/files/*.conf /zroot/vm/.templates/
```

Add all admin keys to `~/.ssh/authorized_keys`:

```
cat ~/scale-network/switch-configuration/authentication/keys/*.pub ~/.authorized_keys
```

## Launch vms

```
vm create -i ~/bionic-server-cloudimg-amd64.raw -t scale-zabbix -s 1000G -C -k ~/.ssh/authorized_keys zabbix
```
> This will spin up a server called zabbix with 1000G zvol and configure the ubuntu user ssh keys from authorized_keys

## References

churchers-vm controller: https://github.com/churchers/vm-bhyve
