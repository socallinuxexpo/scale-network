#!/usr/bin/env python3
"""Classify whether a git-style patch's substantive changes are already
present in an unpatched source tree.

Comments and whitespace are ignored: blank hunk lines and comment-only
hunk lines are dropped, and remaining lines are compared with collapsed
whitespace. GNU patch is also tried with --ignore-whitespace, forward
and reverse.

Prints: STATUS<TAB>REASON
  NEEDED            – the patch still applies and the change is absent
  LIKELY-UPSTREAM   – the substantive change appears to be in the tree
  NO-LONGER-APPLIES – the patch does not apply and the change is not
                      clearly present (needs human review)

This is an advisory hint, not a verdict. Exit 0 on a successful
classification, 2 on usage/IO errors.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


def file_kind(path: str) -> str:
    name = path.rsplit("/", 1)[-1]
    if name in {"Makefile", "makefile", "GNUmakefile"} or name.endswith(
        (".mk", ".mak", ".sh", ".bash", ".awk")
    ):
        return "hash"
    if name.endswith(".lua"):
        return "lua"
    if name.endswith((".c", ".h", ".cc", ".cpp", ".cxx", ".uc", ".js", ".ts", ".rs")):
        return "c"
    if name.endswith(".patch"):
        return "raw"
    return "c"


def is_nonsubstantive(kind: str, text: str) -> bool:
    s = text.strip()
    if not s:
        return True
    if kind == "raw":
        return False
    if kind == "hash":
        return s.startswith("#")
    if kind == "lua":
        return s.startswith("--")
    # C-like: // comments and typical block-comment lines. '#include' etc. stay.
    if s.startswith("//"):
        return True
    if s.startswith(("/*", "*/")):
        return True
    # Comment continuation: "* text" or lone "*", but not "*ptr" / "*=" / "*)"
    return s.startswith("*") and (len(s) == 1 or s[1] in " \t/")


def normalize(text: str) -> str:
    return " ".join(text.split())


def parse_patch(text: str):
    """Return a list of (path, kind, [(+/- , raw_line), ...]) for each file."""
    files = []
    path = None
    kind = "raw"
    changes: list[tuple[str, str]] = []
    in_hunk = False

    def flush():
        nonlocal path, kind, changes, in_hunk
        if path is not None:
            files.append((path, kind, changes))
        path, kind, changes, in_hunk = None, "raw", [], False

    for line in text.splitlines():
        if line.startswith("diff --git "):
            flush()
            m = re.search(r" b/(.+)$", line)
            path = m.group(1) if m else None
            kind = file_kind(path or "")
            changes, in_hunk = [], False
        elif line.startswith("+++ "):
            rest = line[4:]
            if rest.startswith("b/"):
                path = rest[2:].split("\t", 1)[0]
                kind = file_kind(path)
        elif line.startswith("--- "):
            rest = line[4:]
            if path is None and rest.startswith("a/"):
                path = rest[2:].split("\t", 1)[0]
                kind = file_kind(path)
        elif line == "--" or line.startswith("-- "):
            # git format-patch signature; not part of the diff
            break
        elif line.startswith("@@"):
            in_hunk = True
        elif in_hunk and line and line[0] in "+-":
            changes.append((line[0], line[1:]))
        elif in_hunk and line.startswith("\\"):
            pass
    flush()
    return files


def read_target(src: Path, rel: str) -> str | None:
    p = src / rel
    if not p.is_file():
        return None
    try:
        return p.read_text(errors="replace")
    except OSError:
        return None


def content_status(src: Path, patch_text: str) -> tuple[str, str]:
    """Return (present|absent|mixed|none, reason) from substantive line presence."""
    files = parse_patch(patch_text)
    if not files:
        return "none", "no file hunks in patch"

    votes = []
    notes = []
    for rel, kind, changes in files:
        added = [
            normalize(t)
            for op, t in changes
            if op == "+" and not is_nonsubstantive(kind, t)
        ]
        removed = [
            normalize(t)
            for op, t in changes
            if op == "-" and not is_nonsubstantive(kind, t)
        ]
        added = [t for t in added if t]
        removed = [t for t in removed if t]

        target = read_target(src, rel)

        if not added and not removed:
            notes.append(f"{rel}: no substantive lines")
            continue

        if target is None:
            if added and not removed:
                votes.append("absent")
                notes.append(f"{rel}: new file missing")
            elif removed and not added:
                votes.append("present")
                notes.append(f"{rel}: deleted file already absent")
            else:
                votes.append("mixed")
                notes.append(f"{rel}: file missing, patch also modifies it")
            continue

        target_norm = [
            normalize(line)
            for line in target.splitlines()
            if not is_nonsubstantive(kind, line)
        ]
        target_set = {t for t in target_norm if t}

        def all_in(lines: list[str], target_set: set[str] = target_set) -> bool:
            return all(line in target_set for line in lines)

        def none_in(lines: list[str], target_set: set[str] = target_set) -> bool:
            return all(line not in target_set for line in lines)

        if added and removed:
            if all_in(added) and none_in(removed):
                votes.append("present")
                notes.append(f"{rel}: added lines present, removed lines gone")
            elif none_in(added) and all_in(removed):
                votes.append("absent")
                notes.append(f"{rel}: change not in tree")
            else:
                votes.append("mixed")
                notes.append(f"{rel}: partial / drifted substantive overlap")
        elif added:
            if all_in(added):
                votes.append("present")
                notes.append(f"{rel}: added lines already present")
            elif none_in(added):
                votes.append("absent")
                notes.append(f"{rel}: added lines absent")
            else:
                votes.append("mixed")
                notes.append(f"{rel}: some added lines already present")
        else:
            if none_in(removed):
                votes.append("present")
                notes.append(f"{rel}: removed lines already gone")
            elif all_in(removed):
                votes.append("absent")
                notes.append(f"{rel}: removed lines still present")
            else:
                votes.append("mixed")
                notes.append(f"{rel}: some removed lines still present")

    if not votes:
        return "none", "; ".join(notes) or "no substantive code changes"
    if all(v == "present" for v in votes):
        return "present", "; ".join(notes)
    if all(v == "absent" for v in votes):
        return "absent", "; ".join(notes)
    return "mixed", "; ".join(notes)


def run_patch(src: Path, patch_text: str, reverse: bool) -> tuple[bool, str]:
    """Whitespace-ignoring dry-run apply. Do not use --batch: GNU patch
    then treats 'Unreversed patch detected' as success by ignoring -R
    and applying the patch forward.
    """
    import tempfile

    # -i so the patch is not on stdin; stdin is /dev/null so the default
    # answer to "Ignore -R?" / "Assume -R?" is no.
    with tempfile.NamedTemporaryFile("w", suffix=".patch", delete=False) as tmp:
        tmp.write(patch_text)
        tmp_path = tmp.name
    cmd = [
        "patch",
        "-d",
        str(src),
        "-p1",
        "--dry-run",
        "--ignore-whitespace",
        "--no-backup-if-mismatch",
        "-i",
        tmp_path,
    ]
    if reverse:
        cmd.append("--reverse")
    try:
        proc = subprocess.run(
            cmd,
            stdin=subprocess.DEVNULL,
            text=True,
            capture_output=True,
            check=False,
        )
    finally:
        Path(tmp_path).unlink(missing_ok=True)
    out = (proc.stdout or "") + (proc.stderr or "")
    out_flat = " ".join(out.split())
    # Belt and suspenders: any of these means the requested direction failed.
    failed_markers = (
        "Unreversed patch detected",
        "Ignoring -R",
        "Assume -R?",
        "hunk ignored",
        "hunks ignored",
    )
    ok = proc.returncode == 0 and not any(m in out for m in failed_markers)
    return ok, out_flat


def classify(src: Path, patch_text: str) -> tuple[str, str]:
    fwd_ok, fwd_out = run_patch(src, patch_text, reverse=False)
    rev_ok, rev_out = run_patch(src, patch_text, reverse=True)
    content, content_reason = content_status(src, patch_text)

    parts = [
        f"forward-apply={'ok' if fwd_ok else 'fail'}",
    ]
    if fwd_out:
        parts.append(f"fwd:{fwd_out}")
    parts.append(f"reverse-apply={'ok' if rev_ok else 'fail'}")
    if rev_out:
        parts.append(f"rev:{rev_out}")
    parts.append(f"substantive={content} ({content_reason})")
    reason = "; ".join(parts)

    # If the patch still applies, the hunks are not in the tree at those
    # locations. Treat as NEEDED even if similar lines exist elsewhere.
    if fwd_ok and not rev_ok:
        return "NEEDED", reason
    if rev_ok or content == "present":
        return "LIKELY-UPSTREAM", reason
    if fwd_ok:
        return "NEEDED", reason
    return "NO-LONGER-APPLIES", reason


def package_from_path(rel: str) -> str | None:
    """OpenWrt package name from a path in the OpenWrt tree or a feed.

    OpenWrt tree: package/<category>/.../<pkg>/{Makefile,patches,files,files-*,src,...}.
    Packages feed: <category>/.../<pkg>/{Makefile,patches,files,files-*,src,...}.
    Walk from the left and take the component just before a terminal one, so
    package/.../wifi-scripts/files-ucode/usr/share/ucode/foo.uc is wifi-scripts,
    not ucode, and utils/prometheus-node-exporter-lua/files/... is
    prometheus-node-exporter-lua.
    """
    parts = rel.split("/")
    if not parts:
        return None
    if parts[0] == "package":
        rest = parts[1:]
        allow_trailing_file = True
    else:
        # Feed layout has no leading "package/". Require a real terminal
        # marker so a random path is not guessed as a package name.
        rest = parts
        allow_trailing_file = False
    terminal = {"patches", "src", "files", "Makefile"}
    for i, comp in enumerate(rest):
        is_terminal = comp in terminal or comp.startswith("files-")
        if (
            not is_terminal
            and allow_trailing_file
            and i + 1 == len(rest)
            and "." in comp
        ):
            is_terminal = True
        if is_terminal:
            return rest[i - 1] if i >= 1 else None
    return rest[-1] if (rest and allow_trailing_file) else None


def packages_touched(patch_text: str) -> list[str]:
    """Best-effort OpenWrt package names from diff paths."""
    found: list[str] = []
    for rel, _kind, _changes in parse_patch(patch_text):
        name = package_from_path(rel)
        if name and name not in found:
            found.append(name)
    return found


def main(argv: list[str]) -> int:
    if len(argv) == 3 and argv[1] == "--packages":
        patch_path = Path(argv[2])
        if not patch_path.is_file():
            sys.stderr.write(f"no such patch: {patch_path}\n")
            return 2
        pkgs = packages_touched(patch_path.read_text(errors="replace"))
        sys.stdout.write(" ".join(pkgs) + "\n")
        return 0
    if len(argv) != 3:
        sys.stderr.write(
            "usage: classify_source_patch.py <openwrt-source-dir> <patch-file>\n"
            "       classify_source_patch.py --packages <patch-file>\n"
        )
        return 2
    src = Path(argv[1])
    patch_path = Path(argv[2])
    if not src.is_dir():
        sys.stderr.write(f"no such source dir: {src}\n")
        return 2
    if not patch_path.is_file():
        sys.stderr.write(f"no such patch: {patch_path}\n")
        return 2
    text = patch_path.read_text(errors="replace")
    status, reason = classify(src, text)
    sys.stdout.write(f"{status}\t{reason}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
