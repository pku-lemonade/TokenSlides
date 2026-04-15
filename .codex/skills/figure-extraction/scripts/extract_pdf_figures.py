#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from pathlib import Path


def require_tool(name: str) -> str:
    resolved = shutil.which(name)
    if not resolved:
        raise SystemExit(f"required tool not found in PATH: {name}")
    return resolved


def run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, check=True, text=True, capture_output=True)


def parse_pdfimages_list(text: str) -> list[dict[str, object]]:
    rows = []
    for line in text.splitlines():
        if not line.strip():
            continue
        if line.lstrip().startswith("page") or set(line.strip()) == {"-"}:
            continue
        parts = line.split()
        if len(parts) < 13:
            continue
        rows.append(
            {
                "page": int(parts[0]),
                "num": int(parts[1]),
                "type": parts[2],
                "width": int(parts[3]),
                "height": int(parts[4]),
                "color": parts[5],
                "comp": int(parts[6]),
                "bpc": int(parts[7]),
                "enc": parts[8],
                "interp": parts[9],
                "object_id": int(parts[10]),
                "generation": int(parts[11]),
                "x_ppi": int(parts[12]),
                "y_ppi": int(parts[13]),
                "size": parts[14] if len(parts) > 14 else None,
                "ratio": parts[15] if len(parts) > 15 else None,
            }
        )
    return rows


def cmd_list(args: argparse.Namespace) -> None:
    pdfimages = require_tool("pdfimages")
    pdf = Path(args.pdf).expanduser().resolve()
    proc = run([pdfimages, "-list", str(pdf)])
    rows = parse_pdfimages_list(proc.stdout)
    if args.page is not None:
        rows = [row for row in rows if row["page"] == args.page]
    print(json.dumps({"pdf": str(pdf), "images": rows}, indent=2))


def cmd_extract(args: argparse.Namespace) -> None:
    pdfimages = require_tool("pdfimages")
    pdf = Path(args.pdf).expanduser().resolve()
    outdir = Path(args.outdir).expanduser().resolve()
    outdir.mkdir(parents=True, exist_ok=True)
    prefix = outdir / (args.prefix or pdf.stem)

    cmd = [pdfimages]
    if args.page is not None:
        cmd += ["-f", str(args.page), "-l", str(args.page)]
    elif args.first_page is not None or args.last_page is not None:
        if args.first_page is not None:
            cmd += ["-f", str(args.first_page)]
        if args.last_page is not None:
            cmd += ["-l", str(args.last_page)]
    cmd += ["-p"]
    cmd += ["-all" if args.native else "-png"]
    cmd += [str(pdf), str(prefix)]
    run(cmd)

    files = sorted(path.name for path in outdir.glob(f"{prefix.name}*"))
    print(json.dumps({"pdf": str(pdf), "outdir": str(outdir), "files": files}, indent=2))


def cmd_render_page(args: argparse.Namespace) -> None:
    pdftocairo = require_tool("pdftocairo")
    pdf = Path(args.pdf).expanduser().resolve()
    out = Path(args.out).expanduser().resolve()
    out.parent.mkdir(parents=True, exist_ok=True)

    cmd = [pdftocairo]
    if args.format == "svg":
        cmd += ["-svg"]
    elif args.format == "png":
        cmd += ["-png", "-r", str(args.dpi), "-singlefile"]
    elif args.format == "pdf":
        cmd += ["-pdf", "-singlefile"]
    else:
        raise SystemExit(f"unsupported format: {args.format}")

    cmd += ["-f", str(args.page), "-l", str(args.page)]
    if args.x is not None:
        cmd += ["-x", str(args.x)]
    if args.y is not None:
        cmd += ["-y", str(args.y)]
    if args.width is not None:
        cmd += ["-W", str(args.width)]
    if args.height is not None:
        cmd += ["-H", str(args.height)]

    output_target = out if args.format in ("svg", "pdf") else out.with_suffix("")
    cmd += [str(pdf), str(output_target)]
    run(cmd)

    produced = str(out if out.exists() else out.with_suffix("." + args.format))
    print(json.dumps({"pdf": str(pdf), "page": args.page, "output": produced}, indent=2))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Inspect embedded PDF images, extract them natively, or render single pages."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    list_parser = subparsers.add_parser("list", help="List embedded images in a PDF")
    list_parser.add_argument("pdf")
    list_parser.add_argument("--page", type=int)
    list_parser.set_defaults(func=cmd_list)

    extract_parser = subparsers.add_parser("extract", help="Extract embedded images from a PDF")
    extract_parser.add_argument("pdf")
    extract_parser.add_argument("--outdir", required=True)
    extract_parser.add_argument("--prefix")
    extract_parser.add_argument("--page", type=int)
    extract_parser.add_argument("--first-page", type=int)
    extract_parser.add_argument("--last-page", type=int)
    extract_parser.add_argument(
        "--native",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Use pdfimages native extraction (-all). Disable for PNG conversion.",
    )
    extract_parser.set_defaults(func=cmd_extract)

    render_parser = subparsers.add_parser("render-page", help="Render a PDF page as svg/png/pdf")
    render_parser.add_argument("pdf")
    render_parser.add_argument("--page", type=int, required=True)
    render_parser.add_argument("--out", required=True)
    render_parser.add_argument("--format", choices=("svg", "png", "pdf"), default="svg")
    render_parser.add_argument("--dpi", type=int, default=300)
    render_parser.add_argument("--x", type=int)
    render_parser.add_argument("--y", type=int)
    render_parser.add_argument("--width", type=int)
    render_parser.add_argument("--height", type=int)
    render_parser.set_defaults(func=cmd_render_page)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
