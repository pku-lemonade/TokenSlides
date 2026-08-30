#!/usr/bin/env python3
"""Derive an audit_pptx_typography.py policy from a generated theme profile.

Reads the disposable profile produced by make_theme_profile.py, selects the
deck's aspect ratio, and emits a policy JSON whose allowed point sizes are the
theme's effective sizes for that aspect:

- every size in `layout-config.<aspect>.font-sizes`;
- title and bottom-band sizes from `title-config` and `thank-you-config`,
  including their Han deltas resolved against `han-config.size-delta`;
- any `--extra-size` for sizes derived in module code rather than configs
  (see references/lemonade-calibration.md for the known list).

Pipe to a scratch file and pass it to audit_pptx_typography.py --policy.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

POINTS = re.compile(r"^(-?\d+(?:\.\d+)?)pt$")


def to_points(value: object, context: str) -> float:
    if isinstance(value, str):
        match = POINTS.match(value)
        if match:
            return float(match.group(1))
    raise SystemExit(f"error: {context} is not a point length: {value!r}")


def resolve_size(value: object, font_sizes: dict[str, object], context: str) -> float:
    if isinstance(value, str) and value in font_sizes:
        return to_points(font_sizes[value], f"font-sizes.{value}")
    return to_points(value, context)


def resolve_delta(value: object, fallback: float | None, context: str) -> float | None:
    if value == "auto":
        return fallback
    if value is None:
        return None
    return to_points(value, context)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--profile", type=Path, required=True,
        help="generated theme profile JSON from the current conversion",
    )
    parser.add_argument("--aspect", required=True, help='deck aspect ratio, e.g. "16-9" or "4-3"')
    parser.add_argument(
        "--extra-size", type=float, action="append", default=[], metavar="PT",
        help="additionally allowed point size; repeat per size",
    )
    parser.add_argument("--tolerance", type=float, default=0.01, metavar="PT")
    parser.add_argument("--output", type=Path, help="write here instead of stdout")
    args = parser.parse_args(argv)

    try:
        profile = json.loads(args.profile.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"error: cannot read profile {args.profile}: {exc}", file=sys.stderr)
        return 2

    layouts = profile.get("layout-config", {})
    if args.aspect not in layouts:
        print(
            f"error: aspect {args.aspect!r} not in profile (has: {', '.join(sorted(layouts))})",
            file=sys.stderr,
        )
        return 2
    font_sizes = layouts[args.aspect].get("font-sizes", {})
    if not font_sizes:
        print(f"error: profile has no font-sizes for {args.aspect}", file=sys.stderr)
        return 2

    sizes = {to_points(value, f"font-sizes.{role}") for role, value in font_sizes.items()}
    han_delta_value = profile.get("han-config", {}).get("size-delta")
    han_delta = None if han_delta_value is None else to_points(han_delta_value, "han-config.size-delta")
    for config_name in ("title-config", "thank-you-config"):
        config = profile.get(config_name, {})

        title = config.get("title", {})
        if title:
            title_size = to_points(font_sizes["title"], "font-sizes.title")
            title_size += to_points(title.get("size-delta", "0pt"), f"{config_name}.title.size-delta")
            sizes.add(title_size)
            delta = resolve_delta(
                title.get("han-size-delta", "auto"),
                han_delta,
                f"{config_name}.title.han-size-delta",
            )
            if delta is not None:
                sizes.add(title_size + delta)

        bottom = config.get("bottom", {})
        if bottom:
            bottom_size = resolve_size(bottom.get("size"), font_sizes, f"{config_name}.bottom.size")
            sizes.add(bottom_size)
            delta = resolve_delta(
                bottom.get("han-size-delta", "auto"),
                han_delta,
                f"{config_name}.bottom.han-size-delta",
            )
            if delta is not None:
                sizes.add(bottom_size + delta)
    sizes.update(args.extra_size)

    policy = {
        "allowed_point_sizes": sorted(sizes),
        "tolerance_pt": args.tolerance,
        "require_explicit_size": True,
        "forbid_autofit": True,
    }
    rendered = json.dumps(policy, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")
        print(f"wrote {args.output} ({len(sizes)} allowed sizes)", file=sys.stderr)
    else:
        print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
