# Prereqs

Make sure you have the prereqs for the [LEDE Image Builder](https://lede-project.org/docs/user-guide/imagebuilder#prerequisites)

# Build image

To build an image just specify the model to build for. Currently we support
Netgear `3700v2`, `3800`, & `3800ch` images. To build for `3800ch`:

```sh
make build-3800ch
```
> This requires an internet connection since it downloads the LEDE builds
> from their mirrors.

You will find the images in `./build/lede-imagebuilder-<version>-ar71xx-generic.Linux-x86_64/bin/targets/ar71xx/generic/`
The `*sysupgrade.bin` file that matches the AP model should have been generated
.
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

## Make

* http://makefiletutorial.com/
* https://bost.ocks.org/mike/make/
* http://mrbook.org/blog/tutorials/make/
* ftp://ftp.gnu.org/old-gnu/Manuals/make-3.79.1/html_chapter/make_2.html
