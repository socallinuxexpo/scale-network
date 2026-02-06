## Preconference Checklist

- [ ] Ensure network team members keys are up to date (https://github.com/socallinuxexpo/scale-network/tree/master/facts/keys) if necessary
- [ ] Update admin key for the expo (https://github.com/socallinuxexpo/scale-network/blob/master/facts/keys/admin_id\*.pub)
- [ ] Update scale version in facts/aps/\*-openwrt-show.yaml

```bash
find ./facts/aps/ -type f -exec sed -i 's/scale:\ 21/scale:\ 22/g' {} \;
```

- [ ] Update root secrets in facts/aps/\*-openwrt-show.yaml:

```bash
openssl passwd -6 newpass
```

- [ ] Update wifi password (if need):
  - https://github.com/socallinuxexpo/scale-network/blob/master/facts/secrets/ar71xx-openwrt-show.yaml
  - https://github.com/socallinuxexpo/scale-network/blob/master/openwrt/files-mt7622/etc/config/wireless.0
- [ ] Create release: https://github.com/socallinuxexpo/scale-network/blob/master/RELEASE.md
