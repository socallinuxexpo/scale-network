#!/usr/bin/env bash
# Source-level advisory check for openwrt/source-patches.
#
#   check_source_patches.sh [--flagged-ids] <openwrt-source-dir> \
#       <source-patches-dir> [repo-root] [--feed name=path ...]
#
# Cheap first step of "is this patch still needed?". It is NOT the
# deciding verdict: the on-device behavioral test is. See
# source-patches/README.md for the full flow.
#
# For each *.patch in <source-patches-dir> (OpenWrt tree) and in
# <source-patches-dir>/feeds/<feed>/ (feed trees), in lexical order:
#   - require a sidecar <stem>.check with a RUNTIME_TEST that detects
#     the bug's behavior (not the presence of this patch);
#   - compare the patch's substantive changes (comments and whitespace
#     ignored) with the unpatched source tree (OPENWRT_VER, or the
#     feed pin such as OPENWRT_PKG_VERSION for the packages feed);
#   - print NEEDED / LIKELY-UPSTREAM / NO-LONGER-APPLIES.
#   - if the sidecar lists LUAC_FILES, run `luac -p` on those files
#     after a temp apply, when `luac` is on the host.
#
# Feed patches are classified against the tree given by
# `--feed <name>=<path>` (or TARGET=feed:<name> in the sidecar, which
# must still have a --feed path). Patches under feeds/<name>/ default
# to TARGET=feed:<name>.
#
# Without-patch images are NOT built here. A flagged result is a report
# only: it never starts a trial build. To try without patches, someone
# must set SOURCE_PATCH_MODE=trial explicitly (see source-patches/README.md).
#
# --flagged-ids: human report on stderr; stdout is a comma-separated list
# of flagged patch ids (or empty). Used by SOURCE_PATCH_MODE=trial when
# SKIP_SOURCE_PATCHES is unset. Feed patches are reported as
# `<feed>/<NNN>` so they do not collide with an OpenWrt-tree id.
#
# Exit 0 if every patch is NEEDED (or there are no patches).
# Exit 2 if any patch is LIKELY-UPSTREAM or NO-LONGER-APPLIES (flag for
# confirmation or human review; not proof the patch can be dropped).
# Exit 1 on missing metadata, a missing runtime test file, a missing
# feed tree, or a failed luac check.
set -euo pipefail

flagged_only=0
if [ "${1:-}" = "--flagged-ids" ]; then
	flagged_only=1
	shift
	# Human output on stderr; stdout reserved for the id list.
	exec 3>&1
	exec 1>&2
fi

src=${1:?usage: $0 [--flagged-ids] <openwrt-source-dir> <source-patches-dir> [repo-root] [--feed name=path ...]}
patches=${2:?usage: $0 [--flagged-ids] <openwrt-source-dir> <source-patches-dir> [repo-root] [--feed name=path ...]}
shift 2
here=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "$here/../.." && pwd)
if [ "${1:-}" != "" ] && [ "${1#--}" = "$1" ]; then
	repo_root=$1
	shift
fi

declare -A FEED_TREE=()
while [ $# -gt 0 ]; do
	case $1 in
	--feed)
		[ "${2:-}" != "" ] || { echo "usage: --feed name=path" >&2; exit 1; }
		spec=$2
		shift 2
		;;
	--feed=*)
		spec=${1#--feed=}
		shift
		;;
	*)
		echo "unknown argument: $1" >&2
		exit 1
		;;
	esac
	name=${spec%%=*}
	path=${spec#*=}
	if [ "$name" = "$spec" ] || [ -z "$name" ] || [ -z "$path" ]; then
		echo "usage: --feed name=path (got '$spec')" >&2
		exit 1
	fi
	FEED_TREE[$name]=$path
done

classify=$here/classify_source_patch.py

[ -d "$src" ] || { echo "no such source dir: $src" >&2; exit 1; }
if [ ! -d "$patches" ]; then
	echo "no source-patches dir: $patches (nothing to check)"
	exit 0
fi
[ -x "$classify" ] || [ -f "$classify" ] || {
	echo "missing classifier: $classify" >&2
	exit 1
}

# Parse KEY=VALUE lines from a sidecar; no shell expansion.
# Values may be unquoted or wrapped in double quotes.
read_check() {
	local file=$1
	unset DESCRIPTION UPSTREAM_OPENWRT UPSTREAM_NOTES RUNTIME_TEST RUNTIME_TEST_ENV TARGET LUAC_FILES
	DESCRIPTION= UPSTREAM_OPENWRT= UPSTREAM_NOTES= RUNTIME_TEST= RUNTIME_TEST_ENV= TARGET= LUAC_FILES=
	while IFS= read -r line || [ -n "$line" ]; do
		case $line in
		''|\#*) continue ;;
		esac
		key=${line%%=*}
		val=${line#*=}
		# strip one layer of double quotes
		if [ "${val#\"}" != "$val" ] && [ "${val%\"}" != "$val" ]; then
			val=${val#\"}
			val=${val%\"}
		fi
		case $key in
		DESCRIPTION|UPSTREAM_OPENWRT|UPSTREAM_NOTES|RUNTIME_TEST|RUNTIME_TEST_ENV|TARGET|LUAC_FILES)
			printf -v "$key" '%s' "$val"
			;;
		esac
	done < "$file"
}

next_action() {
	local status=$1
	case $status in
	LIKELY-UPSTREAM)
		printf '    next: flagged for a combined without-patch confirmation (see summary).\n'
		printf '          Do not build a per-patch image.\n'
		;;
	NO-LONGER-APPLIES)
		printf '    next: human review (make extract / feeds update will fail) and include this id in the\n'
		printf '          combined without-patch confirmation (see summary).\n'
		;;
	NEEDED)
		printf '    next: keep the patch. No extra image on this run. Include it in the\n'
		printf '          combined without-patch confirmation only on an OPENWRT_VER or\n'
		printf '          OPENWRT_PKG_VERSION bump (for feed patches).\n'
		;;
	esac
}

# Paths the patch touches, relative to the tree root (+++ b/...).
patch_paths() {
	local p=$1
	sed -n 's|^+++ b/||p' "$p"
}

# Apply the patch in a temp tree that holds only the files it touches,
# then run `luac -p` on LUAC_FILES. Missing luac is a skip, not an error.
# A syntax failure is an error. $1=source tree, $2=patch, $3=LUAC_FILES.
run_luac_check() {
	local tree=$1 patch=$2 files=$3
	local tmp f rel rc=0
	local -a luac_files=()

	files=${files//,/ }
	read -r -a luac_files <<< "$files"
	if [ ${#luac_files[@]} -eq 0 ]; then
		return 0
	fi
	if ! command -v luac >/dev/null 2>&1; then
		echo "    luac: not available on this host, skipped"
		return 0
	fi

	tmp=$(mktemp -d)
	# shellcheck disable=SC2064
	trap 'rm -rf "$tmp"' RETURN
	while IFS= read -r rel || [ -n "$rel" ]; do
		[ -n "$rel" ] || continue
		[ "$rel" = "/dev/null" ] && continue
		mkdir -p "$tmp/$(dirname "$rel")"
		if [ -f "$tree/$rel" ]; then
			cp -a "$tree/$rel" "$tmp/$rel"
		fi
	done < <(patch_paths "$patch")
	if ! patch -d "$tmp" -p1 --batch --forward --no-backup-if-mismatch -s < "$patch"; then
		# Forward apply can fail when the change is already in the
		# tree (LIKELY-UPSTREAM). Try the files as they stand in $tree.
		echo "    luac: could not temp-apply the patch; checking files in the source tree"
		for f in "${luac_files[@]}"; do
			if [ ! -f "$tree/$f" ]; then
				echo "    ERROR: LUAC_FILES not found in source tree: $f"
				return 1
			fi
			if ! luac -p "$tree/$f"; then
				echo "    ERROR: luac -p failed for $f"
				return 1
			fi
			echo "    luac -p $f: ok"
		done
		return 0
	fi
	for f in "${luac_files[@]}"; do
		if [ ! -f "$tmp/$f" ]; then
			echo "    ERROR: LUAC_FILES not found after applying patch: $f"
			return 1
		fi
		if ! luac -p "$tmp/$f"; then
			echo "    ERROR: luac -p failed for $f"
			return 1
		fi
		echo "    luac -p $f: ok"
	done
	return 0
}

# Collect OpenWrt-tree patches then feed patches, as "path<TAB>scope".
# scope is "openwrt" or the feed name.
shopt -s nullglob
patch_entries=()
for p in "$patches"/*.patch; do
	patch_entries+=("$p	openwrt")
done
if [ -d "$patches/feeds" ]; then
	for feed_dir in "$patches/feeds"/*/; do
		[ -d "$feed_dir" ] || continue
		feed_dir=${feed_dir%/}
		feed=$(basename "$feed_dir")
		for p in "$feed_dir"/*.patch; do
			[ -f "$p" ] || continue
			patch_entries+=("$p	$feed")
		done
	done
fi

if [ ${#patch_entries[@]} -eq 0 ]; then
	echo "no *.patch files in $patches or $patches/feeds/*/"
	exit 0
fi

meta_err=0
followup=0
needed=0
flagged_ids=()
flagged_tests=()
flagged_pkgs=()
all_ids=()
all_tests=()
echo "Source-level advisory check against $src"
echo "On-device behavioral test is the deciding verdict."
echo "Without-patch images are only for OPENWRT_VER / OPENWRT_PKG_VERSION"
echo "bumps or flagged patches, and then only ONE combined image (see summary)."
echo

for entry in "${patch_entries[@]}"; do
	p=${entry%%	*}
	scope=${entry#*	}
	base=$(basename "$p")
	stem=${base%.patch}
	prefix=${stem%%-*}
	check=$(dirname "$p")/$stem.check

	# Id used in SKIP_SOURCE_PATCHES / --flagged-ids. Feed patches are
	# qualified so they cannot be confused with an OpenWrt-tree NNN.
	if [ "$scope" = openwrt ]; then
		id=$prefix
		default_target=openwrt
	else
		id=$scope/$prefix
		default_target=feed:$scope
	fi

	printf '== %s\n' "${p#"$patches"/}"

	if [ ! -f "$check" ]; then
		echo "    ERROR: missing sidecar $stem.check (RUNTIME_TEST is required)"
		meta_err=1
		echo
		continue
	fi
	read_check "$check"

	target=${TARGET:-$default_target}
	tree=$src
	case $target in
	openwrt|"")
		tree=$src
		;;
	feed:*)
		feed=${target#feed:}
		if [ -z "$feed" ] || [ -z "${FEED_TREE[$feed]+x}" ]; then
			echo "    ERROR: TARGET=$target needs --feed $feed=<path> (pristine feed checkout)"
			meta_err=1
			echo
			continue
		fi
		tree=${FEED_TREE[$feed]}
		if [ ! -d "$tree" ]; then
			echo "    ERROR: feed tree not a directory: $tree"
			meta_err=1
			echo
			continue
		fi
		;;
	*)
		echo "    ERROR: unknown TARGET=$target (want openwrt or feed:<name>)"
		meta_err=1
		echo
		continue
		;;
	esac

	if [ -z "$RUNTIME_TEST" ]; then
		echo "    ERROR: $stem.check has no RUNTIME_TEST (must detect the bug's behavior)"
		meta_err=1
		echo
		continue
	fi
	# RUNTIME_TEST is repo-relative, or already absolute
	case $RUNTIME_TEST in
	/*) rpath=$RUNTIME_TEST ;;
	*)  rpath=$repo_root/$RUNTIME_TEST ;;
	esac
	if [ ! -f "$rpath" ]; then
		echo "    ERROR: RUNTIME_TEST not found: $RUNTIME_TEST"
		meta_err=1
		echo
		continue
	fi

	[ -n "$DESCRIPTION" ] && echo "    $DESCRIPTION"
	echo "    target: $target"
	[ -n "$UPSTREAM_OPENWRT" ] && echo "    known landing (advisory): $UPSTREAM_OPENWRT"
	[ -n "$UPSTREAM_NOTES" ] && echo "    $UPSTREAM_NOTES"
	echo "    runtime test: $RUNTIME_TEST${RUNTIME_TEST_ENV:+ ($RUNTIME_TEST_ENV)}"
	pkgs=$(python3 "$classify" --packages "$p")
	[ -n "$pkgs" ] && echo "    packages touched: $pkgs"

	if ! out=$(python3 "$classify" "$tree" "$p"); then
		echo "    ERROR: classifier failed"
		meta_err=1
		echo
		continue
	fi
	status=${out%%$'\t'*}
	reason=${out#*$'\t'}
	echo "    source check: $status"
	echo "    ($reason)"
	next_action "$status"

	if [ -n "$LUAC_FILES" ]; then
		if ! run_luac_check "$tree" "$p" "$LUAC_FILES"; then
			meta_err=1
			echo
			continue
		fi
	fi

	test_line=$RUNTIME_TEST
	[ -n "$RUNTIME_TEST_ENV" ] && test_line="$RUNTIME_TEST_ENV $RUNTIME_TEST"
	all_ids+=("$id")
	all_tests+=("$test_line")
	case $status in
	NEEDED) needed=$((needed + 1)) ;;
	LIKELY-UPSTREAM|NO-LONGER-APPLIES)
		followup=$((followup + 1))
		flagged_ids+=("$id")
		flagged_tests+=("$test_line")
		flagged_pkgs+=("$pkgs")
		;;
	*)
		echo "    ERROR: unexpected status $status"
		meta_err=1
		;;
	esac
	echo
done

echo "Summary: $needed NEEDED, $followup need confirmation or review (of ${#patch_entries[@]} patch(es))"
echo
if [ "$followup" -ne 0 ]; then
	combo_ids=$(IFS=,; echo "${flagged_ids[*]}")
	echo "Combined without-patch confirmation (ONE image or package rebuild, not one per patch):"
	echo "  SKIP_SOURCE_PATCHES=$combo_ids"
	echo "  Packages touched: ${flagged_pkgs[*]}"
	echo "  Tests to run on that image:"
	for t in "${flagged_tests[@]}"; do
		echo "    $t"
	done
	echo "  If you already have a built extract, do NOT 'make clean' (that wipes"
	echo "  the toolchain, staging_dir, build_dir and dl). Reverse the flagged"
	echo "  patches in the tree and rebuild only the packages they touch, then"
	echo "  repack the image. If a PKG_ABI_VERSION changed, also rebuild the"
	echo "  packages that link that library. For a files-only package (e.g."
	echo "  wifi-scripts), installing just that package — or copying the file"
	echo "  onto the AP — is enough."
	echo "  A flagged source check does not start a trial build. To try"
	echo "  without these patches, set SOURCE_PATCH_MODE=trial explicitly:"
	echo "    make extract SOURCE_PATCH_MODE=trial SKIP_SOURCE_PATCHES=$combo_ids && make build-img"
	echo "  Feed patches are applied after 'feeds update'. If the extract already"
	echo "  exists, also 'make clean-feeds' (or delete .feeds-updated and the"
	echo "  feed checkout) so the skip list is honored on the next config."
	echo "  (one image for all flagged ids, not one per patch)."
	echo "  PASS on every test above => drop all flagged patches."
	echo "  FAIL => only then bisect (subset of SKIP_SOURCE_PATCHES, or install"
	echo "  one package) to see which patch is still needed."
	echo
fi
if [ "$needed" -ne 0 ]; then
	echo "On an OPENWRT_VER or OPENWRT_PKG_VERSION bump, confirm the NEEDED"
	echo "  patches the same way, only by setting SOURCE_PATCH_MODE=trial explicitly:"
	echo "    make extract SOURCE_PATCH_MODE=trial SKIP_SOURCE_PATCHES=$(IFS=,; echo "${all_ids[*]}") && make build-img"
	echo "  because the bug may have been fixed another way."
	echo
fi
if [ "$flagged_only" -eq 1 ]; then
	if [ "$followup" -ne 0 ]; then
		printf '%s\n' "$(IFS=,; echo "${flagged_ids[*]}")" >&3
	else
		printf '\n' >&3
	fi
fi
if [ "$meta_err" -ne 0 ]; then
	exit 1
fi
if [ "$followup" -ne 0 ]; then
	exit 2
fi
exit 0
