# Autoflash

## Intro

There has been significant work on the autofashing process for the APs used at SCaLE. As opposed to having to leverage
the [traditional flashing process](./AR71XX.md#flashing).

We now have an autoflashing process that takes place soley inside out CI process and leverages external runners to
physical hardware hosted elsewhere. This document will explain how to configure a raspberry pi and corresponding AP to be
setup for autoflashing.

## Slash command

This is an outline for how to trigger a build on a PR thats in scale-network:

1. Have write access to the repo and push branch directly to the repo. This is needed since we have gitlab mirroring our
   repo.
2. Generate a wormhole string using wormhole and the image to be flashed:

```
~$ wormhole send /openwrt-ath79-generic-netgear_wndr3800ch-squashfs-factory.img
Wormhole code is: 8-amusement-drumbeat
```

3. Take wormhole code `8-amusement-drumbeat` and pass it along to our `tux` slash command as a PR comment:

```
/tux openwrt flash 8-amusement-drumbeat
```

4. This will kickoff the flash and reply with a gitlab pipeline URL.

## Hardware Prereqs

We'll be using the Raspberry Pi 2 for our autoflash coordinator. This should work with any version of the Pi
or similar hardware but we have many extra Pi 2s as they were old sign clients.

Parts list:

1. Tek Republic TUN-300 - Works well with FreeBSD but any USB interface using the ue driver should work
2. Raspberry Pi - Any model should do just make sure the image being flashed matches the architecture
3. Raspberry Pi Power Adapter - Will need to modify
4. Relay - Currently using [these from Amazon](https://www.amazon.com/gp/product/B07PNB86R7)
5. AP Board - Currently only have this working for WNDR-3700v2 and WNDR-3800[CH]

Wiring:

1. Splice power adapter ground (white dashes) wire and connect to relay points:

```
Wall Wart -> COMM
NC -> Barrel Plug
```

2. Other relay points:

```
GND -> Pi pin 9
IN ->  Pi pin 3
VCC -> Pi pin 2
```

3. Next you'll need to solder 2 wires to the board. One to a ground spot and the other to the reset switch.
  With those in place, the wires connect o the pi:

```
AP Board ground -> Pi pin 6
AP Board reset switch -> Pi pin 5
```

4. Connect USB ethernet interface to LAN port 1 (closest to the barrel plug) on the AP

References:
- Pi header (pins) diagram: https://www.raspberrypi.org/documentation/usage/gpio/

## Software Prereqs

Using `FreeBSD pi2` image:

```
FreeBSD generic 12.2-RELEASE FreeBSD 12.2-RELEASE r366954 GENERIC  arm
```

Install pkgs:

```
pkg install -y bash expect \
               ruby rubygem-serverspec \
               rubygem-rake curl sudo \
               py37-magic-wormhole git dnsmasq
```

Build the `gitlab-runner`:

1. Build gitlab-runner from source and instructions here: https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6694#note_307517264 (go 1.13 required)
2. Copy gitlab-runner binary to pi
3. Need to setup gitlab configuration: https://docs.gitlab.com/runner/install/freebsd.html
> Reach out to Rob for registration token for the runner

Thats it! And you should be able to confirm your runner is up and running by looking at
[Gitlab settings](https://gitlab.com/socallinuxexpo/scale-network/-/settings/ci_cd#js-runners-settings)

Additionally considerations:
- Make sure USB interface connected to Pi is set to interface `ue1`
- `serverspec` needs to be passed `LOGIN_PASSWORD` environment var to match default pass for image (current set in gitlab
  CI env var at runtime)
