# Prereqs

Make sure you have the prereqs for the [LEDE Image Builder](https://lede-project.org/docs/user-guide/imagebuilder#prerequisites)

If you are building images with templates you'll also need:
* gomplate 2.2.0: https://github.com/hairyhenderson/gomplate/releases/tag/v2.2.0

# Build
## Stock Image

To build an image just specify the model to build for. Currently we support
Netgear `3700v2`, `3800`, & `3800ch` images. To build for `3800ch`:

```sh
make build-3800ch
```
> This requires an internet connection since it downloads the LEDE builds
> from their mirrors.

You will find the images in `./build/lede-imagebuilder-<version>-ar71xx-generic.Linux-x86_64/bin/targets/ar71xx/generic/`
The `*sysupgrade.bin` file that matches the AP model should have been generated.

## Image with Templates

Copy over the default secrets:
```bash
cd ./openwrt/
cp ../facts/secrets/openwrt.yaml.example ../facts/secrets/openwrt.yaml
```

Update the default to represent actual values then:
```bash
cd ./openwrt/
make templates build-3800ch
```

This will populate the templates with the necessary values and include them
into the lede build

# Upgrading
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


## Make

* http://makefiletutorial.com/
* https://bost.ocks.org/mike/make/
* http://mrbook.org/blog/tutorials/make/
* ftp://ftp.gnu.org/old-gnu/Manuals/make-3.79.1/html_chapter/make_2.html
