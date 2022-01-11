# Openwrt Build

## Requirements

Make sure you have the prereq pkgs for the [Openwrt Image Builder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder)

To use this part of the git repo you will need the following pkgs:
  - git >= 1.8.2
  - git-lfs
  - gomplate >= 3.2.0
  - Docker (Optional)

### Gomplate

Installation of `gomplate` is a little bit tricky since it doesnt come in a `.deb`:
```bash
sudo -i
cd /usr/local/bin/
curl -O https://github.com/hairyhenderson/gomplate/releases/download/<version>/gomplate_linux-amd64 -L
mv gomplate_linux-amd64 gomplate
```

### Docker

You can build these openwrt images inside a docker container. This makes it easy to has a consistent build environment
for all members of the tech team.

To start building:

```
docker pull sarcasticadmin/openwrt-build:d25cfb5
# Make sure to mount the git root inside this container
docker run -v $(git rev-parse --show-toplevel):/home/openwrt/scale-network --rm -it sarcasticadmin/openwrt-build@sha256:8dc545cb1cbb2cb507f4e5c8df2f3632335abf7230f9574eb39080c2fc67cc3f /bin/bash
cd /home/openwrt/scale-network
```
> There is no latest tag so make sure to specify the version (short commit hash)
> The docker mount only works in linux, on OSX you'll get: "Build dependency: OpenWrt can only be built on a case-sensitive filesystem"

Then continue onto whichever image you'd like to build.

## Build

### Image No Templates

Build are done per arch with `TARGET` environment variable (defaults to `TARGET=ar71xx`:

```sh
cd ./openwrt
make build-img
```
> This requires an internet connection since it downloads the Openwrt src
> github.com and uses some openwrt mirrors.

You will find the images in `./build/source-<commit>/bin/targets/<target>/generic/`
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

## Misc

### Adding new packages

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

### Updating target info

This is similar to `Adding a new package` however after running `menuconfig` go back to the Makefile in `openwrt`
and run:
```
make diffconfig targetconfig
```

### Update openwrt/opkg

To bump the Makefile to reference the current upstream master branches

```
make bump
```

After bumping the version of openwrt/opkg make sure to ensure that the configs are
still generated cleanly (no diff)

```
make config
make menuconfig
```
> Ensure the selections in menuconfig are what your expecting

If it looks good save them back to `config/` using:

```
make diffconfig commonconfig targetconfig
```
> This generates the diff of the base config, then we split it out
> into the common components and last its arch target configs

Repeat this for `TARGET=ipq806x`

```
TARGET=ipq806x make config
TARGET=ipq806x make diffconfig commonconfig targetconfig
```

### Build Identity

Depending on the SCaLE conference number, the WPS LED will be ON for even years and OFF
for odd years.
> NOTE: This depends on the SCaLE conference number from `facts.yaml` not the year since the build
> would drift based on when it was built.

## Notes

### Issues

1. When iterating on new packages there have been times were the existing config is stale
and needs to be completely blown away and regenerated off of `master` then reconfigured
with `menuconfig`. This is just something to be aware of since its come up during the development
of this image.

### SSH

1. `/root` - Must be permissions `755` (or less perm) or ssh-key auth wont work
2. openssh needs to have both `/etc/passwd` and `/etc/hosts` to allow ssh login

### Useful commands

To check which vlans are loaded onto a switch:

```sh
swconfig dev switch0 show
```

Check to see the status of the wifi radios:

```sh
wifi status
```

### Make

* http://makefiletutorial.com/
* https://bost.ocks.org/mike/make/
* http://mrbook.org/blog/tutorials/make/
* ftp://ftp.gnu.org/old-gnu/Manuals/make-3.79.1/html_chapter/make_2.html

## Troubleshooting

### build fails

There are many different packages in the openwrt and the open pkgs repo. Some of the requirements for the build system
differ based on upstream changes to both repos. Its best to check the log to see if there was a dependency missed due to
these changes. This is also something to account for when bumping the based build system (ubuntu 16.04 vs ubuntu 18.04)

### mkhash

If early in the build you recieve `bin/mkhash: No such file or directory`. Check to make sure that the `mkhash` binary is
linked against the right linker/loader. In some cases you could have mkhash that was build inside or outside of the
environment and its unable to the expected loader.

```
$ file ./staging_dir/host/bin/mkhash
+ file ./staging_dir/host/bin/mkhash
./staging_dir/host/bin/mkhash: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /nix/store/9bh3986bpragfjmr32gay8p95k91q4gy-glibc-2.33-47/lib/ld-linux-x86-64.so.2, for GNU/Linu
x 2.6.32, with debug_info, not stripped
```
> Note: `mkhash` will exist but be unable to run and fail with the following `No such file or directory`

`make clean-all` and rerun inside the local environment should fix it
