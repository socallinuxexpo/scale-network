#!/usr/bin/env bash
# Apply SCALE local patches to a freshly extracted OpenWrt source tree
# and, with --feeds, to feed checkouts after `feeds update`.
#
#   apply_source_patches.sh [--feeds] <openwrt-source-dir> <source-patches-dir>
#
# Without --feeds, <source-patches-dir>/*.patch are applied in lexical
# order (use an NNN- prefix so the order is obvious) with GNU `patch -p1`
# from the top of the OpenWrt tree. They are git-style diffs against
# OPENWRT_VER (file adds/deletes are supported, GNU patch >= 2.7).
# Subdirectories are not walked; feed patches live under feeds/<name>/
# and are applied only in --feeds mode.
#
# With --feeds, <source-patches-dir>/feeds/<feed>/*.patch are applied
# (lexical order per feed) with `patch -p1` from the top of
# <openwrt-source-dir>/feeds/<feed>/. Run this after `./scripts/feeds
# update` and before `feeds install` or the build. A missing feed
# checkout is fatal. If the checkout is a git repo it is reset to HEAD
# first so a re-run cannot double-apply; on failure it is reset again
# so a half-patched feed is never left behind. Non-git checkouts are
# patched in a temporary copy and swapped in only on success.
#
# SKIP_SOURCE_PATCHES, if set, is a comma- or space-separated list of
# patches to leave out: NNN, NNN-short-description, or the filename.
# Tokens may be qualified so a tree patch and a feed patch that share
# an NNN can be selected independently: `openwrt/001`, `packages/001`,
# `feeds/packages/001`, or `feed:packages:001`. A bare `001` still
# matches every patch with that prefix, in either tree. The Makefile
# honors SKIP_SOURCE_PATCHES only when SOURCE_PATCH_MODE=trial (it is
# never applied automatically). After changing it, re-extract for
# OpenWrt-tree patches (`make clean`, or a different BUILD_DIR), and
# drop the `.feeds-updated` stamp plus the feed checkout for feed
# patches (or `make clean-feeds`).
#
# Any failure (e.g. a patch that no longer applies after an OPENWRT_VER
# or OPENWRT_PKG_VERSION bump) is fatal so the build never silently
# runs without it. A skipped patch is announced and is not an error.
# With no matching *.patch files this script is a no-op.
set -euo pipefail

feeds_mode=0
if [ "${1:-}" = "--feeds" ]; then
	feeds_mode=1
	shift
fi

src=${1:?usage: $0 [--feeds] <openwrt-source-dir> <source-patches-dir>}
patches=${2:?usage: $0 [--feeds] <openwrt-source-dir> <source-patches-dir>}

[ -d "$src" ] || { echo "no such source dir: $src" >&2; exit 1; }
[ -d "$patches" ] || exit 0

skip_raw=${SKIP_SOURCE_PATCHES:-}
skip_raw=${skip_raw//,/ }
read -r -a skip_list <<< "$skip_raw"

# $1 = path to the .patch, $2 = scope ("openwrt" or the feed name)
patch_is_skipped() {
	local p base prefix tok scope tok_scope tok_rest
	p=$(basename "$1")
	base=${p%.patch}
	prefix=${base%%-*}
	scope=$2
	for tok in "${skip_list[@]+"${skip_list[@]}"}"; do
		[ -n "$tok" ] || continue
		tok=${tok#feed:}
		tok=${tok//://}
		case $tok in
		feeds/*) tok=${tok#feeds/} ;;
		openwrt/*)
			tok_scope=openwrt
			tok_rest=${tok#openwrt/}
			;;
		esac
		if [ -z "${tok_scope:-}" ]; then
			case $tok in
			*/*)
				tok_scope=${tok%%/*}
				tok_rest=${tok#*/}
				;;
			*)
				tok_scope=
				tok_rest=$tok
				;;
			esac
		fi
		tok_rest=${tok_rest##*/}
		tok_rest=${tok_rest%.patch}
		if [ -n "$tok_scope" ] && [ "$tok_scope" != "$scope" ]; then
			unset tok_scope tok_rest
			continue
		fi
		if [ "$tok_rest" = "$p" ] || [ "$tok_rest" = "$base" ] || [ "$tok_rest" = "$prefix" ]; then
			return 0
		fi
		unset tok_scope tok_rest
	done
	return 1
}

applied=0
skipped=0

# Apply every *.patch in $1 to tree $2 with skip scope $3. Returns 1
# if GNU patch fails, without aborting the caller so they can clean up.
apply_dir() {
	local pdir=$1 dest=$2 scope=$3
	local p
	shopt -s nullglob
	for p in "$pdir"/*.patch; do
		if patch_is_skipped "$p" "$scope"; then
			echo "Skipping $p (SKIP_SOURCE_PATCHES)"
			skipped=$((skipped + 1))
			continue
		fi
		echo "Applying $p"
		if ! patch -d "$dest" -p1 --batch --forward --no-backup-if-mismatch -s < "$p"; then
			echo "FAILED $p" >&2
			return 1
		fi
		applied=$((applied + 1))
	done
	return 0
}

reset_git_feed() {
	local dest=$1
	git -C "$dest" reset --hard >/dev/null
	git -C "$dest" clean -fd >/dev/null
}

# $1 = feed name, $2 = directory of patches for that feed
apply_feed() {
	local feed=$1 pdir=$2
	local dest=$src/feeds/$feed
	local tmp
	if [ ! -d "$dest" ]; then
		echo "no feed checkout $dest (run './scripts/feeds update' first)" >&2
		exit 1
	fi
	if [ -d "$dest/.git" ]; then
		reset_git_feed "$dest"
		if ! apply_dir "$pdir" "$dest" "$feed"; then
			reset_git_feed "$dest"
			exit 1
		fi
		return 0
	fi
	tmp=${dest}.scale-patch-tmp
	rm -rf "$tmp"
	cp -a "$dest" "$tmp"
	if ! apply_dir "$pdir" "$tmp" "$feed"; then
		rm -rf "$tmp"
		exit 1
	fi
	rm -rf "$dest"
	mv "$tmp" "$dest"
}

shopt -s nullglob
if [ "$feeds_mode" -eq 0 ]; then
	apply_dir "$patches" "$src" openwrt || exit 1
else
	if [ -d "$patches/feeds" ]; then
		for feed_dir in "$patches/feeds"/*/; do
			[ -d "$feed_dir" ] || continue
			feed_dir=${feed_dir%/}
			feed=$(basename "$feed_dir")
			# A README.md (or other non-patch) dir is still visited;
			# apply_dir is a no-op when there are no *.patch files.
			apply_feed "$feed" "$feed_dir"
		done
	fi
fi
if [ "$skipped" -gt 0 ]; then
	echo "Applied $applied patch(es), skipped $skipped"
fi
