# Bhyve Hypervisor

We have two hypervisor hosts running bhyve and FreeBSD.

## Configuration

Add the following to a fresh version of FreeBSD `12.1`:

```
40fad0c2454a94a334a128163deb82803b59d6da6b08cd0d3bc4acadddd49c1b  FreeBSD-12.1-RELEASE-amd64-memstick.img
```

Setup interfaces in `/etc/rc.conf`. (Example for `conference` bhyve host):

```
ifconfig_igb0="inet 10.128.3.20 netmask 255.255.255.0"
defaultrouter="10.128.3.1"
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
            tmux \
            stow \
            git \
            vim-console
```
> Out of band make sure to get the vm-bhyve-1.5.0.p1.txz and install it
> we need the network functionality of cloudinit in that version for the vms

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
fetch http://cloud-images.ubuntu.com/bionic/20200218/bionic-server-cloudimg-amd64.img
fetch http://cloud-images.ubuntu.com/bionic/20200218/SHA256SUMS
shasum -a 256 -c SHA256SUMS --ignore-missing
qemu-img convert -f qcow2 -O raw bionic-server-cloudimg-amd64.img bionic-server-cloudimg-amd64.raw
```
> NOTE: At the time of doing this the SHA256SUM for this img was
> 3c3a67a142572e1f0e524789acefd465751224729cff3a112a7f141ee512e756
> Ubuntu only keeps about a months worth of images at this URL so
> dont expect to find the same images :(

Once converted the SHA256 bionic-server-cloudimg-amd64.raw have conversion:

```
ecd6c1d1b01ce03bf13229d97438f306fe2eb3fdc4f742608a3726b6c236434d bionic-server-cloudimg-amd64.raw
```

Add the default vm templates and mix in some of the ones from this repo:

```
cp /usr/local/share/examples/vm-bhyve/* /zroot/vm/.templates/
cp ~/scale-network/ansible/roles/bhyve/files/*.conf /zroot/vm/.templates/
```

Add all admin keys to `~/.ssh/authorized_keys`:

```
mkdir ~/.ssh
chmod 700 ~/.ssh
cat ~/scale-network/switch-configuration/authentication/keys/*.pub > ~/.ssh/authorized_keys
cat ~/scale-network/switch-configuration/authentication/keys/rob_id_rsa.pub > ~/authorized_key_bootstrap
```
> NOTE: Theres currently a limitation on cloudinit can only use a single ssh-key

## Launch vms

Create the vms for `conference`:

```
vm create -i ~/imgs/bionic-server-cloudimg-amd64.raw -t scale-core -C -n "ip=10.128.3.5/24;gateway=10.128.3.1;nameservers=8.8.8.8,8.8.4.4" -k ~/authorized_key_bootstrap core
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
