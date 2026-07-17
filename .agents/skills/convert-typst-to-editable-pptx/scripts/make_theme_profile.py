#!/usr/bin/env python3
"""Generate or verify the tracked lemonade theme profile.

Scans `theme/*.typ` for the repo's config convention (every user-tweakable
style dict is a top-level `#let <name>-config`; see AGENTS.md "Config
convention"), builds a Typst probe that imports each config, and queries the
compiled metadata into a JSON profile. New configs are picked up automatically
as long as they follow the convention — this script needs no edits.

Default output is `<skill>/references/theme-profile.json` (tracked in git, so
theme changes show up as reviewable diffs). Use `--check` in QA gates to fail
when the tracked profile is stale.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

CONFIG_PATTERN = re.compile(r"^#let ([a-z][a-z0-9-]*-config) = \(", re.MULTILINE)
PROFILE_LABEL = "lemonade-profile"
PROFILE_VERSION = 1
SKILL_DIR = Path(__file__).resolve().parent.parent


class ProfileError(Exception):
    """A user-facing problem while building the profile."""


def find_root(explicit: Path | None) -> Path:
    if explicit is not None:
        root = explicit.resolve()
        if not (root / "theme" / "base.typ").is_file():
            raise ProfileError(f"--root has no theme/base.typ: {root}")
        return root
    for candidate in (SKILL_DIR, Path.cwd().resolve()):
        for directory in (candidate, *candidate.parents):
            if (directory / "theme" / "base.typ").is_file():
                return directory
    raise ProfileError("cannot find the theme repo root; pass --root")


def scan_configs(root: Path) -> dict[str, str]:
    """Map config name -> theme file, erroring on duplicates."""

    configs: dict[str, str] = {}
    for path in sorted((root / "theme").glob("*.typ")):
        for name in CONFIG_PATTERN.findall(path.read_text(encoding="utf-8")):
            if name in configs:
                raise ProfileError(
                    f"duplicate config `{name}` in theme/{path.name} and {configs[name]}"
                )
            configs[name] = f"theme/{path.name}"
    if not configs:
        raise ProfileError("no `#let <name>-config` declarations found in theme/*.typ")
    return configs


def build_probe(configs: dict[str, str]) -> str:
    by_file: dict[str, list[str]] = {}
    for name, source in sorted(configs.items()):
        by_file.setdefault(source, []).append(name)
    lines = [f'#import "/{source}": {", ".join(names)}' for source, names in sorted(by_file.items())]
    entries = "".join(f"    {name}: {name},\n" for name in sorted(configs))
    lines.append(f"#[#metadata((\n{entries})) <{PROFILE_LABEL}>]")
    return "\n".join(lines) + "\n"


def query_profile(root: Path, configs: dict[str, str]) -> dict:
    scratch_parent = root / "tmp"
    scratch_parent.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(dir=scratch_parent, prefix="theme-probe-") as scratch:
        probe = Path(scratch) / "probe.typ"
        probe.write_text(build_probe(configs), encoding="utf-8")
        result = subprocess.run(
            [
                "typst", "query", "--root", str(root), str(probe),
                f"<{PROFILE_LABEL}>", "--field", "value", "--one",
            ],
            capture_output=True,
            text=True,
        )
    if result.returncode != 0:
        raise ProfileError(
            "typst query failed — a config may contain a non-serializable value "
            f"(function/content) or a theme file may not compile:\n{result.stderr.strip()}"
        )
    values = json.loads(result.stdout)
    return {
        "_meta": {
            "profile-version": PROFILE_VERSION,
            "label": PROFILE_LABEL,
            "convention": "top-level `#let <name>-config` in theme/*.typ (AGENTS.md)",
            "sources": configs,
        },
        **{name: values[name] for name in sorted(configs)},
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--root", type=Path, help="theme repo root (auto-detected by default)")
    parser.add_argument(
        "--output", type=Path, default=SKILL_DIR / "references" / "theme-profile.json",
        help="profile path (default: the skill's tracked references/theme-profile.json)",
    )
    parser.add_argument(
        "--check", action="store_true",
        help="do not write; exit 1 if the tracked profile differs from the theme",
    )
    args = parser.parse_args(argv)

    try:
        root = find_root(args.root)
        profile = query_profile(root, scan_configs(root))
    except ProfileError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    rendered = json.dumps(profile, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    if args.check:
        try:
            existing = json.loads(args.output.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            print(f"STALE: cannot read tracked profile {args.output}: {exc}", file=sys.stderr)
            return 1
        if existing != profile:
            new_keys = sorted(set(profile) - set(existing))
            gone_keys = sorted(set(existing) - set(profile))
            changed = sorted(
                key for key in set(profile) & set(existing) if profile[key] != existing[key]
            )
            print(f"STALE: {args.output} does not match the theme", file=sys.stderr)
            for label, keys in (("added", new_keys), ("removed", gone_keys), ("changed", changed)):
                if keys:
                    print(f"  {label}: {', '.join(keys)}", file=sys.stderr)
            print("Re-run make_theme_profile.py (without --check) and review the diff.", file=sys.stderr)
            return 1
        print(f"OK: {args.output} matches the theme ({len(profile) - 1} configs).")
        return 0

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered, encoding="utf-8")
    print(f"wrote {args.output} ({len(profile) - 1} configs from {root})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
