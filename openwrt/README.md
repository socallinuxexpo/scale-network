# Prereqs

Make sure you have the prereq pkgs for the [LEDE Image Builder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder)

If you are building images with templates you'll also need:
* gomplate 2.2.0: https://github.com/hairyhenderson/gomplate/releases/tag/v2.2.0

# Build
## Stock Image

Currently we support Netgear `3700v2`, `3800`, & `3800ch` images.

We build all 3 modules at once:

```sh
cd ./openwrt
make build-img
```
> This requires an internet connection since it downloads the LEDE src
> github.com and uses some openwrt mirrors.

You will find the images in `./build/source-<commit>/bin/targets/ar71xx/generic/`
The `*sysupgrade.bin` and `*factory.img` files match the AP models

## Image with Templates
To get the configuration thats used at scale the templates need to be baked into
the image.

Copy over the default secrets:
```bash
cp ./facts/secrets/openwrt.yaml.example ./facts/secrets/openwrt.yaml
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
into the lede build

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
Assuming openwrt or LEDE is already installed:

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
