# CI for scale-network

## Github Actions

See actions defined: https://github.com/socallinuxexpo/scale-network/tree/master/.github/workflows

### /tux command

`/tux` is our keyword in a PR comment. This structure is setup like a CLI command:

``` 
/tux openwrt flash <WORMHOLE-STRING>
 |     |       |           |
 |     |       |           --- Arg needed for flashing
 |     |       --- Specific action to take
 |     --- Subcommand for specific components of the repo
 --- /tux trigger word
```

### Openwrt Example

This is an outline for `/tux` and how to trigger a build on a PR thats in `scale-network` repo:

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

## Gitlab CI

See the pipelines defined: https://github.com/socallinuxexpo/scale-network/blob/master/.gitlab-ci.yml

Our [autoflash process](./openwrt/docs/AUTOFLASH.md) leverages `gitlab-runners` to be able to interact with real hardware so that
we can automate the flashing process to test our openwrt images.

