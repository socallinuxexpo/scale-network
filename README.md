# scale-network
configurations, tooling and scripts for [SCALE's](https://www.socallinuxexpo.org/) on-site expo network

## Table of Contents
* [CONTRIBUTING](./CONTRIBUTING.md)
* [SWITCH CONFIG](./switch-configuration/README.md)
* [ANSIBLE](./ansible/README.md)
* [OPENWRT](./openwrt/README.md)
* [TESTING](./tests/serverspec/README.md)

## Requirements
To use this git repo you will need the following pkgs:
  - git >= 1.8.2
  - git-lfs
  - gomplete == 2.2.0

### Installation
#### Gomplate
Installation of `gomplate` is a little bit tricky since it doesnt come in a `.deb`:
```bash
sudo -i
cd /usr/local/bin/
curl -O https://github.com/hairyhenderson/gomplate/releases/download/v2.2.0/gomplate_linux-amd64 -L
mv gomplate_linux-amd64 gomplate
```
 
## Contributing
SCALE happens once a year but the team has ongoing projects and prep year round.
If you are interesting in volunteering please request to join our mailing list:
https://lists.linuxfests.org/cgi-bin/mailman/listinfo/tech
