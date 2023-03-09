# Bhyve Hypervisor

We have two hypervisor hosts running bhyve and FreeBSD for Scale

## Prep Install Media

Add the following to a fresh version of FreeBSD `13.1`:

```
SHA256 (FreeBSD-13.1-RELEASE-amd64-memstick.img) = f73ce6526ccd24dfe2e79740f6de1ad1a304c854bfcff03a4d5b0de35d69d4a0
```

dd the image to a flash drive

Mount the flash drive and modify `/boot/loader.conf` for serial support:

```
cat << EOF >> /boot/loader.conf
# Setup serial console.
boot_multicons="YES"
boot_serial="YES"
comconsole_speed="115200"
console="comconsole"
EOF
```

Boot it

Options to select during the installer:

```
Default US keyboard - Auto detected
```

```
Deselect all system components
```

```
installer type: Auto ZFS installer
pool type: RAID 10 (if possible)
filesystem name: zroot
swap: 2G
encrypted swap: YES
```

At the end of the installer drop into a shell and readd the serial config to /boot/loader.conf:

```
cat << EOF >> /boot/loader.conf
boot_multicons="YES"
boot_serial="YES"
comconsole_speed="115200"
console="comconsole,vidconsole"
EOF
```

## OS Configuration

Setup interfaces in `/etc/rc.conf`. (Example for `conference` bhyve host):

```
hostname="bhyveexpo"
# Leave this if we need DHCP
#ifconfig_igb0="DHCP"
ifconfig_igb0="inet 10.0.3.20 netmask 255.255.255.0"
defaultrouter="10.0.3.1"
#ifconfig_igb0_ipv6="inet6 accept_rtadv"
ifconfig_igb0_ipv6="inet6 2001:470:f325:103::20 prefixlen 64"
ipv6_defaultrouter="2001:470:f325:103::1"
sshd_enable="YES"
# Set dumpdev to "AUTO" to enable crash dumps, "NO" to disable
dumpdev="AUTO"
zfs_enable="YES"
vm_enable="YES"
vm_dir="zfs:zroot/vm"
vm_list="core"
```
> NOTE: Set static IP interface for ipv4 to appropriate value

Set repo list to `latest`:

```
mkdir -p /usr/local/etc/pkg/repos
cat << EOF >> /usr/local/etc/pkg/repos/FreeBSD.conf
FreeBSD: {
  url: "pkg+http://pkg.FreeBSD.org/${ABI}/latest",
  mirror_type: "srv",
  signature_type: "fingerprints",
  fingerprints: "/usr/share/keys/pkg",
  enabled: yes
}
EOF
```

Install the complete set of pkgs that we need:

```
pkg install -y beadm \
            qemu-tools \
            cdrkit-genisoimage \
            grub2-bhyve \
            dmidecode \
            tmux \
            stow \
            git \
            vim \
            bash
            # vm-bhyve # leaving until 1.5.0 is in ports

```
> >= vm-bhyve-1.5.0.p1.txz for cloudinit in that version for the vms

For the right version of vm-bhyve we need to build it ourselves:

```
portsnap fetch extract
git clone https://github.com/sarcasticadmin/ports.git /usr/robs-ports
cd /usr/robs-ports/sysutils/vm-bhyve
make install
```

Configure a boot environment before we continue to configure the system:

```
beadm create slotA
```

Check for any patches for the version of FreeBSD:

```
freebsd-update fetch
freebsd-update install
```

Clone down the scale repo:

```
cd ~
git clone https://github.com/socallinuxexpo/scale-network.git
```

Create vm zfs filesystem:

```
zfs create zroot/vm
# sysrc vm_enable="YES" # Only do these if you havent appended to rc.conf
# sysrc vm_dir="zfs:zroot/vm" # ""
vm init
vm switch create public
vm switch add public igb0
```

Confirm serial port configured via loader.conf:

```
boot_multicons="YES"
boot_serial="YES"
comconsole_speed="115200"
console="comconsole,vidconsole"
```

Grab the `Ubuntu 18.04` image that we'll be using for the linux guests:

```
mkdir ~/imgs
cd ~/imgs
```

Lets get 20.04:
```
fetch http://cloud-images.ubuntu.com/focal/20220721/focal-server-cloudimg-amd64.img
fetch http://cloud-images.ubuntu.com/focal/20220721/SHA256SUMS
shasum -a 256 -c SHA256SUMS --ignore-missing
qemu-img convert -f qcow2 -O raw focal-server-cloudimg-amd64.img focal-server-cloudimg-amd64.raw
```
> NOTE: At the time of doing this the SHA256SUM for this img was
> 969ccacd3ab8a227e5ac26fe12d59f608d93230a444b126887c18f145f5027e0

Once converted the SHA256 focal-server-cloudimg-amd64.raw have conversion:

```
316e21d706fbaf760885018efd0c06e3ab6101fcc51e70a94b35b475b61a0ad  focal-server-cloudimg-amd64.raw
```

Add the default vm templates and mix in some of the ones from this repo:

```
cp ~/scale-network/utilities/bhyve/templates/*.conf /zroot/vm/.templates/
```
> Example templates can be found in: /usr/local/share/examples/vm-bhyve/

Adding all ssh keys for the tech team to authorized_keys:

```
mkdir ~/.ssh
chmod 700 ~/.ssh
cat ~/scale-network/facts/keys/*.pub > ~/.ssh/authorized_keys
```

Add `admin` key to for vm default ssh key:

```
cat ~/scale-network/facts/keys/admin_id_ed25519.pub > ~/authorized_key_bootstrap
```
> NOTE: Theres currently a limitation on cloudinit can only use a single ssh-key

## Launch vms

Create the vms for `conference`:

```
vm create -i ~/imgs/bionic-server-cloudimg-amd64.raw -t scale-core -C -n "ip=10.0.3.5/24;gateway=10.0.3.1;nameservers=8.8.8.8,8.8.4.4" -k ~/authorized_key_bootstrap core
vm create -i ~/imgs/bionic-server-cloudimg-amd64.raw -t scale-monitoring -C -n "ip=10.128.3.6/24;gateway=10.128.3.1;nameservers=8.8.8.8,8.8.4.4" -k ~/authorized_key_bootstrap monitoring
vm create -i ~/imgs/bionic-server-cloudimg-amd64.raw -t scale-automation -C -n "ip=10.128.3.7/24;gateway=10.128.3.1;nameservers=8.8.8.8,8.8.4.4" -k ~/authorized_key_bootstrap automation
vm create -i ~/imgs/bionic-server-cloudimg-amd64.raw -t scale-signs -C -n "ip=10.128.3.8/24;gateway=10.128.3.1;nameservers=8.8.8.8,8.8.4.4" -k ~/authorized_key_bootstrap signs
```
> Configuration will vary for the expo side

Snapshot them all before we start:

```
zfs snapshot zroot/vm/core/disk0@init
zfs snapshot zroot/vm/monitoring/disk0@init
zfs snapshot zroot/vm/automation/disk0@init
zfs snapshot zroot/vm/signs/disk0@init
```

Start the vms:

```
vm start core
vm start monitoring
vm start automation
vm start signs
```

## References

* churchers-vm controller: https://github.com/churchers/vm-bhyve

## Troubleshooting

If you need to mount the zpool in a livecd:

```
mount -u / # Set the livecd to be writeable
zpool import zroot -R /mnt/other # Set altroot to something other than /
zfs mount zroot/ROOT/default # zfs on root set canmount option to false for the root filesystem for force it here
zfs export zroot
```
