# OpenWrt source patches

Patches in this directory are applied (in lexical order, `patch -p1`) to
the OpenWrt tree right after `make extract` unpacks `OPENWRT_VER`, by
`scripts/apply_source_patches.sh`. Use them for targeted fixes we need
before they reach the `OPENWRT_VER` we pin, without bumping the whole
tree.

Patches that target a **feed** (for example the `packages` feed pinned
at `OPENWRT_PKG_VERSION`, `sarcasticadmin/opkgs`) live under
`feeds/<feedname>/NNN-*.patch`. They are applied after
`./scripts/feeds update` and before `feeds install` or the build,
against the feed checkout at
`build/source-<target>-<ver>/feeds/<feedname>/`. The same fail-clean behavior, `check-source-patches` classification,
`SOURCE_PATCH_MODE`, and `SKIP_SOURCE_PATCHES` handling apply.

With no `*.patch` files (and no feed patches), `make extract` produces
the same tree as it did before this mechanism existed. A patch that does
not apply (for example after `make bump`) fails the build. OpenWrt-tree
extraction goes through a temporary directory, and a failed feed patch
resets the feed checkout (or is applied in a temporary copy), so a
failure never leaves a half-patched tree.

## Build control: `SOURCE_PATCH_MODE`

Applying the patches, and trying a build without them, are never
automatic. One knob chooses the path:

| `SOURCE_PATCH_MODE` | What happens |
| --- | --- |
| `apply` (default) | Apply every source patch and build as usual. At most the cheap source check is run, as an advisory hint. `SKIP_SOURCE_PATCHES` is ignored. A flagged source check is a report only; it does **not** start a without-patch build. |
| `check` | Run only `make check-source-patches`. Do not extract a build tree or build an image. |
| `trial` | Explicit without-patch build. Honors `SKIP_SOURCE_PATCHES`. If that is empty, skips the patches the source check flags; if nothing is flagged either, the build stops and asks you to set `SKIP_SOURCE_PATCHES` (for example every id after an `OPENWRT_VER` bump). |

Set the mode on the make command line, or via the GitHub
`workflow_dispatch` input `source_patch_mode` / the GitLab pipeline
variable `SOURCE_PATCH_MODE`. The weekly/cron OpenWrt job has no input,
so it stays on `apply`. A source check that flags a patch must never
flip the mode by itself.

```
# normal (and CI default): all patches, no extra image
make templates build-img

# advisory source check only
make check-source-patches
# or: make SOURCE_PATCH_MODE=check

# explicit without-patch confirmation (one image, all candidates)
make clean
make extract SOURCE_PATCH_MODE=trial SKIP_SOURCE_PATCHES=001,002
make build-img
```

## Adding a patch

Several patches can be carried at once. They are applied in lexical
order (OpenWrt-tree patches at extract; each feed's patches after that
feed is updated).

1. Write a git-style diff against the current pin (`OPENWRT_VER` for
   tree patches, `OPENWRT_PKG_VERSION` for the `packages` feed;
   `git format-patch` or `git diff`; file adds and deletes are
   supported, GNU patch >= 2.7). Paths in a feed patch are relative to
   the feed root (for example
   `utils/prometheus-node-exporter-lua/files/...`).
1. Name it `NNN-short-description.patch` so the apply order is obvious
   (`001-…`, `002-…`, …). Prefer an NNN that is unique across *both*
   the OpenWrt tree and every feed, but see qualified skip ids below
   if two patches must share a number.
1. Put it in this directory for an OpenWrt-tree patch, or in
   `feeds/<feedname>/` for a feed patch. The sidecar can also set
   `TARGET=feed:<name>` (this is the default for files already under
   `feeds/<name>/`).
1. Put a header on the patch that names the bug, the upstream commit(s)
   it carries if any, and when it *might* be droppable. The header is
   documentation: the drop decision is the on-device test below, because
   the bug may have been fixed another way.
1. Add a sidecar `NNN-short-description.check` (same stem, same
   directory as the patch) with at least a `RUNTIME_TEST` that detects
   the **bug's behavior**, independent of this patch and of any
   particular upstream commit. Optional keys are listed below.
1. Run `make extract` (after `make clean` only if you are replacing an
   extract that has no reusable build tree) so an OpenWrt-tree patch is
   shown to apply. Feed patches are applied later, when `.config` runs
   `feeds update`; after changing only feed patches on an existing
   extract, `make clean-feeds` is enough. Run
   `make check-source-patches` as well.

### Sidecar (`NNN-name.check`)

`KEY=value` lines, no shell expansion. `#` comments and blank lines are
ignored.

| Key | Required | Meaning |
| --- | --- | --- |
| `RUNTIME_TEST` | yes | Path, relative to the repo root, of an on-device test that FAILs when the bug is present and PASSes when the bug is gone, however it was fixed. Do not check package versions or patch markers. |
| `RUNTIME_TEST_ENV` | no | Environment for that test (for example `TESTS=A` to run only the case that belongs to this bug). |
| `DESCRIPTION` | no | One-line summary of the bug. |
| `UPSTREAM_OPENWRT` | no | Known OpenWrt landing commit(s), advisory only. |
| `UPSTREAM_NOTES` | no | Extra advisory context (other repos, etc.). |
| `TARGET` | no | `openwrt` (default for patches in this directory) or `feed:<name>` (default for patches under `feeds/<name>/`). Tells the source check which tree to classify against. |
| `LUAC_FILES` | no | Space- or comma-separated paths, relative to the patch's target tree, of Lua files to syntax-check with `luac -p` after a temp apply. If `luac` is not on the build host the check is skipped (not a failure). A `luac` syntax error fails `make check-source-patches`. |

## Is a patch still needed?

The on-device behavioral test is the deciding verdict. The source-level
check is a cheap first step. Without-patch images are expensive in this
repo (see "What is cached" below), so we do **not** build one image per
patch, and we do not run a without-patch build unless someone sets
`SOURCE_PATCH_MODE=trial` explicitly.

### 1. Every run: cheap source-level check only (or the apply-mode hint)

```
make check-source-patches
```

This unpacks a pristine `OPENWRT_VER` tree (it does not touch an existing
extract or a built toolchain) and, when any feed patches are present, a
pristine checkout of the `packages` feed at `OPENWRT_PKG_VERSION`. For
each patch it compares the patch's **substantive** code changes with the
matching tree: comment-only and blank hunk lines are ignored (including
`--` comments in `.lua` files), and whitespace is ignored. It also tries
a whitespace-ignoring forward and reverse apply. Sidecar `LUAC_FILES`
are syntax-checked with `luac -p` when `luac` is on the host.

| Result | Meaning | What to do next |
| --- | --- | --- |
| `NEEDED` | The patch still applies and the change is not in the tree (OpenWrt or the named feed). | Keep the patch. No extra image on this run. |
| `LIKELY-UPSTREAM` | The substantive change appears to be already present. This is a hint, not proof. | Flag the patch for a without-patch confirmation (step 2). |
| `NO-LONGER-APPLIES` | The patch does not apply and the change is not clearly present. `make extract` (tree) or `feeds update` / feed apply (feed) will fail. | Human review, and include it in the step-2 confirmation. |

`make check-source-patches` exits 0 when every patch is `NEEDED` (or there
are no patches), 2 when any patch is flagged, and 1 if metadata is
missing. Exit 2 is a flag for follow-up, not permission to drop a patch,
and it never starts a trial build. In `SOURCE_PATCH_MODE=apply`, the
same check is run after extract as a hint; exit 2 is printed and the
patched build continues.

### 2. Without-patch confirmation (only when explicitly requested)

Do this only when you have set `SOURCE_PATCH_MODE=trial`, typically
because:

- `OPENWRT_VER` was just bumped, **or**
- step 1 flagged one or more patches (`LIKELY-UPSTREAM` or
  `NO-LONGER-APPLIES`) and you decided to confirm.

On an `OPENWRT_VER` or `OPENWRT_PKG_VERSION` bump, include **every**
carried patch in the confirmation (tree and feed), even those that
step 1 still calls `NEEDED`: the bug may have been fixed another way.
Pass that list in `SKIP_SOURCE_PATCHES` (trial will not guess the
NEEDED ones).

**Build one image (or one package rebuild) with all candidate patches
disabled at once**, not one image per patch:

```
# explicit; ids from the check output, comma-separated
make extract SOURCE_PATCH_MODE=trial SKIP_SOURCE_PATCHES=001,002
make build-img
```

`SKIP_SOURCE_PATCHES` accepts `NNN`, `NNN-short-description`, or the
filename, comma- or space-separated. A bare `001` matches every patch
with that prefix, in the OpenWrt tree or a feed. To target one patch
when numbers collide, use a qualified id: `openwrt/001`,
`packages/001`, `feeds/packages/001`, or `feed:packages:001`.
`check-source-patches --flagged-ids` prints feed patches as
`<feed>/<NNN>`. The skip list from a trial extract is written next to
the build tree and reused when feed patches are applied, so a later
`make build-img` without `SOURCE_PATCH_MODE=trial` on the command line
still honors that trial. After changing the skip list on an existing
extract, re-extract for tree patches and `make clean-feeds` for feed
patches.

Then flash that one image and run each candidate's `RUNTIME_TEST` (with
its `RUNTIME_TEST_ENV` if any).

- **All PASS without those patches** – the bugs are gone, however they
  were fixed. Drop all of those patches.
- **Some FAIL** – only then bisect (rebuild with a subset skipped, or
  install just the affected package) to see which patch is still
  required. A FAIL means keep or refresh that patch.
- **SKIP** – inconclusive (for example a DFS/CAC radio that returns
  EBUSY). Re-run where the test can actually exercise the bug.

### How to produce that one without-patch build (avoid a from-scratch tree)

Do **not** start with `make clean` if you already have a built
`build/source-<target>-<ver>/` tree. The SCALE `make clean` deletes that
whole tree, including OpenWrt's toolchain, `staging_dir`, `build_dir` and
`dl/` (verified in `openwrt/Makefile`). That turns a package-level change
into a multi-hour full rebuild.

Preferred, on a tree that has already completed `make build-img`:

1. Reverse only the candidate patches in that tree (`patch -p1 -R` for
   each), or re-extract into a new `BUILD_DIR` only if you have no
   reusable tree. For feed patches on an existing extract,
   `make clean-feeds` drops the feed checkouts and the `.feeds-updated`
   stamp so the next config re-runs `feeds update` and re-applies
   (or skips) feed patches without wiping the toolchain.

1. Rebuild **only the packages those patches touch**, then repack the
   image. Example, for the packages a typical `diff --git` path of
   `package/utils/ucode/…` or `package/network/config/wifi-scripts/…`
   maps to:

   ```
   cd build/source-<target>-<ver>
   make package/wifi-scripts/{clean,compile} package/ucode/{clean,compile}
   # if ucode's PKG_ABI_VERSION changed, also rebuild libucode users
   # (wpad/hostapd, rpcd, netifd, uhttpd, ucode-mod-*, …), then:
   make
   ```

1. When the change is a no-compile package (`wifi-scripts` is
   `PKGARCH=all` and has empty `Build/Compile`, verified in the
   41a1874c tree) you can build just that package and install it on a
   running AP, or even copy the updated file, without a new image.

1. If there is no reusable tree (typical CI: a fresh runner), one full
   `make extract SOURCE_PATCH_MODE=trial SKIP_SOURCE_PATCHES=… build-img`
   is required. Still do that **once** for all candidates, not once per
   patch, and only when trial mode was set explicitly.

To keep a fully patched extract and a skipped one side by side, use a
different `BUILD_DIR`. Sharing or copying `dl/` (and, if you know what
you are doing, `staging_dir` / the toolchain) between those dirs is
possible but is not wired up in the Makefile today (inferred: standard
OpenWrt, not something this repo implements).

## What is cached, and what a skip rebuild actually costs

Marked **verified** when it comes from files in this repo or the OpenWrt
tree we pin; **inferred** when it is normal OpenWrt/CI behavior we did
not re-run here.

- **This is a full source build, not ImageBuilder.** The Makefile
  variable is named `IMAGEBUILDER` but it is `source-$(TARGET)-$(SHORT_VER)`:
  curl the OpenWrt tarball, `feeds update/install`, `make defconfig`,
  `make download`, `make V=s -j`. Verified in `openwrt/Makefile`.
  `openwrt/docs/BUILD.md` mentions Image Builder only as a prereq list;
  the commands it documents are this source build.

- **GitHub Actions `openwrt-build.yml`** (weekly cron + `workflow_dispatch`,
  matrix `ath79` and `mt798x`, `sarcasticadmin/openwrt-build` container):
  there is no `actions/cache` (or equivalent) and the build happens in
  the job workspace. Each run is therefore a from-scratch toolchain,
  kernel and package build. Artifacts are kept 30 days; they are images
  and logs, not a reusable `staging_dir`. Verified in the workflow YAML.
  The in-repo `openwrt/Dockerfile` only installs host compilers and
  tools, not a prebuilt OpenWrt toolchain (verified). Whether the
  published container image has extra cached state beyond that
  Dockerfile is **not verified** here.

- **GitLab `.gitlab-ci.yml`**: no `cache:` key. `openwrt-ar71xx-build`
  runs only when `OPENWRT_BUILD=YES`, on GitLab shared runners, timeout
  3 hours, and is from-scratch by the same reasoning (verified: no
  cache; inferred: shared runners are ephemeral). `openwrt-3800ch-integ`
  (`OPENWRT_INTEG=YES`, self-hosted `openwrt` tag) does **not** build:
  it `wormhole receive`s a factory image, autoflashes a WNDR3800, and
  runs `rake spec TEST_TYPE=openwrt`. Verified in the job and in
  `openwrt/scripts/local/gather-artifact.sh`.

- **Nix flake CI** (`ci.yml`, `ci-nixos.yml`, GitLab `nix-checks`) does
  not build these AP images. The `openwrt-one-nix` input is the MixOS /
  OpenWrt One NixOS side, not this Makefile. Verified by search of the
  workflows and `flake.nix`.

- **Local or a reused tree:** OpenWrt incremental make will keep
  `dl/` (tarballs), `staging_dir` (toolchain, host tools, staged
  packages), `build_dir` (object files) and only rebuild packages whose
  inputs changed. Inferred: standard OpenWrt; not re-measured here.
  The SCALE wrapper does not add ccache: `CONFIG_CCACHE` is not set in
  `openwrt/configs/*` (verified).

- **Toggling one source patch on a reused tree:**

  - A `wifi-scripts` (or similar files-only) change: just that package,
    then image pack. Inferred from the empty `Build/Compile` and
    `PKGARCH=all` (verified in the 41a1874c Makefile).
  - A `ucode` Makefile change: rebuild `ucode` / `libucode`. The
    toolchain and kernel are reused (inferred, standard OpenWrt).
  - If `PKG_ABI_VERSION` changes (the carried master ucode pin bumps
    `20230711` → `20261009`, verified in the package Makefile / the
    carried patch), every package that links `libucode` has to be
    rebuilt: at least `hostapd`/`wpad`, `rpcd`, `netifd`, `uhttpd`,
    `ucode-mod-*` (verified as dependents by `Depends`/`libucode` in
    the 41a1874c tree). That is still far short of a toolchain or
    kernel rebuild, but it is not "ucode only."
  - `make clean` at the SCALE wrapper level is **not** an incremental
    rebuild: it deletes the whole extract, so the next `build-img` is
    from-scratch (verified).

That is why the default is `SOURCE_PATCH_MODE=apply` (all patches, cheap
advisory check at most, no extra image). A combined without-patch rebuild
happens only when someone sets `SOURCE_PATCH_MODE=trial`. Prefer
package-level rebuilds on a reused tree; bisect only if the combined
test fails.

## Carried patches

| Patch | Why | Runtime test | Known landing (advisory) |
| --- | --- | --- | --- |
| 001-wifi-scripts-iwinfo-wait-for-own-scan.patch | `iwinfo <if> scan` accepted the other radio's scan-done event (backport of openwrt 62d9f2d4f22a) | `wifi_scan_spin_test.sh` `TESTS=B` (early return / 2.4 GHz cells on the 5 GHz scan) | 62d9f2d4f22a |
| 002-ucode-update-to-master-2026-10-28.patch | ucode `nl80211.waitfor()` busy-spin (100% CPU `iwinfo scan` hang at SCALE 23x (March 2026)) and event-socket overrun recovery; master's ucode package | `wifi_scan_spin_test.sh` `TESTS=A` (waitfor spin / hang) | a4e922953c8d (both 520d9f4c and 0bfb7b97) |

Drop a patch when its runtime test PASSes on an image built without it
(`SKIP_SOURCE_PATCHES=…`), regardless of whether that landing commit is
in `OPENWRT_VER`. Confirm flagged patches with one combined without-patch
build, not one image per patch; see the flow above.
