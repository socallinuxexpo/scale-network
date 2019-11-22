# Openwrt

## Supported Hardware

* WNDR 3700,3800,3800ch
* [TPLink c2600](./TPLINK.md)

## Prereqs

Make sure you have the prereq pkgs for the [Openwrt Image Builder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder)

If you are building images with templates you'll also need:
* [gomplate](../README.md#requirements)

## Build

### Docker

You can build these images inside a docker container. This makes it easy to has a consistent build environment
for all members of the tech team.

To start building:

```
docker pull sarcasticadmin/openwrt-build:528bc79
# Make sure to mount the git root inside this container
docker run -v $(git rev-parse --show-toplevel):/home/openwrt/scale-network --rm -it sarcasticadmin/openwrt-build:528bc79 /bin/bash
cd /home/openwrt/scale-network
```
> There is no latest tag so make sure to specify the version (short commit hash)
> The docker mount only works in linux, on OSX you'll get: "Build dependency: OpenWrt can only be built on a case-sensitive filesystem"

Then continue onto whichever image you'd like to build.

### Stock Image

Currently we support Netgear `3700v2`, `3800`, & `3800ch` images.

We build all 3 modules at once:

```sh
cd ./openwrt
make build-img
```
> This requires an internet connection since it downloads the Openwrt src
> github.com and uses some openwrt mirrors.

You will find the images in `./build/source-<commit>/bin/targets/ar71xx/generic/`
The `*sysupgrade.bin` and `*factory.img` files match the AP models

### Image with Templates
To get the configuration thats used at scale the templates need to be baked into
the image.

Copy over the default secrets:
```bash
cp ./facts/secrets/openwrt-example.yaml ./facts/secrets/openwrt.yaml
```
> If needed update the defaults in `openwrt.yaml` to represent actual values

Generate and update the root password hash in `openwrt.yaml`:
```bash
openssl passwd -1 secretpassword
```

Compile the templates:
```bash
cd ./openwrt/
make templates
```
> This will populate the templates with the necessary values and
> prep them in the build dir. To validate the templates check:
> ./openwrt/build/source-<commit>/files/

Now build the image:
```
make build-img
```

This will populate the templates with the necessary values and include them
into the Openwrt build

# Adding new packages

Leverage the existing `diffconfig` via the `Makefile`:
```
make config
cd build/source-<SHA>/
make menuconfig
```

At this point you can add any additional pkgs youd like. Afterwhich its time
to save them back to the `diffconfig` using the makefile and then copy them
to the commonconfig:
```
make diffconfig commonconfig
```

At which point you should have a diff in git which can then be tested against a new
build of the img

## Issues

When iterating on new packages there have been times were the existing config is stale
and needs to be completely blown away and regenerated off of `master` then reconfigured
with `menuconfig`. This is just something to be aware of since its come up during the development
of this image.

# Updating target info

This is similar to `Adding a new package` however after running `menuconfig` go back to the Makefile in `openwrt`
and run:
```
make diffconfig targetconfig
```

# Upgrading

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

## Auto TFTP

Use the `flash` script:

```sh
cd openwrt
./flash
```
> This will also update the .csv with the mac address

## Manual TFTP

Manual interaction with `tftp` client:

```sh
ln -s locationof.img factory.img
tftp 192.168.1.1
> bin
> put factory.img
> quit
```

## Inplace
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
# Notes

## Files
### SSH
1. `/root` - Must be permissions `755` (or less perm) or ssh-key auth wont work
2. openssh needs to have both `/etc/passwd` and `/etc/hosts` to allow ssh login

## Useful commands
To check which vlans are loaded onto a switch:

```sh
swconfig dev switch0 show
```

Check to see the status of the wifi radios:

```sh
wifi status
```

## Make

* http://makefiletutorial.com/
* https://bost.ocks.org/mike/make/
* http://mrbook.org/blog/tutorials/make/
* ftp://ftp.gnu.org/old-gnu/Manuals/make-3.79.1/html_chapter/make_2.html
