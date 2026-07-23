#!/usr/bin/env python3
"""Audit Lemonade-specific native PowerPoint layout and weight contracts."""

from __future__ import annotations

import argparse
import json
import posixpath
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from typing import Iterable
from urllib.parse import unquote


NS = {
    "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
    "p": "http://schemas.openxmlformats.org/presentationml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    "pr": "http://schemas.openxmlformats.org/package/2006/relationships",
}
A = "{%s}" % NS["a"]
P = "{%s}" % NS["p"]
R = "{%s}" % NS["r"]


class AuditError(Exception):
    """A user-facing input or package error."""


def parse_xml(archive: zipfile.ZipFile, path: str) -> ET.Element:
    try:
        return ET.fromstring(archive.read(path))
    except KeyError as exc:
        raise AuditError(f"required OOXML part is missing: {path}") from exc
    except ET.ParseError as exc:
        raise AuditError(f"invalid XML in {path}: {exc}") from exc


def package_path(source_part: str, target: str) -> str:
    target = unquote(target).replace("\\", "/")
    if target.startswith("/"):
        return posixpath.normpath(target.lstrip("/"))
    return posixpath.normpath(posixpath.join(posixpath.dirname(source_part), target))


def relationships(archive: zipfile.ZipFile, source_part: str) -> dict[str, str]:
    directory, filename = posixpath.split(source_part)
    rel_path = posixpath.join(directory, "_rels", filename + ".rels")
    try:
        root = ET.fromstring(archive.read(rel_path))
    except KeyError:
        return {}
    result: dict[str, str] = {}
    for rel in root.findall("pr:Relationship", NS):
        rel_id = rel.get("Id")
        target = rel.get("Target")
        if rel_id and target and rel.get("TargetMode", "").lower() != "external":
            result[rel_id] = package_path(source_part, target)
    return result


def ordered_slide_parts(archive: zipfile.ZipFile) -> list[str]:
    presentation_path = "ppt/presentation.xml"
    root = parse_xml(archive, presentation_path)
    rels = relationships(archive, presentation_path)
    ordered = []
    for slide_id in root.findall("p:sldIdLst/p:sldId", NS):
        target = rels.get(slide_id.get(R + "id", ""))
        if target:
            ordered.append(target)
    if ordered:
        return ordered
    return sorted(
        (
            name
            for name in archive.namelist()
            if name.startswith("ppt/slides/slide") and name.endswith(".xml")
        ),
        key=lambda path: int(posixpath.basename(path)[5:-4]),
    )


def slide_width(archive: zipfile.ZipFile) -> int:
    root = parse_xml(archive, "ppt/presentation.xml")
    size = root.find("p:sldSz", NS)
    if size is None:
        raise AuditError("ppt/presentation.xml has no p:sldSz")
    try:
        width = int(size.get("cx", ""))
    except ValueError as exc:
        raise AuditError("slide width is not an integer") from exc
    if width <= 0:
        raise AuditError("slide width must be positive")
    return width


def shape_name(shape: ET.Element) -> str:
    props = shape.find("p:nvSpPr/p:cNvPr", NS)
    return props.get("name", "") if props is not None else ""


def shape_width(shape: ET.Element) -> int | None:
    ext = shape.find("p:spPr/a:xfrm/a:ext", NS)
    if ext is None:
        return None
    try:
        width = int(ext.get("cx", ""))
    except ValueError:
        return None
    return width if width > 0 else None


def visible_run_bold(shape: ET.Element) -> Iterable[tuple[str, bool]]:
    body = shape.find("p:txBody", NS)
    if body is None:
        return
    for paragraph in body.findall("a:p", NS):
        paragraph_props = paragraph.find("a:pPr", NS)
        default_props = (
            paragraph_props.find("a:defRPr", NS)
            if paragraph_props is not None
            else None
        )
        default_bold = default_props.get("b") if default_props is not None else None
        for run in paragraph:
            if run.tag not in {A + "r", A + "fld"}:
                continue
            text = "".join(node.text or "" for node in run.iter(A + "t"))
            if not text:
                continue
            run_props = run.find("a:rPr", NS)
            bold = run_props.get("b") if run_props is not None else None
            effective = default_bold if bold is None else bold
            yield text, effective in {"1", "true", "on"}


def requires_bold(weight: object) -> bool:
    if isinstance(weight, (int, float)) and not isinstance(weight, bool):
        return weight >= 600
    return str(weight).lower() in {
        "semibold",
        "demibold",
        "bold",
        "extrabold",
        "ultrabold",
        "black",
        "heavy",
    }


def load_profile(path: Path) -> dict:
    try:
        profile = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise AuditError(f"cannot read profile {path}: {exc}") from exc
    if not isinstance(profile, dict):
        raise AuditError("profile root must be an object")
    return profile


def audit(pptx_path: Path, profile_path: Path, min_title_width: float) -> list[str]:
    profile = load_profile(profile_path)
    slide_config = profile.get("slide-config", {})
    outline_config = profile.get("outline-config", {})
    violations: list[str] = []

    try:
        archive = zipfile.ZipFile(pptx_path)
    except (OSError, zipfile.BadZipFile) as exc:
        raise AuditError(f"cannot open PowerPoint package {pptx_path}: {exc}") from exc

    with archive:
        canvas_width = slide_width(archive)
        for slide_number, part in enumerate(ordered_slide_parts(archive), 1):
            root = parse_xml(archive, part)
            shapes = root.findall(".//p:sp", NS)
            names = {shape_name(shape): shape for shape in shapes}

            if slide_config.get("centered-title-full-bleed") is True:
                has_page_number = any(name.startswith("page-number-") for name in names)
                if has_page_number:
                    title_shapes = [
                        shape for name, shape in names.items()
                        if name.startswith("slide-title-")
                    ]
                    if not title_shapes:
                        violations.append(
                            f"slide {slide_number}: page-number exists but slide-title is missing"
                        )
                    for shape in title_shapes:
                        width = shape_width(shape)
                        coverage = (width / canvas_width) if width is not None else 0.0
                        if coverage < min_title_width:
                            violations.append(
                                f"slide {slide_number}, {shape_name(shape)}: title width "
                                f"{coverage:.1%} is below {min_title_width:.1%}"
                            )

            if requires_bold(outline_config.get("entry-weight")):
                for name, shape in names.items():
                    if not name.startswith("section-title-"):
                        continue
                    for text, bold in visible_run_bold(shape):
                        if not bold:
                            violations.append(
                                f"slide {slide_number}, {name}: outline run is not bold: {text!r}"
                            )

    return violations


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("pptx", type=Path)
    parser.add_argument("--profile", type=Path, required=True)
    parser.add_argument(
        "--min-title-width",
        type=float,
        default=0.93,
        help="minimum content-title width as a fraction of the slide (default: 0.93)",
    )
    args = parser.parse_args(argv)

    if not 0 < args.min_title_width <= 1:
        parser.error("--min-title-width must be in (0, 1]")

    try:
        violations = audit(args.pptx, args.profile, args.min_title_width)
    except AuditError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    print(f"Lemonade contract audit: {args.pptx}")
    if violations:
        print("\nFAIL:")
        for violation in violations:
            print(f"  - {violation}")
        return 1
    print("PASS: centered title widths and outline weights match the generated profile.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
