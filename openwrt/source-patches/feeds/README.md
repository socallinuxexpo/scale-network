# Feed source patches

Patches against an OpenWrt feed belong in `feeds/<feedname>/NNN-*.patch`,
with a `NNN-*.check` sidecar in the same directory. The feed name must
match the name in `feeds.conf` (SCALE pins the `packages` feed at
`OPENWRT_PKG_VERSION`, currently `sarcasticadmin/opkgs`).

They are applied after `./scripts/feeds update` and before
`feeds install`, against `build/source-<target>-<ver>/feeds/<feedname>/`.
Paths inside the patch are relative to the feed root. See the parent
[README.md](../README.md) for naming, still-needed checks,
`SOURCE_PATCH_MODE`, `SKIP_SOURCE_PATCHES` (including qualified ids
such as `packages/001`), fail-clean behavior, and `LUAC_FILES`.

This directory has no patches of its own; a stacked change that carries
a feed patch adds `feeds/<feedname>/`.
