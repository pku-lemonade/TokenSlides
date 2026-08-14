#!/usr/bin/env python3
"""Audit whether a PowerPoint deck is composed of editable native objects.

This script reads the OOXML package directly. It does not require PowerPoint,
LibreOffice, python-pptx, or any third-party Python package.
"""

from __future__ import annotations

import argparse
import json
import math
import posixpath
import re
import sys
import xml.etree.ElementTree as ET
import zipfile
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable
from urllib.parse import unquote


NS = {
    "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
    "p": "http://schemas.openxmlformats.org/presentationml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    "pr": "http://schemas.openxmlformats.org/package/2006/relationships",
    "ct": "http://schemas.openxmlformats.org/package/2006/content-types",
}

P = "{%s}" % NS["p"]
A = "{%s}" % NS["a"]
R = "{%s}" % NS["r"]
MC = "{http://schemas.openxmlformats.org/markup-compatibility/2006}"
EMU_PER_INCH = 914400
LINE_FRAGMENT_NAME = re.compile(
    r"^(?P<prefix>.+?)(?:[-_ ]line(?:[-_ ]?\d+))$",
    re.IGNORECASE,
)


class AuditError(Exception):
    """A user-facing problem with the input package."""


@dataclass(frozen=True)
class Transform:
    """Axis-aligned transform from local coordinates to slide coordinates."""

    sx: float = 1.0
    sy: float = 1.0
    tx: float = 0.0
    ty: float = 0.0

    def point(self, x: float, y: float) -> tuple[float, float]:
        return self.tx + self.sx * x, self.ty + self.sy * y


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def natural_slide_key(path: str) -> tuple[int, str]:
    stem = posixpath.basename(path).removesuffix(".xml")
    suffix = stem.removeprefix("slide")
    return (int(suffix), path) if suffix.isdigit() else (sys.maxsize, path)


def package_path(source_part: str, target: str) -> str:
    """Resolve an OOXML relationship target to a normalized package path."""

    target = unquote(target).replace("\\", "/")
    if target.startswith("/"):
        return posixpath.normpath(target.lstrip("/"))
    return posixpath.normpath(posixpath.join(posixpath.dirname(source_part), target))


def relationship_part(source_part: str) -> str:
    directory, filename = posixpath.split(source_part)
    return posixpath.join(directory, "_rels", filename + ".rels")


def parse_xml(archive: zipfile.ZipFile, path: str) -> ET.Element:
    try:
        return ET.fromstring(archive.read(path))
    except KeyError as exc:
        raise AuditError(f"required OOXML part is missing: {path}") from exc
    except ET.ParseError as exc:
        raise AuditError(f"invalid XML in {path}: {exc}") from exc


def read_relationships(
    archive: zipfile.ZipFile, source_part: str
) -> dict[str, dict[str, Any]]:
    rel_path = relationship_part(source_part)
    try:
        root = ET.fromstring(archive.read(rel_path))
    except KeyError:
        return {}
    except ET.ParseError as exc:
        raise AuditError(f"invalid XML in {rel_path}: {exc}") from exc

    relationships: dict[str, dict[str, Any]] = {}
    for rel in root.findall("pr:Relationship", NS):
        rel_id = rel.get("Id")
        target = rel.get("Target")
        if not rel_id or target is None:
            continue
        external = rel.get("TargetMode", "").lower() == "external"
        relationships[rel_id] = {
            "id": rel_id,
            "type": rel.get("Type", "").rsplit("/", 1)[-1],
            "target": target,
            "external": external,
            "package_path": None if external else package_path(source_part, target),
        }
    return relationships


def ordered_slide_parts(archive: zipfile.ZipFile) -> list[str]:
    presentation_path = "ppt/presentation.xml"
    presentation = parse_xml(archive, presentation_path)
    relationships = read_relationships(archive, presentation_path)
    ordered: list[str] = []
    for slide_id in presentation.findall("p:sldIdLst/p:sldId", NS):
        rel_id = slide_id.get(R + "id")
        rel = relationships.get(rel_id or "")
        if rel and rel["package_path"]:
            ordered.append(rel["package_path"])

    if ordered:
        return ordered

    # Be useful with minimally generated packages whose presentation rels are
    # incomplete, while retaining a deterministic order.
    return sorted(
        (
            name
            for name in archive.namelist()
            if name.startswith("ppt/slides/slide") and name.endswith(".xml")
        ),
        key=natural_slide_key,
    )


def slide_size(archive: zipfile.ZipFile) -> tuple[int, int]:
    presentation = parse_xml(archive, "ppt/presentation.xml")
    size = presentation.find("p:sldSz", NS)
    if size is None:
        raise AuditError("ppt/presentation.xml has no p:sldSz slide dimensions")
    try:
        width = int(size.get("cx", ""))
        height = int(size.get("cy", ""))
    except ValueError as exc:
        raise AuditError("slide dimensions are not valid integers") from exc
    if width <= 0 or height <= 0:
        raise AuditError("slide dimensions must be positive")
    return width, height


def content_types(archive: zipfile.ZipFile) -> tuple[dict[str, str], dict[str, str]]:
    root = parse_xml(archive, "[Content_Types].xml")
    defaults = {
        node.get("Extension", "").lower(): node.get("ContentType", "")
        for node in root.findall("ct:Default", NS)
    }
    overrides = {
        node.get("PartName", "").lstrip("/"): node.get("ContentType", "")
        for node in root.findall("ct:Override", NS)
    }
    return defaults, overrides


def group_transform(group: ET.Element, parent: Transform) -> Transform:
    xfrm = group.find("p:grpSpPr/a:xfrm", NS)
    if xfrm is None:
        return parent
    off = xfrm.find("a:off", NS)
    ext = xfrm.find("a:ext", NS)
    child_off = xfrm.find("a:chOff", NS)
    child_ext = xfrm.find("a:chExt", NS)
    if None in (off, ext, child_off, child_ext):
        return parent

    try:
        ox, oy = float(off.get("x", "0")), float(off.get("y", "0"))
        ex, ey = float(ext.get("cx", "0")), float(ext.get("cy", "0"))
        cox, coy = float(child_off.get("x", "0")), float(child_off.get("y", "0"))
        cex, cey = float(child_ext.get("cx", "0")), float(child_ext.get("cy", "0"))
    except ValueError:
        return parent
    if cex == 0 or cey == 0:
        return parent

    scale_x, scale_y = ex / cex, ey / cey
    return Transform(
        sx=parent.sx * scale_x,
        sy=parent.sy * scale_y,
        tx=parent.tx + parent.sx * (ox - cox * scale_x),
        ty=parent.ty + parent.sy * (oy - coy * scale_y),
    )


def resolved_children(element: ET.Element) -> Iterable[ET.Element]:
    """Children with mc:AlternateContent collapsed to the branch a renderer uses.

    PowerPoint renders exactly one of mc:Choice / mc:Fallback, so counting both
    would double-count the same logical object. Prefer the first Choice, fall
    back to Fallback."""

    for child in element:
        if child.tag == MC + "AlternateContent":
            branch = child.find(MC + "Choice")
            if branch is None:
                branch = child.find(MC + "Fallback")
            if branch is not None:
                yield from resolved_children(branch)
        else:
            yield child


def walk_resolved(element: ET.Element) -> Iterable[ET.Element]:
    for child in resolved_children(element):
        yield child
        yield from walk_resolved(child)


def picture_elements(
    element: ET.Element, transform: Transform = Transform()
) -> Iterable[tuple[ET.Element, Transform]]:
    """Yield pictures and their enclosing group transform without duplicates."""

    for child in resolved_children(element):
        if child.tag == P + "pic":
            yield child, transform
        elif child.tag == P + "grpSp":
            yield from picture_elements(child, group_transform(child, transform))
        else:
            yield from picture_elements(child, transform)


def geometry(
    picture: ET.Element,
    transform: Transform,
    slide_width: int,
    slide_height: int,
) -> dict[str, Any] | None:
    xfrm = picture.find("p:spPr/a:xfrm", NS)
    if xfrm is None:
        return None
    off = xfrm.find("a:off", NS)
    ext = xfrm.find("a:ext", NS)
    if off is None or ext is None:
        return None
    try:
        x = float(off.get("x", "0"))
        y = float(off.get("y", "0"))
        width = float(ext.get("cx", "0"))
        height = float(ext.get("cy", "0"))
        rotation = float(xfrm.get("rot", "0")) / 60000.0
    except ValueError:
        return None

    if rotation % 360 != 0:
        # DrawingML rotates about the shape center; use the rotated rect's
        # axis-aligned bounding box so e.g. a 90deg-rotated full-slide picture
        # still trips the coverage thresholds.
        angle = math.radians(rotation)
        bound_w = abs(width * math.cos(angle)) + abs(height * math.sin(angle))
        bound_h = abs(height * math.cos(angle)) + abs(width * math.sin(angle))
        x += (width - bound_w) / 2
        y += (height - bound_h) / 2
        width, height = bound_w, bound_h

    x, y = transform.point(x, y)
    width = abs(width * transform.sx)
    height = abs(height * transform.sy)
    if width <= 0 or height <= 0:
        return None

    visible_width = max(0.0, min(x + width, slide_width) - max(x, 0.0))
    visible_height = max(0.0, min(y + height, slide_height) - max(y, 0.0))
    visible_area = visible_width * visible_height
    slide_area = float(slide_width * slide_height)
    return {
        "x_emu": round(x),
        "y_emu": round(y),
        "width_emu": round(width),
        "height_emu": round(height),
        "x_inches": round(x / EMU_PER_INCH, 4),
        "y_inches": round(y / EMU_PER_INCH, 4),
        "width_inches": round(width / EMU_PER_INCH, 4),
        "height_inches": round(height / EMU_PER_INCH, 4),
        "width_coverage": round(visible_width / slide_width, 6),
        "height_coverage": round(visible_height / slide_height, 6),
        "area_coverage": round(visible_area / slide_area, 6),
        "raw_area_coverage": round((width * height) / slide_area, 6),
    }


def picture_asset_refs(
    picture: ET.Element, relationships: dict[str, dict[str, Any]]
) -> list[dict[str, Any]]:
    refs: list[dict[str, Any]] = []
    seen: set[tuple[str, str]] = set()
    for node in picture.iter():
        rel_id = node.get(R + "embed") or node.get(R + "link")
        if not rel_id:
            continue
        key = (rel_id, local_name(node.tag))
        if key in seen:
            continue
        seen.add(key)
        rel = relationships.get(rel_id)
        refs.append(
            {
                "relationship_id": rel_id,
                "reference_kind": local_name(node.tag),
                "external": bool(rel and rel["external"]),
                "target": rel["target"] if rel else None,
                "package_path": rel["package_path"] if rel else None,
                "relationship_type": rel["type"] if rel else None,
                "resolved": rel is not None,
            }
        )
    return refs


def has_text(element: ET.Element) -> bool:
    return any((node.text or "").strip() for node in element.iter(A + "t"))


def generated_line_fragment_groups(
    root: ET.Element, slide_number: int
) -> list[dict[str, Any]]:
    """Find repeated text boxes named as visual-line fragments of one block."""

    groups: dict[str, list[str]] = defaultdict(list)
    for shape in walk_resolved(root):
        if shape.tag != P + "sp" or not has_text(shape):
            continue
        props = shape.find("p:nvSpPr/p:cNvPr", NS)
        name = props.get("name", "") if props is not None else ""
        match = LINE_FRAGMENT_NAME.match(name)
        if match:
            groups[match.group("prefix")].append(name)

    return [
        {
            "slide_number": slide_number,
            "semantic_prefix": prefix,
            "text_box_count": len(names),
            "object_names": names,
        }
        for prefix, names in sorted(groups.items())
        if len(names) >= 2
    ]


def count_slide_objects(root: ET.Element) -> dict[str, int]:
    nodes = list(walk_resolved(root))
    shapes = [node for node in nodes if node.tag == P + "sp"]
    connectors = [node for node in nodes if node.tag == P + "cxnSp"]
    graphic_frames = [node for node in nodes if node.tag == P + "graphicFrame"]
    pictures = [node for node in nodes if node.tag == P + "pic"]
    text_candidates = shapes + connectors + graphic_frames + pictures
    text_nodes = [node for node in nodes if node.tag == A + "t" and (node.text or "").strip()]
    text_shape_count = sum(1 for shape in shapes if has_text(shape))
    return {
        "text_objects": sum(1 for obj in text_candidates if has_text(obj)),
        "text_runs": len(text_nodes),
        "text_characters": sum(len(node.text or "") for node in text_nodes),
        "native_shapes": len(shapes),
        "text_shapes": text_shape_count,
        "nontext_shapes": len(shapes) - text_shape_count,
        "connectors": len(connectors),
        "graphic_frames": len(graphic_frames),
        "pictures": len(pictures),
        "groups": sum(1 for node in nodes if node.tag == P + "grpSp"),
    }


def inspect_media(
    archive: zipfile.ZipFile,
    references: dict[str, list[dict[str, Any]]],
) -> list[dict[str, Any]]:
    defaults, overrides = content_types(archive)
    media: list[dict[str, Any]] = []
    for info in sorted(
        (
            item
            for item in archive.infolist()
            if item.filename.startswith("ppt/media/") and not item.is_dir()
        ),
        key=lambda item: item.filename,
    ):
        extension = posixpath.splitext(info.filename)[1].lstrip(".").lower()
        refs = references.get(info.filename, [])
        media.append(
            {
                "package_path": info.filename,
                "filename": posixpath.basename(info.filename),
                "extension": extension,
                "content_type": overrides.get(info.filename, defaults.get(extension, "")),
                "size_bytes": info.file_size,
                "reference_count": len(refs),
                "referenced_by": refs,
            }
        )
    return media


def audit(
    pptx_path: Path, coverage_threshold: float, dimension_threshold: float
) -> dict[str, Any]:
    try:
        archive = zipfile.ZipFile(pptx_path)
    except FileNotFoundError as exc:
        raise AuditError(f"file not found: {pptx_path}") from exc
    except (OSError, zipfile.BadZipFile) as exc:
        raise AuditError(f"not a readable PPTX/ZIP package: {pptx_path}: {exc}") from exc

    with archive:
        width, height = slide_size(archive)
        slide_parts = ordered_slide_parts(archive)
        if not slide_parts:
            raise AuditError("the package contains no slides")

        slides: list[dict[str, Any]] = []
        suspicious: list[dict[str, Any]] = []
        line_fragment_groups: list[dict[str, Any]] = []
        media_references: dict[str, list[dict[str, Any]]] = defaultdict(list)
        totals: Counter[str] = Counter()

        for slide_number, slide_part in enumerate(slide_parts, 1):
            root = parse_xml(archive, slide_part)
            relationships = read_relationships(archive, slide_part)
            counts = count_slide_objects(root)
            totals.update(counts)
            slide_line_fragment_groups = generated_line_fragment_groups(
                root, slide_number
            )
            line_fragment_groups.extend(slide_line_fragment_groups)
            pictures: list[dict[str, Any]] = []
            sp_tree = root.find("p:cSld/p:spTree", NS)
            if sp_tree is None:
                pic_elements: Iterable[tuple[ET.Element, Transform]] = ()
            else:
                pic_elements = picture_elements(sp_tree)

            for picture_number, (picture, transform) in enumerate(pic_elements, 1):
                props = picture.find("p:nvPicPr/p:cNvPr", NS)
                name = props.get("name", "") if props is not None else ""
                asset_refs = picture_asset_refs(picture, relationships)
                geom = geometry(picture, transform, width, height)
                is_suspicious = bool(
                    geom
                    and geom["area_coverage"] >= coverage_threshold
                    and geom["width_coverage"] >= dimension_threshold
                    and geom["height_coverage"] >= dimension_threshold
                )
                item = {
                    "picture_number": picture_number,
                    "name": name or "<unnamed>",
                    "geometry": geom,
                    "assets": asset_refs,
                    "suspicious_near_full_slide": is_suspicious,
                }
                pictures.append(item)

                for ref in asset_refs:
                    path = ref["package_path"]
                    if path:
                        media_references[path].append(
                            {
                                "slide_number": slide_number,
                                "picture_number": picture_number,
                                "picture_name": item["name"],
                                "reference_kind": ref["reference_kind"],
                            }
                        )

                if is_suspicious:
                    suspicious.append(
                        {
                            "slide_number": slide_number,
                            "slide_part": slide_part,
                            "picture_number": picture_number,
                            "picture_name": item["name"],
                            "area_coverage": geom["area_coverage"],
                            "width_coverage": geom["width_coverage"],
                            "height_coverage": geom["height_coverage"],
                            "assets": [
                                ref["package_path"] or ref["target"]
                                for ref in asset_refs
                                if ref["package_path"] or ref["target"]
                            ],
                        }
                    )

            slides.append(
                {
                    "slide_number": slide_number,
                    "part": slide_part,
                    "counts": counts,
                    "pictures": pictures,
                    "line_fragment_groups": slide_line_fragment_groups,
                }
            )

        media = inspect_media(archive, media_references)
        totals["slides"] = len(slides)
        totals["media_assets"] = len(media)
        totals["referenced_media_assets"] = sum(
            1 for asset in media if asset["reference_count"] > 0
        )
        totals["unreferenced_media_assets"] = sum(
            1 for asset in media if asset["reference_count"] == 0
        )

    return {
        "file": str(pptx_path.resolve()),
        "status": "fail" if suspicious or line_fragment_groups else "pass",
        "slide_size": {
            "width_emu": width,
            "height_emu": height,
            "width_inches": round(width / EMU_PER_INCH, 4),
            "height_inches": round(height / EMU_PER_INCH, 4),
        },
        "policy": {
            "coverage_threshold": coverage_threshold,
            "dimension_threshold": dimension_threshold,
            "rule": (
                "A picture is suspicious when its visible area coverage meets the "
                "coverage threshold and both visible dimensions meet the dimension threshold."
            ),
        },
        "summary": dict(totals),
        "slides": slides,
        "media": media,
        "suspicious_pictures": suspicious,
        "line_fragment_groups": line_fragment_groups,
        "definitions": {
            "text_objects": "Drawable slide objects containing non-empty DrawingML text.",
            "text_runs": "Non-empty a:t elements.",
            "native_shapes": "p:sp shape elements, including text boxes and styled shapes.",
            "connectors": "p:cxnSp connector elements.",
            "graphic_frames": "p:graphicFrame elements such as tables, charts, and diagrams.",
            "pictures": "p:pic picture elements; one picture may reference multiple fallback assets.",
            "coverage": "Visible picture bounds intersected with the slide bounds.",
            "line_fragment_groups": (
                "Repeated generated text-box names ending in line-N for one "
                "semantic prefix; these indicate PDF visual lines were rebuilt "
                "as separate text boxes."
            ),
        },
    }


def pct(value: float) -> str:
    return f"{value * 100:.1f}%"


def human_report(result: dict[str, Any], allowed: bool) -> str:
    summary = result["summary"]
    size = result["slide_size"]
    lines = [
        f"PPTX editability audit: {result['file']}",
        f"Slide size: {size['width_inches']:.3f} x {size['height_inches']:.3f} in",
        "",
        "Package totals",
        f"  Slides:              {summary['slides']}",
        f"  Text objects:        {summary['text_objects']} ({summary['text_runs']} runs, {summary['text_characters']} characters)",
        f"  Native shapes:       {summary['native_shapes']} ({summary['text_shapes']} with text, {summary['nontext_shapes']} without text)",
        f"  Connectors:          {summary['connectors']}",
        f"  Graphic frames:      {summary['graphic_frames']}",
        f"  Pictures:            {summary['pictures']}",
        f"  Groups:              {summary['groups']}",
        f"  Media assets:        {summary['media_assets']} ({summary['referenced_media_assets']} referenced, {summary['unreferenced_media_assets']} unreferenced)",
        "",
        "Per-slide objects",
    ]
    for slide in result["slides"]:
        counts = slide["counts"]
        lines.append(
            f"  {slide['slide_number']:>3}: text {counts['text_objects']:>3} | "
            f"shapes {counts['native_shapes']:>3} | connectors {counts['connectors']:>3} | "
            f"frames {counts['graphic_frames']:>3} | pictures {counts['pictures']:>3}"
        )

    lines.extend(["", "Picture-to-asset map"])
    picture_count = 0
    for slide in result["slides"]:
        for picture in slide["pictures"]:
            picture_count += 1
            geom = picture["geometry"]
            coverage = (
                f"coverage {pct(geom['area_coverage'])} "
                f"({pct(geom['width_coverage'])} w x {pct(geom['height_coverage'])} h)"
                if geom
                else "coverage unavailable"
            )
            marker = " [SUSPICIOUS]" if picture["suspicious_near_full_slide"] else ""
            lines.append(
                f"  Slide {slide['slide_number']}, picture {picture['picture_number']} "
                f"({picture['name']}): {coverage}{marker}"
            )
            if picture["assets"]:
                for ref in picture["assets"]:
                    target = ref["package_path"] or ref["target"] or "<unresolved>"
                    lines.append(
                        f"      {ref['reference_kind']} {ref['relationship_id']} -> {target}"
                    )
            else:
                lines.append("      no embedded or linked asset relationship found")
    if picture_count == 0:
        lines.append("  No p:pic elements found.")

    lines.extend(["", "Media inventory"])
    if result["media"]:
        for asset in result["media"]:
            lines.append(
                f"  {asset['package_path']}: {asset['size_bytes']} bytes, "
                f"{asset['reference_count']} picture reference(s)"
            )
    else:
        lines.append("  No ppt/media assets found.")

    lines.extend(["", "Semantic text grouping"])
    if result["line_fragment_groups"]:
        lines.append(
            "FAIL: found repeated generated line-fragment text boxes that should "
            "be one semantic text block."
        )
        for group in result["line_fragment_groups"]:
            lines.append(
                f"  Slide {group['slide_number']}, "
                f"{group['semantic_prefix']}: "
                f"{group['text_box_count']} line-level text boxes"
            )
    else:
        lines.append("PASS: no repeated generated line-fragment text boxes found.")

    lines.append("")
    suspicious_count = len(result["suspicious_pictures"])
    if suspicious_count:
        disposition = "ALLOWED" if allowed else "FAIL"
        lines.append(
            f"{disposition}: found {suspicious_count} suspicious near-full-slide picture(s)."
        )
        for item in result["suspicious_pictures"]:
            lines.append(
                f"  Slide {item['slide_number']}, picture {item['picture_number']} "
                f"({item['picture_name']}): {pct(item['area_coverage'])} area coverage"
            )
        if not allowed:
            lines.append(
                "Use --allow-full-slide-pictures only after confirming these are intentional."
            )
    else:
        lines.append("PASS: no suspicious near-full-slide pictures found.")
    return "\n".join(lines)


def ratio(value: str) -> float:
    try:
        parsed = float(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("must be a number between 0 and 1") from exc
    if not math.isfinite(parsed) or not 0 <= parsed <= 1:
        raise argparse.ArgumentTypeError("must be a number between 0 and 1")
    return parsed


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Inspect a .pptx OOXML package for editable text, shapes, connectors, "
            "graphic frames, pictures, and media. Near-full-slide pictures are "
            "treated as suspicious slide-image exports, and repeated generated "
            "line-fragment text boxes are treated as broken semantic grouping."
        ),
        epilog=(
            "Exit status is 0 when the audit passes, 1 when suspicious pictures "
            "or repeated generated line-fragment text boxes are found, and 2 "
            "for input/package errors. Use "
            "--allow-full-slide-pictures to acknowledge intentional full-bleed images."
        ),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("pptx", type=Path, help="PowerPoint .pptx file to inspect")
    parser.add_argument(
        "--json",
        action="store_true",
        help="emit the complete machine-readable audit as JSON",
    )
    parser.add_argument(
        "--allow-full-slide-pictures",
        action="store_true",
        help="report suspicious pictures but return exit status 0",
    )
    parser.add_argument(
        "--coverage-threshold",
        type=ratio,
        default=0.85,
        metavar="RATIO",
        help="minimum visible slide-area coverage for a suspicious picture",
    )
    parser.add_argument(
        "--dimension-threshold",
        type=ratio,
        default=0.90,
        metavar="RATIO",
        help="minimum visible width and height coverage for a suspicious picture",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.pptx.suffix.lower() != ".pptx":
        print(f"error: expected a .pptx file: {args.pptx}", file=sys.stderr)
        return 2
    try:
        result = audit(
            args.pptx,
            coverage_threshold=args.coverage_threshold,
            dimension_threshold=args.dimension_threshold,
        )
    except AuditError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.json:
        output = dict(result)
        output["allowed_full_slide_pictures"] = args.allow_full_slide_pictures
        if result["line_fragment_groups"]:
            output["effective_status"] = "fail"
        elif result["suspicious_pictures"] and args.allow_full_slide_pictures:
            output["effective_status"] = "allowed"
        else:
            output["effective_status"] = result["status"]
        print(json.dumps(output, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print(human_report(result, allowed=args.allow_full_slide_pictures))

    if result["line_fragment_groups"]:
        return 1
    if result["suspicious_pictures"] and not args.allow_full_slide_pictures:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
