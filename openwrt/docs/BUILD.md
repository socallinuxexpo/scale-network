# Openwrt Build

## Requirements

Make sure you have the prereq pkgs for the [Openwrt Image Builder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder)

To use this part of the git repo you will need the following pkgs:

- git >= 1.8.2
- git-lfs
- gomplate >= 3.11.0
- Docker (Optional)
- Nixpkgs (Optional)

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
# Make sure to mount the git rev-parse --show-toplevel) inside this container
docker run -v $(git rev-parse --show-toplevel):/home/ubuntu/scale-network --rm -it docker.io/sarcasticadmin/openwrt-build@sha256:25ac9d0dd4eeaad1aaaa7c82c09e9ecc103c69224fc55eb9717c4cfb018a5281 /bin/bash
cd /home/ubuntu/scale-network
```

> There is no latest tag so make sure to specify the version (short commit hash)
> The docker mount only works in linux, on OSX you'll get: "Build dependency: OpenWrt can only be built on a case-sensitive filesystem"

Then continue onto whichever image you'd like to build.

## Build

### Image No Templates

Build are done per arch with `TARGET` environment variable (defaults to `TARGET=ath79`:

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

Copy over the default config:

```bash
cp ./facts/aps/openwrt-example.yaml ./facts/aps/openwrt.yaml
```

> If needed update the defaults in `openwrt.yaml` to represent actual values

Generate and update the root password hash in `openwrt.yaml`:

```bash
openssl passwd -6 secretpassword
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

#### common.config

Leverage the existing `diffconfig` via the `Makefile`:

```
TARGET=x86 make config menuconfig
```

> This assumes the additional packages are common to all architectures if not change TARGET
> to specific board arch

Save pkgs back to common.config with `diffconfig` using the Makefile and then copy them
to the commonconfig:

```
TARGET=x86 make commonconfig
```

At which point you should have a diff in git which can then be tested against a new
build of the img

#### mt798x-generic.config

Will use mt798x as an example but this will work for any other arch we support:

```
TARGET=mt798x make config menuconfig
```

After adding the specific mt798x arch packages:

```
TARGET=mt798x make targetconfig
```

### Update openwrt/opkg

To bump the Makefile to reference the current upstream master branches

```
make bump
```

After bumping the version of openwrt/opkg make sure to ensure that the configs are
still generated cleanly (no diff)

```
TARGET=x86 make config menuconfig
```

> Ensure the selections in menuconfig are what your expecting

If it looks good save them back to `config/` using:

```
TARGET=x86 make commonconfig targetconfig
```

> This generates the diff of the base config, then we split it out
> into the common components and last its arch target configs

Repeat this for `TARGET=ath79` and `TARGET=mt798x`

```
TARGET=mt798x make config menuconfig
TARGET=mt798x make targetconfig
```

> commonconfig is only generated on x86

Commit the results that are generated. You can ensure that the config options are stable by repeating
the process. You should not get a diff.

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
1. openssh needs to have both `/etc/passwd` and `/etc/hosts` to allow ssh login

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

- http://makefiletutorial.com/
- https://bost.ocks.org/mike/make/
- http://mrbook.org/blog/tutorials/make/
- ftp://ftp.gnu.org/old-gnu/Manuals/make-3.79.1/html_chapter/make_2.html

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

### Config generation process

Assuming we are starting from no existing `.config`. Lets generate the x86 config first since its
the most generic (no specific drivers or modules):

```
cd <build source>
rm -f *.config
```

If you already have a true common config (meaning no specific arch or arch packages inside) you can copy it in:

```
cp $(git rev-parse --show-toplevel)/openwrt/configs/common.config ./.config
```

Or create a new one:

```
make defconfig
```

> Set target to `x86/generic`

Install only packages which are utilities and non arch specific things. We dont want the hardware packages to pollute the common.config. When youve got all of it selected you can then create
the `common.config`

```
./scripts/diffconfig.sh | tee .diffconfig | grep -v CONFIG_TARGET > $(git rev-parse --show-toplevel)/openwrt/configs/common.config
```

```
comm -23 <(sort ./.diffconfig) <(sort $(git rev-parse --show-toplevel)/openwrt/configs/common.config) > $(git rev-parse --show-toplevel)/openwrt/configs/x86-generic.config
```

Now we have the `common.config` and `x86-generic.config`. To add in a specific board:

```
cd <build source>
cat $(git rev-parse --show-toplevel)/openwrt/configs/common.config > ./.config
cat $(git rev-parse --show-toplevel)/openwrt/configs/x86_generic.config >> ./.config
```

Run `make menuconfig` and change the arch from x86 to target arch:

```
./scripts/diffconfig.sh | tee .diffconfig | grep -v CONFIG_TARGET > $(git rev-parse --show-toplevel)/openwrt/configs/common.config
```

```
comm -23 <(sort ./.diffconfig) <(sort $(git rev-parse --show-toplevel)/openwrt/configs/common.config) > $(git rev-parse --show-toplevel)/openwrt/configs/mt798x-generic.config
```

> Assuming mt798x is our target arch

Thats it now you should have a generic config and a arch specific config going forward. The majority of these steps are taken care of by the Makefile in the `openwrt` dir but in the cases where
we need to start fresh this has been time consuming to recall.
