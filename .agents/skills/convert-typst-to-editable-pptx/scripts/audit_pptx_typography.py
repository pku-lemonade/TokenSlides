#!/usr/bin/env python3
"""Audit effective text sizes in a PowerPoint OOXML package.

The script reads DrawingML directly and uses only the Python standard library.
It reports the point size inherited by each visible run from run, paragraph, or
list-level properties. Optional policies turn the report into an acceptance
gate for point-exact Typst-to-PowerPoint reconstruction.
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
from collections import Counter
from pathlib import Path
from typing import Any, Iterable
from urllib.parse import unquote


NS = {
    "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
    "c": "http://schemas.openxmlformats.org/drawingml/2006/chart",
    "p": "http://schemas.openxmlformats.org/presentationml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    "pr": "http://schemas.openxmlformats.org/package/2006/relationships",
}

A = "{%s}" % NS["a"]
P = "{%s}" % NS["p"]
R = "{%s}" % NS["r"]
TEXT_OBJECT_TAGS = {
    P + "sp": "shape",
    P + "cxnSp": "connector",
    P + "graphicFrame": "graphic-frame",
    P + "pic": "picture",
}
AUTOFIT_TAGS = {
    A + "noAutofit": "none",
    A + "normAutofit": "shrink-text",
    A + "spAutoFit": "resize-shape",
}
POINTS_PER_CENTIPOINT = 0.01


class AuditError(Exception):
    """A user-facing problem with the input package or policy."""


def natural_slide_key(path: str) -> tuple[int, str]:
    stem = posixpath.basename(path).removesuffix(".xml")
    suffix = stem.removeprefix("slide")
    return (int(suffix), path) if suffix.isdigit() else (sys.maxsize, path)


def package_path(source_part: str, target: str) -> str:
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
) -> dict[str, dict[str, str]]:
    rel_path = relationship_part(source_part)
    try:
        root = ET.fromstring(archive.read(rel_path))
    except KeyError:
        return {}
    except ET.ParseError as exc:
        raise AuditError(f"invalid XML in {rel_path}: {exc}") from exc

    relationships: dict[str, dict[str, str]] = {}
    for rel in root.findall("pr:Relationship", NS):
        rel_id = rel.get("Id")
        target = rel.get("Target")
        if not rel_id or target is None:
            continue
        external = rel.get("TargetMode", "").lower() == "external"
        relationships[rel_id] = {
            "type": rel.get("Type", "").rsplit("/", 1)[-1],
            "target": target,
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
    return sorted(
        (
            name
            for name in archive.namelist()
            if name.startswith("ppt/slides/slide") and name.endswith(".xml")
        ),
        key=natural_slide_key,
    )


def object_identity(element: ET.Element) -> tuple[str, str]:
    paths = {
        P + "sp": "p:nvSpPr/p:cNvPr",
        P + "cxnSp": "p:nvCxnSpPr/p:cNvPr",
        P + "graphicFrame": "p:nvGraphicFramePr/p:cNvPr",
        P + "pic": "p:nvPicPr/p:cNvPr",
    }
    props = element.find(paths[element.tag], NS)
    if props is None:
        return "", "<unnamed>"
    return props.get("id", ""), props.get("name", "") or "<unnamed>"


def text_bodies(element: ET.Element) -> Iterable[ET.Element]:
    for node in element.iter():
        if node.tag in {P + "txBody", A + "txBody"}:
            yield node


def autofit_mode(body: ET.Element) -> str:
    body_props = body.find("a:bodyPr", NS)
    if body_props is None:
        return "inherited"
    for child in body_props:
        mode = AUTOFIT_TAGS.get(child.tag)
        if mode:
            return mode
    return "inherited"


def centipoints(element: ET.Element | None) -> int | None:
    if element is None:
        return None
    raw = element.get("sz")
    if raw is None:
        return None
    try:
        value = int(raw)
    except ValueError as exc:
        raise AuditError(f"invalid DrawingML font size sz={raw!r}") from exc
    if value <= 0:
        raise AuditError(f"DrawingML font size must be positive: sz={raw!r}")
    return value


def list_default(
    body: ET.Element, paragraph_properties: ET.Element | None
) -> tuple[int | None, str | None]:
    try:
        level = int(paragraph_properties.get("lvl", "0")) if paragraph_properties is not None else 0
    except ValueError:
        level = 0
    level = min(max(level, 0), 8) + 1
    default = body.find(f"a:lstStyle/a:lvl{level}pPr/a:defRPr", NS)
    size = centipoints(default)
    return size, f"list-level-{level}" if size is not None else None


def run_size(
    run: ET.Element,
    paragraph_default: int | None,
    list_size: int | None,
) -> tuple[int | None, str]:
    run_properties = run.find("a:rPr", NS)
    size = centipoints(run_properties)
    if size is not None:
        return size, "run"
    if paragraph_default is not None:
        return paragraph_default, "paragraph"
    if list_size is not None:
        return list_size, "list"
    return None, "inherited-outside-slide"


def inspect_slide(root: ET.Element, slide_number: int, slide_part: str) -> dict[str, Any]:
    runs: list[dict[str, Any]] = []
    bodies: list[dict[str, Any]] = []
    object_count = 0

    for element in root.iter():
        object_type = TEXT_OBJECT_TAGS.get(element.tag)
        if object_type is None:
            continue
        object_count += 1
        object_id, object_name = object_identity(element)
        for body_index, body in enumerate(text_bodies(element), 1):
            mode = autofit_mode(body)
            body_record = {
                "slide_number": slide_number,
                "object_type": object_type,
                "object_id": object_id,
                "object_name": object_name,
                "body_index": body_index,
                "autofit": mode,
            }
            bodies.append(body_record)
            paragraphs = body.findall("a:p", NS)
            for paragraph_index, paragraph in enumerate(paragraphs, 1):
                paragraph_properties = paragraph.find("a:pPr", NS)
                paragraph_default = centipoints(
                    paragraph_properties.find("a:defRPr", NS)
                    if paragraph_properties is not None
                    else None
                )
                list_size, list_source = list_default(body, paragraph_properties)
                visible_runs = [
                    child
                    for child in paragraph
                    if child.tag in {A + "r", A + "fld"}
                    and any((text.text or "") for text in child.iter(A + "t"))
                ]
                paragraph_text = "".join(
                    text.text or ""
                    for run in visible_runs
                    for text in run.iter(A + "t")
                )
                for run_index, run in enumerate(visible_runs, 1):
                    text = "".join(node.text or "" for node in run.iter(A + "t"))
                    if not text:
                        continue
                    size, source = run_size(run, paragraph_default, list_size)
                    runs.append(
                        {
                            **body_record,
                            "paragraph_index": paragraph_index,
                            "run_index": run_index,
                            "text": text,
                            "paragraph_text": paragraph_text,
                            "size_centipoints": size,
                            "point_size": (
                                round(size * POINTS_PER_CENTIPOINT, 2)
                                if size is not None
                                else None
                            ),
                            "size_source": list_source if source == "list" else source,
                        }
                    )

    return {
        "slide_number": slide_number,
        "part": slide_part,
        "object_count": object_count,
        "text_bodies": bodies,
        "runs": runs,
    }


def chart_parts_for_slide(
    archive: zipfile.ZipFile, slide_part: str
) -> list[str]:
    return sorted(
        {
            rel["package_path"]
            for rel in read_relationships(archive, slide_part).values()
            if rel["type"] == "chart" and rel["package_path"]
        }
    )


def inspect_chart(root: ET.Element, slide_number: int, chart_part: str) -> list[dict[str, Any]]:
    """Extract explicitly sized text from a chart part as pseudo-runs.

    Chart text inherits through chart styles and theme defaults that this
    audit does not model, so only explicit `sz` values are checked; charts
    with no explicit size surface in the `chart_parts_without_sizes` summary.
    """

    runs: list[dict[str, Any]] = []
    chart_name = posixpath.basename(chart_part)
    for node in root.iter():
        if node.tag not in {A + "rPr", A + "defRPr"}:
            continue
        size = centipoints(node)
        if size is None:
            continue
        runs.append(
            {
                "slide_number": slide_number,
                "object_type": "chart",
                "object_id": "",
                "object_name": chart_name,
                "body_index": 1,
                "autofit": "inherited",
                "paragraph_index": 0,
                "run_index": len(runs) + 1,
                "text": f"<chart {local_name(node.tag)}>",
                "paragraph_text": "",
                "size_centipoints": size,
                "point_size": round(size * POINTS_PER_CENTIPOINT, 2),
                "size_source": "chart",
            }
        )
    return runs


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def finite_positive(value: Any, context: str) -> float:
    if isinstance(value, bool):
        raise AuditError(f"{context} must be a positive number")
    try:
        parsed = float(value)
    except (TypeError, ValueError) as exc:
        raise AuditError(f"{context} must be a positive number") from exc
    if not math.isfinite(parsed) or parsed <= 0:
        raise AuditError(f"{context} must be a positive number")
    return parsed


def load_policy(path: Path | None) -> dict[str, Any]:
    if path is None:
        return {}
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise AuditError(f"policy file not found: {path}") from exc
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise AuditError(f"cannot read JSON policy {path}: {exc}") from exc
    if not isinstance(raw, dict):
        raise AuditError("policy root must be a JSON object")
    return raw


def normalize_policy(raw: dict[str, Any], args: argparse.Namespace) -> dict[str, Any]:
    allowed_raw = raw.get("allowed_point_sizes", [])
    if not isinstance(allowed_raw, list):
        raise AuditError("policy allowed_point_sizes must be an array")
    allowed = [
        finite_positive(value, "allowed_point_sizes entry") for value in allowed_raw
    ]
    allowed.extend(args.allowed_point_size)

    tolerance = args.tolerance
    if tolerance is None:
        tolerance = raw.get("tolerance_pt", 0.01)
    tolerance = float(tolerance)
    if not math.isfinite(tolerance) or tolerance < 0:
        raise AuditError("tolerance_pt must be a finite, non-negative number")

    expectations_raw = raw.get("expectations", [])
    if not isinstance(expectations_raw, list):
        raise AuditError("policy expectations must be an array")
    expectations: list[dict[str, Any]] = []
    for index, item in enumerate(expectations_raw, 1):
        if not isinstance(item, dict):
            raise AuditError(f"expectation {index} must be an object")
        slide = item.get("slide")
        if not isinstance(slide, int) or isinstance(slide, bool) or slide <= 0:
            raise AuditError(f"expectation {index} requires a positive integer slide")
        selectors = ("object_name", "object_name_regex", "text_contains")
        if not any(isinstance(item.get(key), str) and item[key] for key in selectors):
            raise AuditError(
                f"expectation {index} requires object_name, object_name_regex, or text_contains"
            )
        if "point_size" in item and "point_sizes" in item:
            raise AuditError(
                f"expectation {index} must use point_size or point_sizes, not both"
            )
        expected_raw = (
            item.get("point_sizes")
            if "point_sizes" in item
            else [item.get("point_size")]
        )
        if not isinstance(expected_raw, list) or not expected_raw or expected_raw == [None]:
            raise AuditError(f"expectation {index} requires point_size or point_sizes")
        expected = [
            finite_positive(value, f"expectation {index} point size")
            for value in expected_raw
        ]
        regex = item.get("object_name_regex")
        if regex:
            try:
                re.compile(regex)
            except re.error as exc:
                raise AuditError(
                    f"expectation {index} has invalid object_name_regex: {exc}"
                ) from exc
        expectations.append(
            {
                "index": index,
                "slide": slide,
                "object_name": item.get("object_name"),
                "object_name_regex": regex,
                "text_contains": item.get("text_contains"),
                "point_sizes": expected,
            }
        )

    return {
        "allowed_point_sizes": sorted(set(allowed)),
        "tolerance_pt": tolerance,
        "require_explicit_size": bool(
            args.require_explicit_size or raw.get("require_explicit_size", False)
        ),
        "forbid_autofit": bool(
            args.forbid_autofit or raw.get("forbid_autofit", False)
        ),
        "expectations": expectations,
    }


def near(value: float, candidates: list[float], tolerance: float) -> bool:
    return any(abs(value - candidate) <= tolerance for candidate in candidates)


def expectation_matches(expectation: dict[str, Any], run: dict[str, Any]) -> bool:
    if run["slide_number"] != expectation["slide"]:
        return False
    object_name = expectation["object_name"]
    if object_name is not None and run["object_name"] != object_name:
        return False
    name_regex = expectation["object_name_regex"]
    if name_regex is not None and not re.search(name_regex, run["object_name"]):
        return False
    text_contains = expectation["text_contains"]
    if text_contains is not None and text_contains not in run["paragraph_text"]:
        return False
    return True


def apply_policy(
    slides: list[dict[str, Any]], policy: dict[str, Any]
) -> list[dict[str, Any]]:
    runs = [run for slide in slides for run in slide["runs"]]
    bodies = [body for slide in slides for body in slide["text_bodies"]]
    tolerance = policy["tolerance_pt"]
    violations: list[dict[str, Any]] = []

    for run in runs:
        size = run["point_size"]
        if size is None and policy["require_explicit_size"]:
            violations.append(
                {
                    "kind": "missing-explicit-size",
                    "slide_number": run["slide_number"],
                    "object_name": run["object_name"],
                    "text": run["text"],
                }
            )
        elif (
            size is not None
            and policy["allowed_point_sizes"]
            and not near(size, policy["allowed_point_sizes"], tolerance)
        ):
            violations.append(
                {
                    "kind": "point-size-not-allowed",
                    "slide_number": run["slide_number"],
                    "object_name": run["object_name"],
                    "text": run["text"],
                    "actual_point_size": size,
                    "allowed_point_sizes": policy["allowed_point_sizes"],
                }
            )

    if policy["forbid_autofit"]:
        for body in bodies:
            if body["autofit"] in {"shrink-text", "resize-shape"}:
                violations.append(
                    {
                        "kind": "autofit-enabled",
                        "slide_number": body["slide_number"],
                        "object_name": body["object_name"],
                        "autofit": body["autofit"],
                    }
                )

    for expectation in policy["expectations"]:
        matches = [run for run in runs if expectation_matches(expectation, run)]
        if not matches:
            violations.append(
                {
                    "kind": "expectation-unmatched",
                    "expectation": expectation,
                }
            )
            continue
        actual_sizes = sorted(
            {
                run["point_size"]
                for run in matches
                if run["point_size"] is not None
            }
        )
        missing = sum(1 for run in matches if run["point_size"] is None)
        expected_sizes = expectation["point_sizes"]
        unexpected = [
            size for size in actual_sizes if not near(size, expected_sizes, tolerance)
        ]
        absent = [
            size for size in expected_sizes if not near(size, actual_sizes, tolerance)
        ]
        if missing or unexpected or absent:
            violations.append(
                {
                    "kind": "expectation-size-mismatch",
                    "expectation": expectation,
                    "matched_runs": len(matches),
                    "actual_point_sizes": actual_sizes,
                    "missing_explicit_sizes": missing,
                    "unexpected_point_sizes": unexpected,
                    "absent_expected_point_sizes": absent,
                }
            )
    return violations


def audit(pptx_path: Path, policy: dict[str, Any]) -> dict[str, Any]:
    try:
        archive = zipfile.ZipFile(pptx_path)
    except FileNotFoundError as exc:
        raise AuditError(f"file not found: {pptx_path}") from exc
    except (OSError, zipfile.BadZipFile) as exc:
        raise AuditError(f"not a readable PPTX/ZIP package: {pptx_path}: {exc}") from exc

    with archive:
        slide_parts = ordered_slide_parts(archive)
        if not slide_parts:
            raise AuditError("the package contains no slides")
        slides = []
        chart_parts: list[str] = []
        charts_without_sizes: list[str] = []
        for index, part in enumerate(slide_parts, 1):
            slide = inspect_slide(parse_xml(archive, part), index, part)
            for chart_part in chart_parts_for_slide(archive, part):
                chart_parts.append(chart_part)
                chart_runs = inspect_chart(parse_xml(archive, chart_part), index, chart_part)
                if chart_runs:
                    slide["runs"].extend(chart_runs)
                else:
                    charts_without_sizes.append(chart_part)
            slides.append(slide)

    runs = [run for slide in slides for run in slide["runs"]]
    bodies = [body for slide in slides for body in slide["text_bodies"]]
    sizes = Counter(
        run["point_size"] for run in runs if run["point_size"] is not None
    )
    missing = sum(1 for run in runs if run["point_size"] is None)
    autofit = Counter(body["autofit"] for body in bodies)
    violations = apply_policy(slides, policy)
    return {
        "file": str(pptx_path.resolve()),
        "status": "fail" if violations else "pass",
        "policy": policy,
        "summary": {
            "slides": len(slides),
            "text_objects": len(
                {
                    (run["slide_number"], run["object_type"], run["object_id"])
                    for run in runs
                }
            ),
            "text_bodies": len(bodies),
            "visible_runs": len(runs),
            "visible_characters": sum(len(run["text"]) for run in runs),
            "explicit_size_runs": len(runs) - missing,
            "missing_explicit_size_runs": missing,
            "unique_point_sizes": len(sizes),
            "autofit_modes": dict(sorted(autofit.items())),
            "chart_parts": len(chart_parts),
            "chart_parts_without_explicit_sizes": sorted(charts_without_sizes),
            "violations": len(violations),
        },
        "point_size_distribution": [
            {"point_size": size, "run_count": count}
            for size, count in sorted(sizes.items())
        ],
        "slides": slides,
        "violations": violations,
    }


def preview(text: str, limit: int = 48) -> str:
    compact = " ".join(text.split())
    return compact if len(compact) <= limit else compact[: limit - 1] + "..."


def human_report(result: dict[str, Any]) -> str:
    summary = result["summary"]
    lines = [
        f"PPTX typography audit: {result['file']}",
        "",
        "Package totals",
        f"  Slides:                       {summary['slides']}",
        f"  Text objects:                 {summary['text_objects']}",
        f"  Visible runs:                 {summary['visible_runs']} ({summary['visible_characters']} characters)",
        f"  Runs with explicit size:      {summary['explicit_size_runs']}",
        f"  Runs missing explicit size:   {summary['missing_explicit_size_runs']}",
        f"  Unique effective sizes:       {summary['unique_point_sizes']}",
        f"  AutoFit modes:                {summary['autofit_modes']}",
        f"  Chart parts:                  {summary['chart_parts']}",
        "",
        "Effective point-size distribution",
    ]
    if summary["chart_parts_without_explicit_sizes"]:
        lines.insert(
            -2,
            "  Charts with no explicit sizes (inspect manually): "
            + ", ".join(summary["chart_parts_without_explicit_sizes"]),
        )
    for item in result["point_size_distribution"]:
        lines.append(
            f"  {item['point_size']:>6.2f} pt: {item['run_count']:>4} visible run(s)"
        )
    if not result["point_size_distribution"]:
        lines.append("  No explicit effective sizes found.")

    lines.append("")
    if result["violations"]:
        lines.append(f"FAIL: {len(result['violations'])} typography policy violation(s).")
        for violation in result["violations"][:50]:
            kind = violation["kind"]
            if kind == "point-size-not-allowed":
                lines.append(
                    f"  Slide {violation['slide_number']}, {violation['object_name']}: "
                    f"{violation['actual_point_size']:.2f} pt, "
                    f"text {preview(violation['text'])!r}"
                )
            elif kind == "missing-explicit-size":
                lines.append(
                    f"  Slide {violation['slide_number']}, {violation['object_name']}: "
                    f"missing explicit size, text {preview(violation['text'])!r}"
                )
            elif kind == "autofit-enabled":
                lines.append(
                    f"  Slide {violation['slide_number']}, {violation['object_name']}: "
                    f"AutoFit is {violation['autofit']}"
                )
            elif kind == "expectation-unmatched":
                lines.append(
                    f"  Expectation {violation['expectation']['index']} matched no text."
                )
            else:
                lines.append(
                    f"  Expectation {violation['expectation']['index']} mismatch: "
                    f"expected {violation['expectation']['point_sizes']}, "
                    f"actual {violation['actual_point_sizes']}"
                )
        omitted = len(result["violations"]) - 50
        if omitted > 0:
            lines.append(f"  ... {omitted} additional violation(s); use --json for all.")
    else:
        lines.append("PASS: typography policy satisfied.")
    return "\n".join(lines)


def point_size(value: str) -> float:
    try:
        return finite_positive(value, "point size")
    except AuditError as exc:
        raise argparse.ArgumentTypeError(str(exc)) from exc


def non_negative(value: str) -> float:
    try:
        parsed = float(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("must be a non-negative number") from exc
    if not math.isfinite(parsed) or parsed < 0:
        raise argparse.ArgumentTypeError("must be a non-negative number")
    return parsed


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Inspect final PPTX DrawingML font sizes and optionally enforce a "
            "point-size policy derived from the Typst source."
        ),
        epilog=(
            "Exit status is 0 when the policy passes, 1 for typography policy "
            "violations, and 2 for input, package, or policy errors."
        ),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("pptx", type=Path, help="PowerPoint .pptx file to inspect")
    parser.add_argument(
        "--policy",
        type=Path,
        help="JSON file with allowed_point_sizes and/or targeted expectations",
    )
    parser.add_argument(
        "--allowed-point-size",
        type=point_size,
        action="append",
        default=[],
        metavar="PT",
        help="allow this source point size; repeat for multiple sizes",
    )
    parser.add_argument(
        "--tolerance",
        type=non_negative,
        metavar="PT",
        help="absolute point-size tolerance; overrides policy tolerance_pt",
    )
    parser.add_argument(
        "--require-explicit-size",
        action="store_true",
        help="fail visible runs whose size still inherits outside slide XML",
    )
    parser.add_argument(
        "--forbid-autofit",
        action="store_true",
        help="fail shrink-text and resize-shape AutoFit text bodies",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="emit the complete machine-readable audit as JSON",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.pptx.suffix.lower() != ".pptx":
        print(f"error: expected a .pptx file: {args.pptx}", file=sys.stderr)
        return 2
    try:
        policy = normalize_policy(load_policy(args.policy), args)
        result = audit(args.pptx, policy)
    except AuditError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print(human_report(result))
    return 1 if result["violations"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
