#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from collections.abc import Callable
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import fitz  # type: ignore[import-not-found]
from PIL import Image


SCHEMA_VERSION = "academic-paper-to-slides/v1"
ALLOWED_ASSET_TYPES = ("figure", "table", "equation")
ALLOWED_DENSITY_TARGETS = ("low", "medium", "high")
ALLOWED_REVIEW_STATUSES = ("pending", "pass", "warning", "fail")
ALLOWED_RENDER_MODES = ("script", "escape")
FIGURE_FORWARD_ARCHETYPES = {
    "Figure-Led Vertical",
    "Wide or Fat Evidence",
    "Two-Up Comparison",
    "Results Comparison",
    "Motivation / Background",
}
SCRIPT_DIR = Path(__file__).resolve().parent
ARCHETYPE_SPECS_PATH = SCRIPT_DIR.parent / "references" / "archetypes.json"
REFERENCE_ARCHETYPES_PATH = SCRIPT_DIR.parent / "references" / "archetypes.md"
ESCAPE_HINT_MAX_WORDS = 18
ESCAPE_HINT_MAX_CHARS = 140
ESCAPE_FRAGMENT_MAX_CHARS = 5000
FALLBACK_ARCHETYPE_RENDERERS = {
    "Title slide": "title_slide",
    "Outline / Roadmap": "outline_roadmap",
    "Motivation / Background": "motivation_background",
    "Figure-Led Vertical": "figure_led_vertical",
    "Method Overview Side-by-Side": "method_side_by_side",
    "Method Overview With Stacked Evidence": "method_stacked_evidence",
    "Method Cards (2 or 3 Only)": "method_cards",
    "Two-Up Comparison": "comparison",
    "Table-Led Structured Slide": "table_structured",
    "Wide or Fat Evidence": "wide_evidence",
    "Equation-Led Explanation": "equation_led",
    "Results Comparison": "comparison",
    "Conclusion / Takeaways": "conclusion_takeaways",
    "Progress or Status Matrix": "table_structured",
}
DEFAULT_SELECTION_RULES = [
    "Default to simpler archetypes before inventing a custom composition.",
    "Choose by rendered geometry, not by semantic label alone.",
    "On figure-led slides, keep the figure as the main evidence; the text explains why it matters.",
    "Treat a two-line title on a dense evidence slide as a warning sign. Shorten the title before you start shrinking evidence or rewriting every box.",
    "Vary neighboring figure-heavy slides instead of repeating the same side-by-side pattern for an entire section.",
    "If a slide still needs too many words after choosing an archetype, split the material across slides.",
]


def build_fallback_archetype_doc() -> dict[str, Any]:
    archetypes: dict[str, Any] = {}
    for name, renderer in FALLBACK_ARCHETYPE_RENDERERS.items():
        allowed_render_modes = ["script"] if name == "Title slide" else ["script", "escape"]
        archetypes[name] = {
            "renderer": renderer,
            "allowed_render_modes": allowed_render_modes,
            "use_when": [],
            "avoid_when": [],
            "required_fields": {},
            "limits": {},
            "qa_rules": [],
            "fallbacks": [],
            "notes": [],
        }
    return {
        "schema_version": "academic-paper-to-slides/archetypes/v1",
        "selection_rules": list(DEFAULT_SELECTION_RULES),
        "archetypes": archetypes,
    }


def load_archetype_spec_doc() -> dict[str, Any]:
    if not ARCHETYPE_SPECS_PATH.exists():
        return build_fallback_archetype_doc()
    with ARCHETYPE_SPECS_PATH.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def load_archetype_specs() -> dict[str, dict[str, Any]]:
    spec_doc = load_archetype_spec_doc()
    archetypes = spec_doc.get("archetypes")
    if not isinstance(archetypes, dict) or not archetypes:
        return build_fallback_archetype_doc()["archetypes"]
    return archetypes


ARCHETYPE_SPEC_DOC = load_archetype_spec_doc()
ARCHETYPE_SPECS = load_archetype_specs()
KNOWN_ARCHETYPES = set(ARCHETYPE_SPECS)


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def rel_or_abs(path: Path, root: Path | None = None) -> str:
    resolved = path.expanduser().resolve()
    if root is None:
        root = Path.cwd().resolve()
    try:
        return str(resolved.relative_to(root))
    except ValueError:
        return str(resolved)


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def save_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=False)
        handle.write("\n")


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def default_workspace_name(pdf_path: Path) -> str:
    stem = pdf_path.stem.strip().lower().replace(" ", "-")
    stem = "".join(ch if ch.isalnum() or ch in ("-", "_") else "-" for ch in stem)
    stem = stem.strip("-_")
    return stem or "paper"


def notes_paths(workspace: Path) -> dict[str, Path]:
    notes_dir = workspace / "notes"
    return {
        "notes_dir": notes_dir,
        "assets_json": notes_dir / "assets.json",
        "brief_json": notes_dir / "brief.json",
        "slides_json": notes_dir / "slides.json",
        "review_json": notes_dir / "review.json",
        "source_txt": notes_dir / "source.txt",
        "asset_manifest_md": notes_dir / "asset-manifest.md",
        "brief_md": notes_dir / "brief.md",
        "slide_map_md": notes_dir / "slide-map.md",
    }


def ensure_workspace_dirs(workspace: Path) -> None:
    (workspace / "notes").mkdir(parents=True, exist_ok=True)
    (workspace / "assets").mkdir(parents=True, exist_ok=True)


def skeleton_assets_json(workspace: Path, pdf_path: Path, title: str, scenario: str, language: str) -> dict[str, Any]:
    paths = notes_paths(workspace)
    timestamp = iso_now()
    return {
        "schema_version": SCHEMA_VERSION,
        "workspace": rel_or_abs(workspace),
        "source_pdf": rel_or_abs(pdf_path),
        "metadata": {
            "paper_title": title,
            "scenario": scenario,
            "language": language,
            "theme": "lemonade",
            "created_at": timestamp,
            "updated_at": timestamp,
        },
        "source_text": {
            "path": rel_or_abs(paths["source_txt"]),
            "extractor": None,
            "generated_at": None,
            "page_count": None,
            "notes": "",
        },
        "extraction": {
            "status": "pending",
            "priority_order": ["figure", "table", "equation"],
            "notes": "",
        },
        "assets": [],
        "notes": "",
    }


def skeleton_brief_json(workspace: Path, pdf_path: Path, title: str, scenario: str, language: str) -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "workspace": rel_or_abs(workspace),
        "paper": {
            "title": title,
            "authors": [],
            "venue": "",
            "date": "",
            "scenario": scenario,
            "language": language,
            "source_pdf": rel_or_abs(pdf_path),
        },
        "presentation_thesis": "",
        "problem_framing": [],
        "claims": [],
        "mechanisms": [],
        "evaluation_setup": [],
        "quantitative_anchors": [],
        "evidence_map": [],
        "limitations": [],
        "best_asset_matches": [],
        "notes": "",
    }


def skeleton_slides_json(workspace: Path, pdf_path: Path, title: str, scenario: str, language: str) -> dict[str, Any]:
    timestamp = iso_now()
    return {
        "schema_version": SCHEMA_VERSION,
        "workspace": rel_or_abs(workspace),
        "deck": {
            "title": title,
            "scenario": scenario,
            "language": language,
            "theme": "lemonade",
            "source_pdf": rel_or_abs(pdf_path),
            "created_at": timestamp,
            "updated_at": timestamp,
        },
        "archetype_policy": {
            "mode": "fixed-theme",
            "reference": rel_or_abs(ARCHETYPE_SPECS_PATH),
            "derived_doc": rel_or_abs(REFERENCE_ARCHETYPES_PATH),
        },
        "slides": [],
        "notes": "",
    }


def skeleton_review_json(workspace: Path) -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "workspace": rel_or_abs(workspace),
        "deck_pdf": None,
        "generated_at": None,
        "summary": {
            "status": "pending",
            "error_count": 0,
            "warning_count": 0,
        },
        "pages": [],
        "issues": [],
    }


def ensure_json_skeletons(
    workspace: Path,
    pdf_path: Path,
    title: str,
    scenario: str,
    language: str,
    force: bool = False,
) -> dict[str, Path]:
    ensure_workspace_dirs(workspace)
    paths = notes_paths(workspace)
    skeletons = {
        paths["assets_json"]: skeleton_assets_json(workspace, pdf_path, title, scenario, language),
        paths["brief_json"]: skeleton_brief_json(workspace, pdf_path, title, scenario, language),
        paths["slides_json"]: skeleton_slides_json(workspace, pdf_path, title, scenario, language),
        paths["review_json"]: skeleton_review_json(workspace),
    }
    for path, payload in skeletons.items():
        if force or not path.exists():
            save_json(path, payload)
    return paths


def extract_source_with_pdftotext(pdf_path: Path, out_path: Path) -> str | None:
    pdftotext = shutil_which("pdftotext")
    if not pdftotext:
        return None
    subprocess.run(
        [pdftotext, "-layout", str(pdf_path), str(out_path)],
        check=True,
        capture_output=True,
        text=True,
    )
    return "pdftotext-layout"


def extract_source_with_fitz(pdf_path: Path, out_path: Path) -> str:
    with fitz.open(pdf_path) as doc:
        chunks = []
        for index, page in enumerate(doc, start=1):
            chunks.append(f"--- Page {index} ---\n")
            chunks.append(page.get_text("text", sort=True).rstrip())
            chunks.append("\n")
    write_text(out_path, "\n".join(chunks).strip() + "\n")
    return "pymupdf-text"


def shutil_which(binary: str) -> str | None:
    for candidate in os.environ.get("PATH", "").split(os.pathsep):
        path = Path(candidate) / binary
        if path.exists() and os.access(path, os.X_OK):
            return str(path)
    return None


def count_pdf_pages(pdf_path: Path) -> int | None:
    if not pdf_path.exists():
        return None
    with fitz.open(pdf_path) as doc:
        return len(doc)


def load_dimensions(asset_path: Path) -> dict[str, float | int | None]:
    if not asset_path.exists():
        return {"width": None, "height": None, "aspect_ratio": None}

    suffix = asset_path.suffix.lower()
    if suffix in {".png", ".jpg", ".jpeg", ".webp"}:
        with Image.open(asset_path) as image:
            width, height = image.size
    elif suffix == ".pdf":
        with fitz.open(asset_path) as doc:
            rect = doc[0].rect
            width = round(rect.width, 3)
            height = round(rect.height, 3)
    else:
        return {"width": None, "height": None, "aspect_ratio": None}

    if not width or not height:
        return {"width": width, "height": height, "aspect_ratio": None}
    return {
        "width": width,
        "height": height,
        "aspect_ratio": round(float(width) / float(height), 4),
    }


def infer_capture_kind(selection_mode: str | None) -> str | None:
    return selection_mode or None


def format_bbox(value: Any) -> str:
    if isinstance(value, list):
        return "[" + ", ".join(f"{float(part):.3f}" for part in value) + "]"
    return str(value)


def format_simple_item(item: Any) -> str:
    if isinstance(item, dict):
        label = item.get("label") or item.get("name") or item.get("title") or item.get("statement") or "Item"
        value = item.get("value") or item.get("detail") or item.get("note") or ""
        return f"- {label}: {value}" if value else f"- {label}"
    return f"- {item}"


def render_asset_manifest_md(data: dict[str, Any]) -> str:
    metadata = data.get("metadata", {})
    source_text = data.get("source_text", {})
    extraction = data.get("extraction", {})
    assets = sorted(
        data.get("assets", []),
        key=lambda asset: (
            asset.get("asset_type", ""),
            int(asset.get("page") or 0),
            asset.get("asset_id", ""),
        ),
    )
    lines = [
        f"# {metadata.get('paper_title', 'Paper')} Asset Manifest",
        "",
        "Artifact Progress:",
        f"- [{'x' if source_text.get('generated_at') else ' '}] Extract paper text to `notes/source.txt`",
        f"- [{'x' if assets else ' '}] Recover likely visuals and write `notes/assets.json`",
        f"- [{'x' if assets else ' '}] Render `notes/asset-manifest.md` from `notes/assets.json`",
        "",
        f"Scenario: {metadata.get('language', 'unknown')} {metadata.get('scenario', 'unknown')} deck.",
        f"Extraction status: {extraction.get('status', 'pending')}",
        "",
    ]

    if source_text.get("generated_at"):
        lines.append(
            f"Source text: `{source_text.get('path', '')}` via `{source_text.get('extractor', 'unknown')}`."
        )
        if source_text.get("page_count") is not None:
            lines.append(f"Pages: `{source_text.get('page_count')}`")
        lines.append("")

    grouped: dict[str, list[dict[str, Any]]] = {asset_type: [] for asset_type in ALLOWED_ASSET_TYPES}
    for asset in assets:
        grouped.setdefault(asset.get("asset_type", "figure"), []).append(asset)

    for asset_type in ALLOWED_ASSET_TYPES:
        entries = grouped.get(asset_type, [])
        if not entries:
            continue
        lines.append(f"## {asset_type.title()} Assets")
        lines.append("")
        for asset in entries:
            heading = asset.get("label") or asset.get("asset_id") or asset_type.title()
            lines.append(f"### {heading}")
            lines.append(f"- Asset ID: `{asset.get('asset_id', '')}`")
            lines.append(f"- Source file: `{asset.get('source_file', data.get('source_pdf', ''))}`")
            if asset.get("page") is not None:
                lines.append(f"- Page: `{asset.get('page')}`")
            if asset.get("bbox"):
                lines.append(f"- BBox: `{format_bbox(asset.get('bbox'))}`")
            if asset.get("capture_kind"):
                lines.append(f"- Capture kind: `{asset.get('capture_kind')}`")
            if asset.get("primary_output"):
                lines.append(f"- Primary output: `{asset.get('primary_output')}`")
            dimensions = asset.get("dimensions") or {}
            if dimensions.get("width") and dimensions.get("height"):
                dimension_line = f"- Dimensions: {dimensions.get('width')} x {dimensions.get('height')}"
                if dimensions.get("aspect_ratio"):
                    dimension_line += f" (ar={dimensions.get('aspect_ratio')})"
                lines.append(dimension_line)
            if asset.get("normalized_caption"):
                lines.append(f"- Caption: {asset.get('normalized_caption')}")
            if asset.get("source_section"):
                lines.append(f"- Section hint: {asset.get('source_section')}")
            if asset.get("extraction_quality"):
                lines.append(f"- Extraction quality: {asset.get('extraction_quality')}")
            if asset.get("cleanup_needed"):
                lines.append("- Cleanup needed: yes")
            if asset.get("candidate_roles"):
                lines.append(f"- Candidate roles: {', '.join(asset.get('candidate_roles', []))}")
            equation = asset.get("equation") or {}
            if equation.get("text"):
                lines.append(f"- Equation text: `{equation.get('text')}`")
            if equation.get("context"):
                lines.append(f"- Equation context: {equation.get('context')}")
            if asset.get("notes"):
                lines.append(f"- Notes: {asset.get('notes')}")
            lines.append("")

    if assets:
        return "\n".join(lines).rstrip() + "\n"

    lines.extend(
        [
            "## Pending Assets",
            "",
            "No assets are registered yet. Use `paper_artifacts.py upsert-asset` after figure extraction.",
            "",
        ]
    )
    return "\n".join(lines)


def render_brief_md(brief: dict[str, Any]) -> str:
    paper = brief.get("paper", {})
    lines = [
        f"# {paper.get('title', 'Paper')} Brief",
        "",
        "## Paper",
        "",
        f"- Title: {paper.get('title', '')}",
        f"- Authors: {', '.join(paper.get('authors', []))}",
        f"- Venue/status: {paper.get('venue', '')}",
        f"- Date: {paper.get('date', '')}",
        f"- Talk mode: {paper.get('language', '')} {paper.get('scenario', '')} deck",
        "",
    ]

    thesis = brief.get("presentation_thesis")
    if thesis:
        lines.extend(["## Presentation Thesis", "", thesis, ""])

    def emit_list_section(title: str, items: list[Any]) -> None:
        if not items:
            return
        lines.extend([f"## {title}", ""])
        for item in items:
            lines.append(format_simple_item(item))
        lines.append("")

    emit_list_section("Problem Framing", brief.get("problem_framing", []))

    claims = brief.get("claims", [])
    if claims:
        lines.extend(["## Deck-Level Claims", ""])
        for claim in claims:
            if isinstance(claim, dict):
                claim_id = claim.get("claim_id", "")
                statement = claim.get("statement", "")
                prefix = f"{claim_id}: " if claim_id else ""
                lines.append(f"- {prefix}{statement}".rstrip())
                evidence = claim.get("evidence", [])
                if evidence:
                    lines.append(f"  Evidence: {', '.join(str(item) for item in evidence)}")
            else:
                lines.append(f"- {claim}")
        lines.append("")

    emit_list_section("Method Breakdown", brief.get("mechanisms", []))
    emit_list_section("Evaluation Setting", brief.get("evaluation_setup", []))
    emit_list_section("Quantitative Anchors", brief.get("quantitative_anchors", []))

    evidence_map = brief.get("evidence_map", [])
    if evidence_map:
        lines.extend(["## Evidence Map", ""])
        for entry in evidence_map:
            if not isinstance(entry, dict):
                lines.append(f"- {entry}")
                continue
            claim_id = entry.get("claim_id", "claim")
            support = ", ".join(
                f"{item.get('kind')}:{item.get('ref')}" if isinstance(item, dict) else str(item)
                for item in entry.get("support", [])
            )
            lines.append(f"- {claim_id}: {support}")
        lines.append("")

    emit_list_section("Limitations", brief.get("limitations", []))

    if brief.get("best_asset_matches"):
        lines.extend(["## Best Asset-to-Claim Matches", ""])
        for match in brief["best_asset_matches"]:
            if not isinstance(match, dict):
                lines.append(f"- {match}")
                continue
            topic = match.get("topic", "Topic")
            asset_ids = ", ".join(match.get("asset_ids", []))
            lines.append(f"- {topic}: {asset_ids}")
        lines.append("")

    if brief.get("notes"):
        lines.extend(["## Notes", "", str(brief["notes"]), ""])

    return "\n".join(lines).rstrip() + "\n"


def format_slide_evidence(slide: dict[str, Any]) -> str:
    chunks = []
    for item in slide.get("evidence", []):
        if isinstance(item, str):
            chunks.append(item)
            continue
        if not isinstance(item, dict):
            chunks.append(str(item))
            continue
        kind = item.get("kind")
        ref = item.get("ref")
        detail = item.get("detail")
        if kind and ref and detail:
            chunks.append(f"{kind}:{ref} ({detail})")
        elif kind and ref:
            chunks.append(f"{kind}:{ref}")
        elif ref:
            chunks.append(str(ref))
        elif detail:
            chunks.append(str(detail))
    if slide.get("asset_ids"):
        chunks.append(f"assets={', '.join(slide.get('asset_ids', []))}")
    if slide.get("equation_ids"):
        chunks.append(f"equations={', '.join(slide.get('equation_ids', []))}")
    return "; ".join(chunks)


def render_slide_map_md(slides_doc: dict[str, Any]) -> str:
    deck = slides_doc.get("deck", {})
    slides = slides_doc.get("slides", [])
    lines = [
        f"# {deck.get('title', 'Paper')} Slide Map",
        "",
        "| # | Section | Title | Takeaway | Evidence | Archetype | Render | Role | Density |",
        "|---|---|---|---|---|---|---|---|---|",
    ]
    for index, slide in enumerate(slides, start=1):
        lines.append(
            "| {index} | {section} | {title} | {takeaway} | {evidence} | {archetype} | {render_mode} | {role} | {density} |".format(
                index=index,
                section=str(slide.get("section", "")).replace("|", "/"),
                title=str(slide.get("title", "")).replace("|", "/"),
                takeaway=str(slide.get("takeaway", "")).replace("|", "/"),
                evidence=format_slide_evidence(slide).replace("|", "/"),
                archetype=str(slide.get("archetype", "")).replace("|", "/"),
                render_mode=str(slide.get("render_mode", "script")).replace("|", "/"),
                role=str(slide.get("rhetorical_role", "")).replace("|", "/"),
                density=str(slide.get("content_density", "")).replace("|", "/"),
            )
        )
    if not slides:
        lines.append("| 1 |  |  |  |  |  |  |  |  |")
    lines.append("")

    qa_lines = []
    for index, slide in enumerate(slides, start=1):
        expectations = slide.get("qa_expectations", [])
        if not expectations:
            continue
        slide_id = slide.get("slide_id") or f"slide-{index:02d}"
        qa_lines.append(f"- {slide_id}: {', '.join(str(item) for item in expectations)}")
    if qa_lines:
        lines.extend(["## QA Expectations", ""])
        lines.extend(qa_lines)
        lines.append("")

    return "\n".join(lines)


def render_archetypes_reference_md(spec_doc: dict[str, Any]) -> str:
    lines = [
        "<!-- Derived from archetypes.json. Edit the JSON spec, then regenerate this file. -->",
        "",
        "# Slide Archetypes",
        "",
        "Use a small set of reusable compositions. The goal is predictable, readable pages rather than one-off layouts.",
        "",
        "## Selection Rules",
        "",
    ]

    for rule in spec_doc.get("selection_rules", []):
        lines.append(f"- {rule}")
    lines.append("")

    archetypes = spec_doc.get("archetypes", {})
    for name, spec in archetypes.items():
        lines.extend([f"## {name}", ""])

        use_when = spec.get("use_when") or []
        if use_when:
            lines.extend(["Use when:", ""])
            for item in use_when:
                lines.append(f"- {item}")
            lines.append("")

        avoid_when = spec.get("avoid_when") or []
        if avoid_when:
            lines.extend(["Avoid when:", ""])
            for item in avoid_when:
                lines.append(f"- {item}")
            lines.append("")

        lines.extend(["Contract:", ""])
        lines.append(f"- Renderer: `{spec.get('renderer', 'generic')}`")
        render_modes = ", ".join(spec.get("allowed_render_modes", ["script"]))
        lines.append(f"- Allowed render modes: `{render_modes}`")

        required_fields = spec.get("required_fields") or {}
        if required_fields:
            lines.append("- Required fields:")
            for field_name, field_spec in required_fields.items():
                if not isinstance(field_spec, dict):
                    lines.append(f"  - `{field_name}`")
                    continue
                details = []
                if field_spec.get("required"):
                    details.append("required")
                if field_spec.get("min_items") is not None:
                    details.append(f"min_items={field_spec['min_items']}")
                if field_spec.get("max_items") is not None:
                    details.append(f"max_items={field_spec['max_items']}")
                if field_spec.get("asset_id_range"):
                    details.append(f"asset_id_range={field_spec['asset_id_range']}")
                if field_spec.get("allowed_card_counts"):
                    details.append(f"allowed_card_counts={field_spec['allowed_card_counts']}")
                if field_spec.get("asset_id_min_items") is not None:
                    details.append(f"asset_id_min_items={field_spec['asset_id_min_items']}")
                suffix = f": {', '.join(details)}" if details else ""
                lines.append(f"  - `{field_name}`{suffix}")

        limits = spec.get("limits") or {}
        if limits:
            lines.append("- Limits:")
            for key, value in limits.items():
                lines.append(f"  - `{key}`: `{value}`")

        qa_rules = spec.get("qa_rules") or []
        if qa_rules:
            lines.append("- QA rules:")
            for rule in qa_rules:
                lines.append(f"  - {rule}")

        fallbacks = spec.get("fallbacks") or []
        if fallbacks:
            lines.append(f"- Fallbacks: {', '.join(f'`{item}`' for item in fallbacks)}")

        notes = spec.get("notes") or []
        if notes:
            lines.extend(["", "Notes:", ""])
            for note in notes:
                lines.append(f"- {note}")

        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def typst_escape(text: Any) -> str:
    value = str(text or "")
    return (
        value.replace("\\", "\\\\")
        .replace("[", "\\[")
        .replace("]", "\\]")
        .replace("#", "\\#")
    )


def typst_string(text: Any) -> str:
    return str(text or "").replace("\\", "\\\\").replace('"', '\\"')


def typst_value(value: Any, default_unit: str | None = None) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)) and default_unit:
        return f"{value}{default_unit}"
    return str(value)


def typst_tuple(values: list[Any], default_unit: str | None = None) -> str:
    return ", ".join(typst_value(value, default_unit=default_unit) for value in values)


def indent_lines(lines: list[str], prefix: str = "    ") -> list[str]:
    return [f"{prefix}{line}" if line else prefix for line in lines]


def plain_text(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        return "; ".join(part for part in (plain_text(item) for item in value) if part)
    if isinstance(value, dict):
        for key in ("text", "body", "content", "detail", "statement", "title", "label", "value", "name"):
            if value.get(key):
                return plain_text(value.get(key))
        return json.dumps(value, ensure_ascii=False)
    return str(value)


def get_archetype_spec(archetype: str) -> dict[str, Any] | None:
    spec = ARCHETYPE_SPECS.get(archetype)
    return spec if isinstance(spec, dict) else None


def normalize_render_mode(value: Any) -> str:
    mode = str(value or "script").strip().lower()
    return mode if mode in ALLOWED_RENDER_MODES else mode


def escape_hint_issue(hint: str) -> str | None:
    if not hint:
        return "missing escape_hint"
    if len(hint) > ESCAPE_HINT_MAX_CHARS:
        return f"escape_hint exceeds {ESCAPE_HINT_MAX_CHARS} characters"
    if len(hint.split()) > ESCAPE_HINT_MAX_WORDS:
        return f"escape_hint exceeds {ESCAPE_HINT_MAX_WORDS} words"
    return None


def collect_escape_config_issues(slide: dict[str, Any], spec: dict[str, Any] | None) -> list[str]:
    issues: list[str] = []
    if normalize_render_mode(slide.get("render_mode")) != "escape":
        return issues
    hint_issue = escape_hint_issue(plain_text(slide.get("escape_hint")).strip())
    if hint_issue:
        issues.append(hint_issue)
    if spec is None:
        issues.append("unknown archetype for escape render mode")
    else:
        allowed_modes = spec.get("allowed_render_modes") or ["script"]
        if "escape" not in allowed_modes:
            issues.append(f"{slide.get('archetype') or 'slide'} does not allow escape render mode")
    return issues


def summarize_escape_assets(asset_entries: list[dict[str, Any]]) -> list[dict[str, str]]:
    summary = []
    for entry in asset_entries:
        if not entry.get("expr"):
            continue
        summary.append(
            {
                "asset_id": entry["asset_id"],
                "expr": entry["expr"],
                "caption": plain_text(entry.get("caption")),
                "label": plain_text(entry.get("label")),
            }
        )
    return summary


def escape_fragment_stem(slide_id: str) -> str:
    return re.sub(r"[^A-Za-z0-9._-]+", "-", str(slide_id)).strip("-") or "slide"


def escape_fragment_path(slide: dict[str, Any], workspace: Path) -> Path:
    slide_id = slide.get("slide_id") or plain_text(slide.get("title")) or "slide"
    explicit = slide.get("escape_fragment")
    if explicit:
        return resolve_repo_relative(str(explicit), workspace)
    return (workspace / "fragments" / f"{escape_fragment_stem(str(slide_id))}.typ").resolve()


def clean_escape_fragment(fragment: str) -> str:
    text = fragment.strip()
    if "```" in text:
        matches = re.findall(r"```(?:typst)?\s*([\s\S]*?)```", text, flags=re.IGNORECASE)
        if matches:
            text = "\n".join(match.strip() for match in matches if match.strip()).strip()
        else:
            text = re.sub(r"^```(?:typst)?\s*", "", text, flags=re.IGNORECASE)
            text = re.sub(r"\s*```$", "", text)
    return text.strip()


def escape_fragment_issue(fragment: str) -> str | None:
    if not fragment:
        return "escape fragment is empty"
    if len(fragment) > ESCAPE_FRAGMENT_MAX_CHARS:
        return f"escape fragment exceeds {ESCAPE_FRAGMENT_MAX_CHARS} characters"
    forbidden_patterns = {
        r"(?m)^\s*#import\b": "fragment must not import modules",
        r"(?m)^\s*#show\b": "fragment must not change show rules",
        r"(?m)^\s*#set\b": "fragment must not change global settings",
        r"(?m)^\s*#title-slide\b": "fragment must not emit a title slide",
        r"(?m)^\s*=+\s": "fragment must not emit section headings",
    }
    for pattern, message in forbidden_patterns.items():
        if re.search(pattern, fragment):
            return message
    return None


def build_escape_fragment_payload(
    slide: dict[str, Any],
    spec: dict[str, Any] | None,
    asset_entries: list[dict[str, Any]],
    boxes: list[dict[str, Any]],
    bullets: list[Any],
    equations: list[dict[str, Any]],
    deck_sections: list[str],
) -> dict[str, Any]:
    return {
        "slide_id": slide.get("slide_id"),
        "title": slide.get("title"),
        "section": slide.get("section"),
        "archetype": slide.get("archetype"),
        "escape_hint": plain_text(slide.get("escape_hint")).strip(),
        "takeaway": slide.get("takeaway"),
        "rhetorical_role": slide.get("rhetorical_role"),
        "deck_sections": deck_sections,
        "boxes": boxes,
        "bullets": bullets,
        "table": slide.get("table"),
        "cards": slide.get("cards"),
        "roadmap": slide.get("roadmap"),
        "equations": equations,
        "assets": summarize_escape_assets(asset_entries),
        "qa_expectations": slide.get("qa_expectations", []),
        "spec_limits": (spec or {}).get("limits", {}),
        "spec_notes": (spec or {}).get("notes", []),
        "allowed_primitives": [
            "#grid",
            "#imgs",
            "#ibox",
            "#hbox",
            "#nbox",
            "#sbox",
            "#ebox",
            "#pbox",
            "#cbox",
            "#mbox",
            "#table",
            "#v",
            "#align",
        ],
        "forbidden_constructs": [
            "#import",
            "#show",
            "#set",
            "#title-slide",
            "section headings",
        ],
    }


def load_escape_fragment(
    slide: dict[str, Any],
    workspace: Path,
) -> tuple[str | None, Path, str | None]:
    fragment_path = escape_fragment_path(slide, workspace)
    if not fragment_path.exists():
        return None, fragment_path, "fragment file is missing"
    try:
        raw_text = fragment_path.read_text(encoding="utf-8")
    except Exception as exc:
        return None, fragment_path, f"fragment could not be read: {exc}"
    fragment = clean_escape_fragment(raw_text)
    issue = escape_fragment_issue(fragment)
    if issue:
        return None, fragment_path, issue
    return fragment, fragment_path, None


def maybe_render_escape_body(
    slide: dict[str, Any],
    spec: dict[str, Any] | None,
    asset_entries: list[dict[str, Any]],
    boxes: list[dict[str, Any]],
    bullets: list[Any],
    equations: list[dict[str, Any]],
    deck_sections: list[str],
    workspace: Path,
    *,
    disable_escape: bool,
) -> dict[str, Any]:
    report = {
        "used": False,
        "fragment_path": None,
        "body_lines": [],
        "warnings": [],
        "fallback_reason": None,
    }
    if normalize_render_mode(slide.get("render_mode")) != "escape":
        return report

    slide_id = slide.get("slide_id") or plain_text(slide.get("title")) or "slide"
    if disable_escape:
        report["warnings"].append(f"slide {slide_id}: escape render mode disabled; falling back to scripted layout")
        report["fallback_reason"] = "disabled"
        return report

    issues = collect_escape_config_issues(slide, spec)
    if issues:
        report["warnings"].append(
            f"slide {slide_id}: invalid escape configuration ({'; '.join(issues)}); falling back to scripted layout"
        )
        report["fallback_reason"] = "invalid-config"
        return report

    fragment, fragment_path, fragment_issue = load_escape_fragment(slide, workspace)
    if fragment_issue:
        report["warnings"].append(
            f"slide {slide_id}: escape fragment unavailable ({fragment_issue}: {rel_or_abs(fragment_path)}); falling back to scripted layout"
        )
        report["fallback_reason"] = "missing-fragment" if not fragment_path.exists() else "invalid-fragment"
        return report

    report["used"] = True
    report["fragment_path"] = str(fragment_path)
    report["body_lines"] = (fragment or "").splitlines()
    report["warnings"].append(f"slide {slide_id}: escape-hatch triggered")
    return report


def asset_image_expr(asset: dict[str, Any], deck_path: Path, workspace: Path) -> str | None:
    primary_output = asset.get("primary_output")
    if not primary_output:
        return None
    asset_path = resolve_repo_relative(primary_output, workspace)
    suffix = asset_path.suffix.lower()
    if suffix not in {".png", ".jpg", ".jpeg", ".webp", ".svg", ".pdf"}:
        return None
    relative = os.path.relpath(asset_path, deck_path.parent)
    return f'image("{typst_string(relative)}")'


def normalize_caption_mode(value: Any) -> str:
    mode = str(value or "short").strip().lower()
    aliases = {
        "auto": "short",
        "short": "short",
        "brief": "short",
        "label": "short",
        "full": "full",
        "long": "full",
        "none": "none",
        "hide": "none",
        "hidden": "none",
        "omit": "none",
    }
    return aliases.get(mode, "short")


def strip_asset_prefix(label: str) -> str:
    stripped = re.sub(r"^(Figure|Table)\s+[0-9A-Za-z().-]+\s*:\s*", "", label).strip()
    return stripped or label.strip()


def lookup_caption_override(caption_overrides: Any, asset_id: str, index: int) -> tuple[bool, Any]:
    if isinstance(caption_overrides, dict) and asset_id in caption_overrides:
        return True, caption_overrides[asset_id]
    if isinstance(caption_overrides, list) and index < len(caption_overrides):
        return True, caption_overrides[index]
    return False, None


def resolve_asset_caption(
    asset: dict[str, Any],
    asset_id: str,
    *,
    caption_override_present: bool,
    caption_override: Any,
    caption_mode: str,
) -> str:
    if caption_override_present:
        return plain_text(caption_override)
    if caption_mode == "none":
        return ""
    if caption_mode == "full":
        return plain_text(asset.get("normalized_caption") or asset.get("label") or asset_id)

    title = plain_text(asset.get("title")).strip()
    if title:
        return title

    label = plain_text(asset.get("label")).strip()
    if label:
        return strip_asset_prefix(label)

    return plain_text(asset.get("normalized_caption") or asset_id)


def resolve_slide_assets(
    slide: dict[str, Any],
    assets_by_id: dict[str, dict[str, Any]],
    deck_path: Path,
    workspace: Path,
) -> tuple[list[dict[str, Any]], list[str]]:
    resolved: list[dict[str, Any]] = []
    unresolved: list[str] = []
    caption_overrides = slide.get("asset_captions")
    caption_mode = normalize_caption_mode(slide.get("asset_caption_mode"))

    for index, asset_id in enumerate(slide.get("asset_ids", [])):
        asset = assets_by_id.get(asset_id)
        if not asset:
            unresolved.append(asset_id)
            continue
        caption_override_present, caption_override = lookup_caption_override(caption_overrides, asset_id, index)

        expr = asset_image_expr(asset, deck_path, workspace)
        if expr is None:
            unresolved.append(asset_id)
        resolved.append(
            {
                "asset_id": asset_id,
                "expr": expr,
                "label": plain_text(asset.get("label") or asset_id),
                "caption": resolve_asset_caption(
                    asset,
                    asset_id,
                    caption_override_present=caption_override_present,
                    caption_override=caption_override,
                    caption_mode=caption_mode,
                ),
                "aspect_ratio": (asset.get("dimensions") or {}).get("aspect_ratio"),
                "notes": plain_text(asset.get("notes")),
            }
        )
    return resolved, unresolved


STYLE_TO_MACRO = {
    "takeaway": "ibox",
    "info": "ibox",
    "claim": "ibox",
    "highlight": "hbox",
    "emphasis": "hbox",
    "neutral": "nbox",
    "note": "nbox",
    "success": "sbox",
    "result": "sbox",
    "error": "ebox",
    "warning": "ebox",
    "purple": "pbox",
}


def normalize_box(raw: Any, index: int) -> dict[str, Any]:
    style_cycle = ["highlight", "neutral", "success", "purple"]
    if isinstance(raw, dict):
        body = raw.get("body")
        if body is None and raw.get("content") is not None:
            body = raw.get("content")
        if body is None and raw.get("text") is not None:
            body = raw.get("text")
        return {
            "style": raw.get("style") or raw.get("kind") or style_cycle[index % len(style_cycle)],
            "label": plain_text(raw.get("label") or raw.get("title")),
            "body": body if body is not None else "",
        }
    return {
        "style": style_cycle[index % len(style_cycle)],
        "label": "",
        "body": raw,
    }


def normalize_takeaway_mode(value: Any) -> str:
    mode = str(value or "auto").strip().lower()
    aliases = {
        "auto": "auto",
        "box": "box",
        "show": "box",
        "none": "none",
        "hide": "none",
        "hidden": "none",
        "omit": "none",
    }
    return aliases.get(mode, "auto")


def should_render_takeaway_box(slide: dict[str, Any]) -> bool:
    takeaway_mode = normalize_takeaway_mode(slide.get("takeaway_mode"))
    if takeaway_mode == "box":
        return True
    if takeaway_mode == "none":
        return False
    if slide.get("boxes"):
        return False
    return str(slide.get("archetype") or "") in FIGURE_FORWARD_ARCHETYPES


def resolve_slide_boxes(slide: dict[str, Any]) -> list[dict[str, Any]]:
    boxes: list[dict[str, Any]] = []
    takeaway = slide.get("takeaway")
    if takeaway and should_render_takeaway_box(slide):
        boxes.append(
            {
                "style": slide.get("takeaway_style", "info"),
                "label": slide.get("takeaway_label", "Takeaway"),
                "body": takeaway,
            }
        )
    for index, raw in enumerate(slide.get("boxes", []), start=len(boxes)):
        boxes.append(normalize_box(raw, index))
    return boxes


def render_box_body_lines(label: str, body: Any) -> list[str]:
    if isinstance(body, list):
        lines = []
        if label:
            lines.append(f"*{typst_escape(label)}:*")
        for item in body:
            lines.append(f"- {typst_escape(plain_text(item))}")
        return lines or [""]

    text = typst_escape(plain_text(body))
    if label and text:
        return [f"*{typst_escape(label)}:* {text}"]
    if label:
        return [f"*{typst_escape(label)}:*"]
    return [text]


def render_box_block(box: dict[str, Any]) -> list[str]:
    macro = STYLE_TO_MACRO.get(str(box.get("style", "neutral")).lower(), "nbox")
    compact = bool(box.get("compact"))
    lines = [f"#{macro}(compact: true)["] if compact else [f"#{macro}["]
    lines.extend(f"  {line}" if line else "  " for line in render_box_body_lines(plain_text(box.get("label")), box.get("body")))
    lines.append("]")
    lines.append("")
    return lines


def render_box_stack(boxes: list[dict[str, Any]], *, limit: int | None = None) -> list[str]:
    if limit is not None:
        boxes = boxes[:limit]
    lines: list[str] = []
    for box in boxes:
        lines.extend(render_box_block(box))
    return lines


def render_bullet_list(items: list[Any]) -> list[str]:
    if not items:
        return []
    lines = [f"- {typst_escape(plain_text(item))}" for item in items]
    lines.append("")
    return lines


def render_text_box(style: str, label: str, body: Any) -> list[str]:
    return render_box_block({"style": style, "label": label, "body": body})


def contains_cjk(text: str) -> bool:
    return bool(re.search(r"[\u3400-\u9fff]", text))


def merge_box_body(existing: Any, additions: list[Any]) -> Any:
    addition_texts = [plain_text(item).strip() for item in additions if plain_text(item).strip()]
    if not addition_texts:
        return existing
    if isinstance(existing, list):
        return [*existing, *addition_texts]

    base_text = plain_text(existing).strip()
    if not base_text:
        merged = addition_texts[0]
        for addition in addition_texts[1:]:
            if merged.endswith(("。", "！", "？", ".", "!", "?", "；", ";", "：", ":")):
                merged = f"{merged} {addition}"
            else:
                separator = "；" if contains_cjk(f"{merged}{addition}") else ";"
                merged = f"{merged}{separator} {addition}"
        return merged

    merged = base_text
    for addition in addition_texts:
        if not addition:
            continue
        if merged.endswith(("。", "！", "？", ".", "!", "?", "；", ";", "：", ":")):
            merged = f"{merged} {addition}"
        else:
            separator = "；" if contains_cjk(f"{merged}{addition}") else ";"
            merged = f"{merged}{separator} {addition}"
    return merged


def fold_support_points_into_boxes(
    boxes: list[dict[str, Any]],
    bullets: list[Any],
    *,
    box_limit: int | None,
    support_style: str = "neutral",
) -> list[dict[str, Any]]:
    support_items = [plain_text(item).strip() for item in bullets if plain_text(item).strip()]
    if not support_items:
        return list(boxes)

    visible_boxes = list(boxes[:box_limit] if box_limit is not None else boxes)
    support_body: Any = merge_box_body("", support_items)

    if box_limit is None or len(visible_boxes) < box_limit:
        visible_boxes.append(
            {
                "style": support_style,
                "label": "",
                "body": support_body,
                "compact": True,
            }
        )
        return visible_boxes

    if visible_boxes:
        merged_box = dict(visible_boxes[-1])
        merged_box["body"] = merge_box_body(merged_box.get("body"), support_items)
        visible_boxes[-1] = merged_box
        return visible_boxes

    return [
        {
            "style": support_style,
            "label": "",
            "body": support_body,
            "compact": True,
        }
    ]


def render_imgs_block(
    asset_entries: list[dict[str, Any]],
    *,
    width: str = "100%",
    widths: list[Any] | None = None,
    gap: str = "0.8em",
) -> list[str]:
    visible = [entry for entry in asset_entries if entry.get("expr")]
    if not visible:
        return []
    lines = ["#imgs("]
    for entry in visible:
        caption = typst_escape(entry.get("caption") or "")
        if caption:
            lines.append(f"  ({entry['expr']}, [{caption}]),")
        else:
            lines.append(f"  {entry['expr']},")
    lines.append(f"  width: {width},")
    if len(visible) > 1:
        lines.append(f"  gap: {gap},")
    if widths and len(visible) > 1:
        lines.append(f"  widths: ({typst_tuple(widths, default_unit='fr')}),")
    lines.append(")")
    lines.append("")
    return lines


def render_stacked_images(asset_entries: list[dict[str, Any]]) -> list[str]:
    visible = [entry for entry in asset_entries if entry.get("expr")]
    lines: list[str] = []
    for index, entry in enumerate(visible):
        lines.extend(render_imgs_block([entry], width="100%"))
        if index < len(visible) - 1:
            lines.append("#v(0.6em)")
            lines.append("")
    return lines


def render_grid(columns: list[Any], panels: list[list[str]], gutter: str = "0.8em") -> list[str]:
    lines = [
        "#grid(",
        f"  columns: ({typst_tuple(columns, default_unit='fr')}),",
        f"  gutter: {gutter},",
    ]
    for panel in panels:
        lines.append("  [")
        lines.extend(indent_lines(panel))
        lines.append("  ],")
    lines.append(")")
    lines.append("")
    return lines


def render_table_block(table: dict[str, Any] | None) -> list[str]:
    if not isinstance(table, dict):
        return []
    headers = table.get("headers") or []
    rows = table.get("rows") or []
    if not headers or not rows:
        return []
    width_count = max(len(headers), max((len(row) for row in rows), default=0))
    columns = table.get("widths") or table.get("columns") or [1] * width_count
    align = table.get("align") or ["left"] * width_count
    lines = [
        "#table(",
        f"  columns: ({typst_tuple(columns, default_unit='fr')}),",
        "  inset: 8pt,",
        f"  align: ({typst_tuple(align)}),",
    ]
    for header in headers:
        lines.append(f"  [*{typst_escape(plain_text(header))}*],")
    for row in rows:
        for cell in row:
            lines.append(f"  [{typst_escape(plain_text(cell))}],")
    lines.append(")")
    lines.append("")
    return lines


def resolve_cards(slide: dict[str, Any], asset_entries: list[dict[str, Any]]) -> list[dict[str, Any]]:
    cards = slide.get("cards")
    if isinstance(cards, list) and cards:
        asset_map = {entry["asset_id"]: entry for entry in asset_entries}
        resolved = []
        for index, raw in enumerate(cards):
            card = raw if isinstance(raw, dict) else {"body": raw}
            asset_id = card.get("asset_id")
            resolved.append(
                {
                    "title": plain_text(card.get("title") or card.get("label") or f"Card {index + 1}"),
                    "body": card.get("body") or card.get("points") or card.get("text") or "",
                    "asset": asset_map.get(asset_id) if asset_id else None,
                }
            )
        return resolved
    if 2 <= len(asset_entries) <= 3:
        return [
            {
                "title": entry.get("label") or entry["asset_id"],
                "body": entry.get("caption") or "",
                "asset": entry,
            }
            for entry in asset_entries[:3]
        ]
    return []


def render_card_body(card: dict[str, Any]) -> list[str]:
    lines: list[str] = []
    body = card.get("body")
    if isinstance(body, list):
        for item in body:
            lines.append(f"- {typst_escape(plain_text(item))}")
    elif plain_text(body):
        lines.append(typst_escape(plain_text(body)))
    asset = card.get("asset")
    if asset and asset.get("expr"):
        if lines:
            lines.append("#v(0.5em)")
        card_asset = dict(asset)
        card_asset["caption"] = ""
        lines.extend(render_imgs_block([card_asset], width="100%"))
    return lines or ["- Add card content."]


def render_cards_grid(cards: list[dict[str, Any]]) -> list[str]:
    if not cards:
        return []
    panels: list[list[str]] = []
    for card in cards:
        panel = [f"#mbox(title: [{typst_escape(card.get('title') or 'Card')}], body-size: 18pt)["]
        panel.extend(f"  {line}" if line else "  " for line in render_card_body(card))
        panel.append("]")
        panels.append(panel)
    return render_grid([1] * len(cards), panels)


def resolve_equations(slide: dict[str, Any], assets_by_id: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    equations: list[dict[str, Any]] = []
    local_equation = slide.get("equation")
    if isinstance(local_equation, dict):
        equations.append(local_equation)
    elif local_equation:
        equations.append({"text": local_equation})

    for equation_id in slide.get("equation_ids", []):
        asset = assets_by_id.get(equation_id)
        if not asset:
            continue
        equation = asset.get("equation") or {}
        equations.append(
            {
                "title": asset.get("label") or equation_id,
                "text": equation.get("text") or "",
                "context": equation.get("context") or "",
                "notation_hints": equation.get("notation_hints") or [],
            }
        )
    return equations


def render_equation_block(equation: dict[str, Any]) -> list[str]:
    lines: list[str] = []
    title = plain_text(equation.get("title"))
    math_expr = equation.get("typst")
    text = plain_text(equation.get("text"))
    if title:
        lines.extend(render_text_box("highlight", title, ""))
    if math_expr:
        lines.append(f"#align(center)[$ {math_expr} $]")
        lines.append("")
    elif text:
        lines.append("#cbox[")
        lines.append(f"  {typst_escape(text)}")
        lines.append("]")
        lines.append("")
    context = plain_text(equation.get("context"))
    if context:
        lines.extend(render_text_box("neutral", "Context", context))
    hints = equation.get("notation_hints") or []
    if hints:
        lines.extend(render_text_box("success", "Notation", hints))
    return lines


def render_support_metadata(
    slide: dict[str, Any],
    unresolved_assets: list[str],
    *,
    render_mode: str | None = None,
    escape_report: dict[str, Any] | None = None,
) -> list[str]:
    items = []
    if render_mode:
        items.append(f"Render mode: {render_mode}")
    if escape_report and escape_report.get("fallback_reason"):
        items.append(f"Escape fallback: {escape_report['fallback_reason']}")
    if slide.get("claim_ids"):
        items.append(f"Claim ids: {', '.join(slide.get('claim_ids', []))}")
    evidence = format_slide_evidence(slide)
    if evidence:
        items.append(f"Evidence: {evidence}")
    if slide.get("qa_expectations"):
        items.append(f"QA: {', '.join(str(item) for item in slide.get('qa_expectations', []))}")
    if unresolved_assets:
        items.append(f"Asset ids needing manual placement: {', '.join(unresolved_assets)}")
    if not items:
        return []
    return [f"// {item}" for item in items] + [""]


def render_generic_slide(
    slide: dict[str, Any],
    boxes: list[dict[str, Any]],
    asset_entries: list[dict[str, Any]],
    equations: list[dict[str, Any]],
) -> tuple[list[str], list[str]]:
    lines: list[str] = []
    warnings: list[str] = []
    body_boxes = fold_support_points_into_boxes(boxes, slide.get("bullets", []), box_limit=3)
    lines.extend(render_box_stack(body_boxes))
    table_lines = render_table_block(slide.get("table"))
    if slide.get("table") and not table_lines:
        warnings.append(f"slide {slide.get('slide_id') or slide.get('title')}: table data is incomplete")
    lines.extend(table_lines)
    if asset_entries:
        lines.extend(render_imgs_block(asset_entries[:2], width="94%"))
    if equations:
        lines.extend(render_equation_block(equations[0]))
    if not lines:
        warnings.append(f"slide {slide.get('slide_id') or slide.get('title')}: no renderable content")
    return lines, warnings


def limit_from_spec(spec: dict[str, Any] | None, key: str, default: int | None) -> int | None:
    if spec is None:
        return default
    limits = spec.get("limits") or {}
    value = limits.get(key)
    return int(value) if isinstance(value, int) else default


def render_title_slide_body(
    slide: dict[str, Any],
    spec: dict[str, Any] | None,
    asset_entries: list[dict[str, Any]],
    boxes: list[dict[str, Any]],
    bullets: list[Any],
    equations: list[dict[str, Any]],
) -> tuple[list[str], list[str]]:
    return [], []


def render_figure_led_vertical_body(
    slide: dict[str, Any],
    spec: dict[str, Any] | None,
    asset_entries: list[dict[str, Any]],
    boxes: list[dict[str, Any]],
    bullets: list[Any],
    equations: list[dict[str, Any]],
    *,
    width: str,
) -> tuple[list[str], list[str]]:
    warnings: list[str] = []
    if not asset_entries:
        warnings.append(
            f"slide {slide.get('slide_id') or slide.get('title')}: {slide.get('archetype')} selected without assets"
        )
    lines: list[str] = []
    box_limit = limit_from_spec(spec, "boxes_max", 2)
    bullet_limit = limit_from_spec(spec, "bullets_max", 3)
    bullet_items = bullets[:bullet_limit] if bullet_limit is not None else bullets
    # Figure-led pages in Lemonade look best when every supporting point stays inside
    # the box system. When the text budget is already full, merge the extra sentence
    # into the last visible box instead of leaving a free bullet above the figure.
    lines.extend(render_box_stack(fold_support_points_into_boxes(boxes, bullet_items, box_limit=box_limit)))
    lines.extend(render_imgs_block(asset_entries[:2], width=width))
    return lines, warnings


def render_method_side_by_side_body(
    slide: dict[str, Any],
    spec: dict[str, Any] | None,
    asset_entries: list[dict[str, Any]],
    boxes: list[dict[str, Any]],
    bullets: list[Any],
    equations: list[dict[str, Any]],
) -> tuple[list[str], list[str]]:
    warnings: list[str] = []
    if not asset_entries:
        warnings.append(
            f"slide {slide.get('slide_id') or slide.get('title')}: Method Overview Side-by-Side selected without assets"
        )
    box_limit = limit_from_spec(spec, "boxes_max", 3)
    if box_limit is not None and len(boxes) > box_limit:
        warnings.append(
            f"slide {slide.get('slide_id') or slide.get('title')}: truncated side-by-side method boxes to {box_limit} to avoid overflow"
        )
    first_ratio = None
    for entry in asset_entries:
        if entry.get("aspect_ratio") is not None:
            first_ratio = float(entry["aspect_ratio"])
            break
    columns = [0.82, 1.18] if first_ratio and first_ratio < 1.0 else [0.92, 1.08]
    bullet_limit = limit_from_spec(spec, "bullets_max", 2)
    bullet_items = bullets[:bullet_limit] if bullet_limit is not None else bullets
    left_panel = render_box_stack(fold_support_points_into_boxes(boxes, bullet_items, box_limit=box_limit))
    right_panel = render_imgs_block(asset_entries[:1], width="100%") or render_text_box(
        "neutral",
        "Missing evidence",
        "Add one overview asset or choose another archetype.",
    )
    return render_grid(columns, [left_panel, right_panel]), warnings


def render_method_stacked_evidence_body(
    slide: dict[str, Any],
    spec: dict[str, Any] | None,
    asset_entries: list[dict[str, Any]],
    boxes: list[dict[str, Any]],
    bullets: list[Any],
    equations: list[dict[str, Any]],
) -> tuple[list[str], list[str]]:
    warnings: list[str] = []
    if len(asset_entries) < 2:
        warnings.append(
            f"slide {slide.get('slide_id') or slide.get('title')}: stacked-evidence archetype works best with 2 assets"
        )
    box_limit = limit_from_spec(spec, "boxes_max", 3)
    if box_limit is not None and len(boxes) > box_limit:
        warnings.append(
            f"slide {slide.get('slide_id') or slide.get('title')}: truncated stacked-evidence method boxes to {box_limit} to avoid overflow"
        )
    bullet_limit = limit_from_spec(spec, "bullets_max", 2)
    bullet_items = bullets[:bullet_limit] if bullet_limit is not None else bullets
    left_panel = render_box_stack(fold_support_points_into_boxes(boxes, bullet_items, box_limit=box_limit))
    right_panel = render_stacked_images(asset_entries[:2]) or render_text_box(
        "neutral",
        "Missing evidence",
        "Add two related assets or use a different method archetype.",
    )
    return render_grid([1, 1], [left_panel, right_panel]), warnings


def render_method_cards_body(
    slide: dict[str, Any],
    spec: dict[str, Any] | None,
    asset_entries: list[dict[str, Any]],
    boxes: list[dict[str, Any]],
    bullets: list[Any],
    equations: list[dict[str, Any]],
) -> tuple[list[str], list[str]]:
    warnings: list[str] = []
    cards = resolve_cards(slide, asset_entries)
    allowed_counts = ((spec or {}).get("limits") or {}).get("cards_allowed") or [2, 3]
    if len(cards) not in allowed_counts:
        warnings.append(
            f"slide {slide.get('slide_id') or slide.get('title')}: Method Cards archetype expects {allowed_counts}"
        )
    lines: list[str] = []
    lines.extend(render_box_stack(boxes, limit=limit_from_spec(spec, "boxes_max", 1)))
    lines.extend(
        render_cards_grid(cards[:3])
        or render_text_box(
            "neutral",
            "Cards missing",
            "Provide `cards` entries or 2-3 asset-backed cards.",
        )
    )
    return lines, warnings


def render_comparison_body(
    slide: dict[str, Any],
    spec: dict[str, Any] | None,
    asset_entries: list[dict[str, Any]],
    boxes: list[dict[str, Any]],
    bullets: list[Any],
    equations: list[dict[str, Any]],
) -> tuple[list[str], list[str]]:
    warnings: list[str] = []
    if len(asset_entries) < 2 and not slide.get("table"):
        warnings.append(
            f"slide {slide.get('slide_id') or slide.get('title')}: comparison archetype usually needs 2 assets or a comparison table"
        )
    lines: list[str] = []
    box_limit = limit_from_spec(spec, "boxes_max", 2)
    bullet_limit = limit_from_spec(spec, "bullets_max", 2)
    bullet_items = bullets[:bullet_limit] if bullet_limit is not None else bullets
    lines.extend(render_box_stack(fold_support_points_into_boxes(boxes, bullet_items, box_limit=box_limit)))
    if len(asset_entries) >= 2:
        lines.extend(render_imgs_block(asset_entries[:2], width="100%"))
    elif slide.get("table"):
        lines.extend(render_table_block(slide.get("table")))
    elif asset_entries:
        lines.extend(render_imgs_block(asset_entries[:1], width="92%"))
    return lines, warnings


def render_table_structured_body(
    slide: dict[str, Any],
    spec: dict[str, Any] | None,
    asset_entries: list[dict[str, Any]],
    boxes: list[dict[str, Any]],
    bullets: list[Any],
    equations: list[dict[str, Any]],
) -> tuple[list[str], list[str]]:
    warnings: list[str] = []
    table_lines = render_table_block(slide.get("table"))
    lines: list[str] = []
    box_limit = limit_from_spec(spec, "boxes_max", 3)
    if boxes:
        first_box = boxes[:1]
        rest_boxes = boxes[1:] if box_limit is None else boxes[1:box_limit]
        lines.extend(render_box_stack(first_box))
        lines.extend(render_box_stack(rest_boxes))
    if not table_lines:
        warnings.append(
            f"slide {slide.get('slide_id') or slide.get('title')}: {slide.get('archetype')} selected without complete table data"
        )
        lines.extend(render_text_box("neutral", "Missing table", "Provide `table.headers` and `table.rows`."))
    else:
        lines.extend(table_lines)
    return lines, warnings


def render_equation_led_body(
    slide: dict[str, Any],
    spec: dict[str, Any] | None,
    asset_entries: list[dict[str, Any]],
    boxes: list[dict[str, Any]],
    bullets: list[Any],
    equations: list[dict[str, Any]],
) -> tuple[list[str], list[str]]:
    warnings: list[str] = []
    if not equations:
        warnings.append(
            f"slide {slide.get('slide_id') or slide.get('title')}: equation archetype selected without equation data"
        )
    left_panel = render_equation_block(equations[0]) if equations else render_text_box(
        "neutral",
        "Missing equation",
        "Provide `equation` or `equation_ids` for this archetype.",
    )
    box_limit = limit_from_spec(spec, "boxes_max", 3)
    bullet_limit = limit_from_spec(spec, "bullets_max", 3)
    bullet_items = bullets[:bullet_limit] if bullet_limit is not None else bullets
    right_panel = render_box_stack(fold_support_points_into_boxes(boxes, bullet_items, box_limit=box_limit))
    return render_grid([0.95, 1.05], [left_panel, right_panel]), warnings


def render_motivation_background_body(
    slide: dict[str, Any],
    spec: dict[str, Any] | None,
    asset_entries: list[dict[str, Any]],
    boxes: list[dict[str, Any]],
    bullets: list[Any],
    equations: list[dict[str, Any]],
) -> tuple[list[str], list[str]]:
    lines: list[str] = []
    box_limit = limit_from_spec(spec, "boxes_max", 3)
    bullet_limit = limit_from_spec(spec, "bullets_max", 4)
    bullet_items = bullets[:bullet_limit] if bullet_limit is not None else bullets
    table_lines = render_table_block(slide.get("table"))
    if table_lines:
        left_panel = render_box_stack(fold_support_points_into_boxes(boxes, bullet_items, box_limit=box_limit))
        lines.extend(render_grid([0.95, 1.05], [left_panel, table_lines]))
    elif asset_entries:
        left_panel = render_box_stack(fold_support_points_into_boxes(boxes, bullet_items, box_limit=box_limit))
        right_panel = render_imgs_block(asset_entries[:1], width="100%")
        lines.extend(render_grid([0.95, 1.05], [left_panel, right_panel]))
    else:
        if boxes:
            lines.extend(render_box_stack(fold_support_points_into_boxes(boxes, bullet_items, box_limit=box_limit)))
        else:
            lines.extend(render_bullet_list(bullet_items))
    return lines, []


def render_conclusion_takeaways_body(
    slide: dict[str, Any],
    spec: dict[str, Any] | None,
    asset_entries: list[dict[str, Any]],
    boxes: list[dict[str, Any]],
    bullets: list[Any],
    equations: list[dict[str, Any]],
) -> tuple[list[str], list[str]]:
    lines: list[str] = []
    box_limit = limit_from_spec(spec, "boxes_max", 4)
    bullet_limit = limit_from_spec(spec, "bullets_max", 4)
    bullet_items = bullets[:bullet_limit] if bullet_limit is not None else bullets
    if boxes:
        lines.extend(render_box_stack(fold_support_points_into_boxes(boxes, bullet_items, box_limit=box_limit)))
    else:
        lines.extend(render_bullet_list(bullet_items))
    if asset_entries:
        lines.extend(render_imgs_block(asset_entries[:1], width="88%"))
    return lines, []


def render_outline_roadmap_body(
    slide: dict[str, Any],
    spec: dict[str, Any] | None,
    asset_entries: list[dict[str, Any]],
    boxes: list[dict[str, Any]],
    bullets: list[Any],
    equations: list[dict[str, Any]],
    deck_sections: list[str],
) -> tuple[list[str], list[str]]:
    warnings: list[str] = []
    roadmap = slide.get("roadmap") or bullets or deck_sections
    lines: list[str] = []
    lines.extend(render_box_stack(boxes, limit=limit_from_spec(spec, "boxes_max", 1)))
    if roadmap:
        lines.extend(render_text_box("neutral", slide.get("roadmap_label", "Roadmap"), [plain_text(item) for item in roadmap]))
    else:
        warnings.append(f"slide {slide.get('slide_id') or slide.get('title')}: roadmap slide has no roadmap items")
    return lines, warnings


RENDERER_HANDLERS: dict[str, Callable[..., tuple[list[str], list[str]]]] = {
    "title_slide": render_title_slide_body,
    "outline_roadmap": render_outline_roadmap_body,
    "motivation_background": render_motivation_background_body,
    "figure_led_vertical": lambda slide, spec, asset_entries, boxes, bullets, equations, deck_sections=None: render_figure_led_vertical_body(
        slide,
        spec,
        asset_entries,
        boxes,
        bullets,
        equations,
        width="94%",
    ),
    "wide_evidence": lambda slide, spec, asset_entries, boxes, bullets, equations, deck_sections=None: render_figure_led_vertical_body(
        slide,
        spec,
        asset_entries,
        boxes,
        bullets,
        equations,
        width="98%",
    ),
    "method_side_by_side": render_method_side_by_side_body,
    "method_stacked_evidence": render_method_stacked_evidence_body,
    "method_cards": render_method_cards_body,
    "comparison": render_comparison_body,
    "table_structured": render_table_structured_body,
    "equation_led": render_equation_led_body,
    "conclusion_takeaways": render_conclusion_takeaways_body,
}


def render_slide_typst(
    slide: dict[str, Any],
    assets_by_id: dict[str, dict[str, Any]],
    deck_path: Path,
    workspace: Path,
    deck_sections: list[str],
    *,
    disable_escape: bool = False,
) -> tuple[list[str], list[str], dict[str, Any]]:
    title = typst_escape(slide.get("title", "Untitled Slide"))
    archetype = str(slide.get("archetype", "") or "")
    spec = get_archetype_spec(archetype)
    asset_entries, unresolved_assets = resolve_slide_assets(slide, assets_by_id, deck_path, workspace)
    boxes = resolve_slide_boxes(slide)
    equations = resolve_equations(slide, assets_by_id)
    bullets = slide.get("bullets") or []
    warnings: list[str] = []
    slide_id = slide.get("slide_id") or slide.get("title") or "slide"
    escape_report = maybe_render_escape_body(
        slide,
        spec,
        asset_entries,
        boxes,
        bullets,
        equations,
        deck_sections,
        workspace,
        disable_escape=disable_escape,
    )

    body_lines: list[str] = []
    if escape_report["used"]:
        fragment_path = Path(str(escape_report["fragment_path"]))
        body_lines.extend(
            [
                f"// WARNING: escape-hatch triggered for slide {slide_id}",
                f"// Escape fragment: {rel_or_abs(fragment_path)}",
                f"// Escape hint: {plain_text(slide.get('escape_hint')).strip()}",
                "",
            ]
        )
        body_lines.extend(escape_report["body_lines"])
        if body_lines and body_lines[-1] != "":
            body_lines.append("")
        warnings.extend(escape_report["warnings"])
    else:
        if escape_report["warnings"]:
            warnings.extend(escape_report["warnings"])
        renderer_name = spec.get("renderer", "generic") if spec else "generic"
        handler = RENDERER_HANDLERS.get(renderer_name)
        if handler is None:
            generic_lines, generic_warnings = render_generic_slide(slide, boxes, asset_entries, equations)
            body_lines.extend(generic_lines)
            warnings.extend(generic_warnings)
        elif renderer_name == "outline_roadmap":
            rendered_lines, rendered_warnings = handler(slide, spec, asset_entries, boxes, bullets, equations, deck_sections)
            body_lines.extend(rendered_lines)
            warnings.extend(rendered_warnings)
        else:
            rendered_lines, rendered_warnings = handler(slide, spec, asset_entries, boxes, bullets, equations)
            body_lines.extend(rendered_lines)
            warnings.extend(rendered_warnings)

    lines = [f"== {title}", ""]
    lines.extend(body_lines)
    lines.extend(
        render_support_metadata(
            slide,
            unresolved_assets,
            render_mode=normalize_render_mode(slide.get("render_mode")),
            escape_report=escape_report,
        )
    )
    return lines, warnings, escape_report


def cmd_emit_deck(args: argparse.Namespace) -> None:
    workspace = Path(args.workspace).expanduser().resolve()
    paths = notes_paths(workspace)
    if not paths["slides_json"].exists():
        raise SystemExit("slides.json does not exist; run init-workspace first")

    slides_doc = load_json(paths["slides_json"])
    brief_doc = load_json(paths["brief_json"]) if paths["brief_json"].exists() else {}
    assets_doc = load_json(paths["assets_json"]) if paths["assets_json"].exists() else {}
    deck = slides_doc.get("deck", {})
    paper = brief_doc.get("paper", {})

    default_out = workspace / f"{workspace.name}.typ"
    deck_path = Path(args.out).expanduser().resolve() if args.out else default_out
    if not deck_path.is_absolute():
        deck_path = (Path.cwd() / deck_path).resolve()

    assets_by_id = {
        asset.get("asset_id"): asset
        for asset in assets_doc.get("assets", [])
        if isinstance(asset, dict) and asset.get("asset_id")
    }

    title = typst_escape(deck.get("title") or paper.get("title") or workspace.name)
    authors = typst_escape(", ".join(paper.get("authors", [])))
    venue = typst_escape(paper.get("venue") or deck.get("scenario") or "")
    institution = typst_escape(paper.get("institution") or "")
    short_title = typst_escape(deck.get("short_title") or paper.get("short_title") or title)
    date = typst_escape(paper.get("date") or deck.get("date") or "")
    lang = "zh" if str(deck.get("language", "")).lower().startswith("zh") else "en"

    lines = [
        '#import "/lemonade.typ": *',
        "",
        f'#set text(lang: "{lang}")',
        "",
        "#show: lemonade-theme.with(",
        '  aspect-ratio: "16-9",',
        '  title-align: "left",',
        "  box-compact: true,",
        '  footer: "bar",',
        "  config-info(",
        f"    title: [{title}],",
        f"    venue: [{venue}],",
        f"    author: [{authors}],",
        f"    institution: [{institution}],",
        f"    short-title: [{short_title}],",
        f"    date: [{date}],",
        "  ),",
        ")",
        "",
        "#title-slide()",
        "",
    ]

    slides = slides_doc.get("slides", [])
    escape_candidates = [
        slide.get("slide_id") or f"slide-{index:02d}"
        for index, slide in enumerate(slides, start=1)
        if isinstance(slide, dict) and normalize_render_mode(slide.get("render_mode")) == "escape"
    ]
    if args.disable_escape and escape_candidates:
        lines.extend(
            [
                f"// WARNING: escape render mode disabled for this emission ({', '.join(escape_candidates)})",
                "",
            ]
        )
    deck_sections: list[str] = []
    for slide in slides:
        if not isinstance(slide, dict):
            continue
        section = plain_text(slide.get("section"))
        if section and section not in deck_sections:
            deck_sections.append(section)

    warnings: list[str] = []
    escape_fragments: list[str] = []
    escape_fallback_slides: list[str] = []
    current_section = None
    for index, slide in enumerate(slides, start=1):
        if not isinstance(slide, dict):
            continue
        archetype = str(slide.get("archetype", ""))
        if index == 1 and archetype == "Title slide":
            continue
        section = slide.get("section")
        if section and section != current_section:
            lines.append(f"= {typst_escape(section)}")
            lines.append("")
            current_section = section
        slide_lines, slide_warnings, escape_report = render_slide_typst(
            slide,
            assets_by_id,
            deck_path,
            workspace,
            deck_sections,
            disable_escape=args.disable_escape,
        )
        lines.extend(slide_lines)
        warnings.extend(slide_warnings)
        if escape_report.get("used") and escape_report.get("fragment_path"):
            escape_fragments.append(str(escape_report["fragment_path"]))
        if normalize_render_mode(slide.get("render_mode")) == "escape" and escape_report.get("fallback_reason"):
            escape_fallback_slides.append(slide.get("slide_id") or f"slide-{index:02d}")

    write_text(deck_path, "\n".join(lines).rstrip() + "\n")
    print(
        json.dumps(
            {
                "deck_typ": str(deck_path),
                "slide_count": len(slides),
                "disable_escape": args.disable_escape,
                "escape_candidates": escape_candidates,
                "escape_fragments": escape_fragments,
                "escape_fallback_slides": escape_fallback_slides,
                "warnings": warnings,
            },
            indent=2,
        )
    )


def cmd_init_workspace(args: argparse.Namespace) -> None:
    pdf_path = Path(args.pdf).expanduser().resolve()
    if not pdf_path.exists():
        raise SystemExit(f"pdf not found: {pdf_path}")
    workspace = Path(args.workspace).expanduser().resolve() if args.workspace else Path("out") / default_workspace_name(pdf_path)
    if not workspace.is_absolute():
        workspace = (Path.cwd() / workspace).resolve()
    title = args.title or pdf_path.stem
    paths = ensure_json_skeletons(workspace, pdf_path, title, args.scenario, args.language, force=args.force)
    cmd_render_notes(argparse.Namespace(workspace=str(workspace)))
    print(
        json.dumps(
            {
                "workspace": str(workspace),
                "notes_dir": str(paths["notes_dir"]),
                "assets_json": str(paths["assets_json"]),
                "brief_json": str(paths["brief_json"]),
                "slides_json": str(paths["slides_json"]),
                "review_json": str(paths["review_json"]),
            },
            indent=2,
        )
    )


def cmd_extract_source(args: argparse.Namespace) -> None:
    workspace = Path(args.workspace).expanduser().resolve()
    pdf_path = Path(args.pdf).expanduser().resolve()
    if not pdf_path.exists():
        raise SystemExit(f"pdf not found: {pdf_path}")
    ensure_json_skeletons(workspace, pdf_path, pdf_path.stem, "paper-reading", "en")
    paths = notes_paths(workspace)
    extractor = extract_source_with_pdftotext(pdf_path, paths["source_txt"])
    if extractor is None:
        extractor = extract_source_with_fitz(pdf_path, paths["source_txt"])

    assets_json = load_json(paths["assets_json"])
    assets_json["source_text"] = {
        "path": rel_or_abs(paths["source_txt"]),
        "extractor": extractor,
        "generated_at": iso_now(),
        "page_count": count_pdf_pages(pdf_path),
        "notes": assets_json.get("source_text", {}).get("notes", ""),
    }
    assets_json.setdefault("metadata", {})["updated_at"] = iso_now()
    assets_json.setdefault("extraction", {})["status"] = "source-extracted"
    save_json(paths["assets_json"], assets_json)
    print(json.dumps({"source_txt": str(paths["source_txt"]), "extractor": extractor}, indent=2))


def cmd_upsert_asset(args: argparse.Namespace) -> None:
    workspace = Path(args.workspace).expanduser().resolve()
    paths = notes_paths(workspace)
    if not paths["assets_json"].exists():
        raise SystemExit("assets.json does not exist; run init-workspace first")

    doc = load_json(paths["assets_json"])
    assets = doc.setdefault("assets", [])
    capture = {}
    if args.capture_json:
        capture = load_json(Path(args.capture_json).expanduser().resolve())

    source_file = args.source_file or capture.get("pdf") or doc.get("source_pdf")
    page = args.page if args.page is not None else capture.get("page")
    bbox = args.bbox or capture.get("bbox")
    capture_kind = args.capture_kind or infer_capture_kind(capture.get("selection_mode"))
    primary_output = args.primary_output or capture.get("primary_output")
    normalized_caption = args.normalized_caption or args.raw_caption or ""
    dimensions = load_dimensions(Path(primary_output).expanduser().resolve()) if primary_output else {
        "width": None,
        "height": None,
        "aspect_ratio": None,
    }

    entry = {
        "asset_id": args.asset_id,
        "asset_type": args.asset_type,
        "label": args.label or args.asset_id,
        "title": args.title or "",
        "source_file": source_file,
        "page": page,
        "bbox": bbox,
        "capture_kind": capture_kind,
        "primary_output": rel_or_abs(Path(primary_output).expanduser().resolve()) if primary_output else None,
        "normalized_caption": normalized_caption,
        "raw_caption": args.raw_caption or normalized_caption,
        "dimensions": dimensions,
        "source_section": args.source_section or "",
        "extraction_quality": args.quality,
        "candidate_roles": list(args.candidate_role or []),
        "notes": args.notes or "",
        "cleanup_needed": args.cleanup_needed,
        "capture_metadata": {
            "selection_mode": capture.get("selection_mode"),
            "selected_candidate": capture.get("selected_candidate"),
            "candidates": capture.get("candidates"),
        } if capture else {},
        "equation": {
            "text": args.equation_text or "",
            "context": args.equation_context or "",
            "notation_hints": list(args.notation_hint or []),
            "display_preferred": args.display_preferred,
        } if args.asset_type == "equation" else None,
    }

    replaced = False
    for index, asset in enumerate(assets):
        if asset.get("asset_id") == args.asset_id:
            assets[index] = entry
            replaced = True
            break
    if not replaced:
        assets.append(entry)

    doc.setdefault("metadata", {})["updated_at"] = iso_now()
    doc.setdefault("extraction", {})["status"] = "assets-registered"
    save_json(paths["assets_json"], doc)
    print(json.dumps({"updated": args.asset_id, "replaced": replaced}, indent=2))


def cmd_render_notes(args: argparse.Namespace) -> None:
    workspace = Path(args.workspace).expanduser().resolve()
    paths = notes_paths(workspace)
    rendered = {}
    if paths["assets_json"].exists():
        rendered["asset_manifest"] = str(paths["asset_manifest_md"])
        write_text(paths["asset_manifest_md"], render_asset_manifest_md(load_json(paths["assets_json"])))
    if paths["brief_json"].exists():
        rendered["brief"] = str(paths["brief_md"])
        write_text(paths["brief_md"], render_brief_md(load_json(paths["brief_json"])))
    if paths["slides_json"].exists():
        rendered["slide_map"] = str(paths["slide_map_md"])
        write_text(paths["slide_map_md"], render_slide_map_md(load_json(paths["slides_json"])))
    print(json.dumps(rendered, indent=2))


def cmd_render_archetypes_reference(args: argparse.Namespace) -> None:
    spec_doc = load_archetype_spec_doc()
    out_path = Path(args.out).expanduser().resolve() if args.out else REFERENCE_ARCHETYPES_PATH
    if not out_path.is_absolute():
        out_path = (Path.cwd() / out_path).resolve()
    write_text(out_path, render_archetypes_reference_md(spec_doc))
    print(json.dumps({"archetypes_md": str(out_path), "source_json": str(ARCHETYPE_SPECS_PATH)}, indent=2))


def cmd_collect_escape_context(args: argparse.Namespace) -> None:
    workspace = Path(args.workspace).expanduser().resolve()
    paths = notes_paths(workspace)
    if not paths["slides_json"].exists():
        raise SystemExit("slides.json does not exist; run init-workspace first")

    slides_doc = load_json(paths["slides_json"])
    assets_doc = load_json(paths["assets_json"]) if paths["assets_json"].exists() else {}
    assets_by_id = {
        asset.get("asset_id"): asset
        for asset in assets_doc.get("assets", [])
        if isinstance(asset, dict) and asset.get("asset_id")
    }
    deck_path = workspace / f"{workspace.name}.typ"
    deck_sections: list[str] = []
    for slide in slides_doc.get("slides", []):
        if not isinstance(slide, dict):
            continue
        section = plain_text(slide.get("section"))
        if section and section not in deck_sections:
            deck_sections.append(section)

    requested_ids = set(args.slide_id or [])
    contexts = []
    for index, slide in enumerate(slides_doc.get("slides", []), start=1):
        if not isinstance(slide, dict):
            continue
        slide_id = slide.get("slide_id") or f"slide-{index:02d}"
        if normalize_render_mode(slide.get("render_mode")) != "escape":
            continue
        if requested_ids and slide_id not in requested_ids:
            continue
        spec = get_archetype_spec(str(slide.get("archetype") or ""))
        asset_entries, unresolved_assets = resolve_slide_assets(slide, assets_by_id, deck_path, workspace)
        boxes = resolve_slide_boxes(slide)
        equations = resolve_equations(slide, assets_by_id)
        context = {
            "slide_id": slide_id,
            "fragment_path": str(escape_fragment_path(slide, workspace)),
            "config_issues": collect_escape_config_issues(slide, spec),
            "unresolved_assets": unresolved_assets,
            "payload": build_escape_fragment_payload(
                slide,
                spec,
                asset_entries,
                boxes,
                slide.get("bullets") or [],
                equations,
                deck_sections,
            ),
        }
        contexts.append(context)

    print(json.dumps({"workspace": str(workspace), "escape_slides": contexts}, indent=2, ensure_ascii=False))


def resolve_repo_relative(path_value: str, workspace: Path) -> Path:
    path = Path(path_value).expanduser()
    if path.is_absolute():
        return path
    cwd_candidate = (Path.cwd() / path).resolve()
    if cwd_candidate.exists():
        return cwd_candidate
    workspace_candidate = (workspace / path).resolve()
    if workspace_candidate.exists():
        return workspace_candidate
    return cwd_candidate


def validate_archetype_required_fields(
    slide_id: str,
    slide: dict[str, Any],
    spec: dict[str, Any] | None,
    warnings: list[str],
) -> None:
    if spec is None:
        return

    required_fields = spec.get("required_fields") or {}
    for field_name, field_spec in required_fields.items():
        if not isinstance(field_spec, dict):
            field_spec = {}
        if field_name == "asset_ids":
            asset_ids = slide.get("asset_ids", [])
            min_items = field_spec.get("min_items")
            max_items = field_spec.get("max_items")
            if min_items is not None and len(asset_ids) < min_items:
                warnings.append(f"slide {slide_id} uses {slide.get('archetype')} but needs at least {min_items} asset_ids")
            if max_items is not None and len(asset_ids) > max_items:
                warnings.append(f"slide {slide_id} uses {slide.get('archetype')} but should not exceed {max_items} asset_ids")
        elif field_name == "table":
            table = slide.get("table")
            headers = (table or {}).get("headers") if isinstance(table, dict) else []
            rows = (table or {}).get("rows") if isinstance(table, dict) else []
            if not headers or not rows:
                warnings.append(f"slide {slide_id} uses {slide.get('archetype')} but table.headers/table.rows are incomplete")
        elif field_name == "equation_or_equation_ids":
            if not (slide.get("equation") or slide.get("equation_ids")):
                warnings.append(f"slide {slide_id} uses {slide.get('archetype')} but needs `equation` or `equation_ids`")
        elif field_name == "roadmap_or_bullets":
            if not (slide.get("roadmap") or slide.get("bullets")):
                warnings.append(f"slide {slide_id} roadmap slide has no roadmap items or bullets")
        elif field_name == "cards_or_asset_ids":
            cards = slide.get("cards") if isinstance(slide.get("cards"), list) else []
            asset_ids = slide.get("asset_ids", [])
            allowed_card_counts = field_spec.get("allowed_card_counts") or [2, 3]
            asset_id_range = field_spec.get("asset_id_range") or [2, 3]
            if cards:
                if len(cards) not in allowed_card_counts:
                    warnings.append(f"slide {slide_id} Method Cards archetype expects {allowed_card_counts}; saw {len(cards)}")
            elif not (asset_id_range[0] <= len(asset_ids) <= asset_id_range[-1]):
                warnings.append(
                    f"slide {slide_id} Method Cards archetype needs `cards` or {asset_id_range[0]}-{asset_id_range[-1]} asset_ids"
                )
        elif field_name == "comparison_assets_or_table":
            asset_ids = slide.get("asset_ids", [])
            table = slide.get("table")
            min_items = field_spec.get("asset_id_min_items", 2)
            if len(asset_ids) < min_items and not table:
                warnings.append(
                    f"slide {slide_id} uses {slide.get('archetype')} but needs {min_items}+ asset_ids or a table"
                )


def validate_archetype_limits(
    slide_id: str,
    slide: dict[str, Any],
    spec: dict[str, Any] | None,
    warnings: list[str],
) -> None:
    if spec is None:
        return

    limits = spec.get("limits") or {}
    boxes_max = limits.get("boxes_max")
    bullets_max = limits.get("bullets_max")
    cards_allowed = limits.get("cards_allowed")

    if isinstance(boxes_max, int) and len(slide.get("boxes", [])) > boxes_max:
        warnings.append(f"slide {slide_id} uses {slide.get('archetype')} but defines {len(slide.get('boxes', []))} boxes (max {boxes_max})")
    if isinstance(bullets_max, int) and len(slide.get("bullets", []) if isinstance(slide.get("bullets"), list) else []) > bullets_max:
        warnings.append(
            f"slide {slide_id} uses {slide.get('archetype')} but defines {len(slide.get('bullets', []))} bullets (max {bullets_max})"
        )
    if cards_allowed and isinstance(slide.get("cards"), list) and len(slide.get("cards")) not in cards_allowed:
        warnings.append(f"slide {slide_id} uses {slide.get('archetype')} but cards count {len(slide.get('cards'))} is not in {cards_allowed}")


def cmd_validate_artifacts(args: argparse.Namespace) -> None:
    workspace = Path(args.workspace).expanduser().resolve()
    paths = notes_paths(workspace)
    errors: list[str] = []
    warnings: list[str] = []

    required = [paths["assets_json"], paths["brief_json"], paths["slides_json"], paths["review_json"]]
    for required_path in required:
        if not required_path.exists():
            errors.append(f"missing required artifact: {required_path}")
    if errors:
        print(json.dumps({"errors": errors, "warnings": warnings}, indent=2))
        raise SystemExit(1)

    assets_doc = load_json(paths["assets_json"])
    brief_doc = load_json(paths["brief_json"])
    slides_doc = load_json(paths["slides_json"])
    review_doc = load_json(paths["review_json"])

    source_path = (assets_doc.get("source_text") or {}).get("path")
    if source_path and not resolve_repo_relative(source_path, workspace).exists():
        warnings.append(f"source_text path does not exist: {source_path}")
    if not (assets_doc.get("source_text") or {}).get("generated_at"):
        warnings.append("source_text has not been generated yet")

    asset_ids: set[str] = set()
    equation_ids: set[str] = set()
    for asset in assets_doc.get("assets", []):
        asset_id = asset.get("asset_id")
        if not asset_id:
            errors.append("asset without asset_id")
            continue
        if asset_id in asset_ids:
            errors.append(f"duplicate asset_id: {asset_id}")
        asset_ids.add(asset_id)

        asset_type = asset.get("asset_type")
        if asset_type not in ALLOWED_ASSET_TYPES:
            errors.append(f"asset {asset_id} has unknown asset_type: {asset_type}")
        if asset_type in {"figure", "table"} and asset.get("primary_output"):
            asset_path = resolve_repo_relative(asset["primary_output"], workspace)
            if not asset_path.exists():
                warnings.append(f"asset {asset_id} primary_output does not exist: {asset['primary_output']}")
        if asset_type == "equation":
            equation_ids.add(asset_id)
            if not (asset.get("equation") or {}).get("text"):
                warnings.append(f"equation asset {asset_id} is missing equation.text")
        if asset_type in {"figure", "table"} and not asset.get("candidate_roles"):
            warnings.append(f"asset {asset_id} does not list candidate_roles")

    claim_ids: set[str] = set()
    for claim in brief_doc.get("claims", []):
        if not isinstance(claim, dict):
            warnings.append(f"claim should be an object, saw {type(claim).__name__}")
            continue
        claim_id = claim.get("claim_id")
        if not claim_id:
            warnings.append("claim without claim_id")
            continue
        if claim_id in claim_ids:
            errors.append(f"duplicate claim_id: {claim_id}")
        claim_ids.add(claim_id)

    for entry in brief_doc.get("evidence_map", []):
        if not isinstance(entry, dict):
            warnings.append(f"evidence_map entry should be an object, saw {type(entry).__name__}")
            continue
        claim_id = entry.get("claim_id")
        if claim_id and claim_id not in claim_ids:
            errors.append(f"evidence_map references missing claim_id: {claim_id}")
        for support in entry.get("support", []):
            if not isinstance(support, dict):
                continue
            kind = support.get("kind")
            ref = support.get("ref")
            if kind == "asset" and ref not in asset_ids:
                errors.append(f"evidence_map references missing asset: {ref}")
            if kind == "claim" and ref not in claim_ids:
                errors.append(f"evidence_map references missing claim: {ref}")

    slide_ids: set[str] = set()
    slides = slides_doc.get("slides", [])
    if not slides:
        warnings.append("slides.json does not contain any planned slides")
    for index, slide in enumerate(slides, start=1):
        if not isinstance(slide, dict):
            errors.append(f"slide entry {index} is not an object")
            continue
        slide_id = slide.get("slide_id") or f"slide-{index:02d}"
        if slide_id in slide_ids:
            errors.append(f"duplicate slide_id: {slide_id}")
        slide_ids.add(slide_id)

        archetype = slide.get("archetype")
        spec = get_archetype_spec(str(archetype)) if archetype else None
        if archetype and spec is None:
            warnings.append(f"slide {slide_id} uses unknown archetype: {archetype}")
        render_mode = normalize_render_mode(slide.get("render_mode"))
        if render_mode not in ALLOWED_RENDER_MODES:
            warnings.append(f"slide {slide_id} uses unknown render_mode: {render_mode}")
        elif spec and render_mode not in (spec.get("allowed_render_modes") or ["script"]):
            warnings.append(f"slide {slide_id} uses render_mode `{render_mode}` but {archetype} allows {spec.get('allowed_render_modes')}")
        for issue in collect_escape_config_issues(slide, spec):
            warnings.append(f"slide {slide_id} escape config: {issue}")
        if render_mode == "escape":
            fragment_path = escape_fragment_path(slide, workspace)
            fragment, _, fragment_issue = load_escape_fragment(slide, workspace)
            if fragment_issue:
                warnings.append(f"slide {slide_id} escape fragment issue: {fragment_issue} ({rel_or_abs(fragment_path)})")
            elif fragment is not None and not fragment.strip():
                warnings.append(f"slide {slide_id} escape fragment is empty after cleanup ({rel_or_abs(fragment_path)})")
        if not slide.get("title"):
            warnings.append(f"slide {slide_id} is missing title")
        if not slide.get("takeaway"):
            warnings.append(f"slide {slide_id} is missing takeaway")
        if not slide.get("rhetorical_role"):
            warnings.append(f"slide {slide_id} is missing rhetorical_role")
        claim_refs = slide.get("claim_ids", [])
        if len(claim_refs) != 1:
            warnings.append(f"slide {slide_id} should usually reference exactly one claim_id; saw {len(claim_refs)}")
        for claim_id in claim_refs:
            if claim_id not in claim_ids:
                errors.append(f"slide {slide_id} references missing claim_id: {claim_id}")
        for asset_id in slide.get("asset_ids", []):
            if asset_id not in asset_ids:
                errors.append(f"slide {slide_id} references missing asset_id: {asset_id}")
        for equation_id in slide.get("equation_ids", []):
            if equation_id not in equation_ids:
                errors.append(f"slide {slide_id} references missing equation_id: {equation_id}")
        density = slide.get("content_density")
        if density and density not in ALLOWED_DENSITY_TARGETS:
            warnings.append(f"slide {slide_id} uses unknown content_density: {density}")
        if not slide.get("qa_expectations"):
            warnings.append(f"slide {slide_id} is missing qa_expectations")
        table = slide.get("table")
        if table is not None:
            if not isinstance(table, dict):
                warnings.append(f"slide {slide_id} table should be an object")
            else:
                headers = table.get("headers") or []
                rows = table.get("rows") or []
                if headers and rows:
                    expected_width = len(headers)
                    for row_index, row in enumerate(rows, start=1):
                        if len(row) != expected_width:
                            warnings.append(
                                f"slide {slide_id} table row {row_index} has {len(row)} cells but headers has {expected_width}"
                            )
                elif archetype in {"Table-Led Structured Slide", "Progress or Status Matrix"}:
                    warnings.append(f"slide {slide_id} uses {archetype} but table.headers/table.rows are incomplete")
        cards = slide.get("cards")
        if cards is not None:
            if not isinstance(cards, list):
                warnings.append(f"slide {slide_id} cards should be a list")
        bullets = slide.get("bullets")
        if bullets is not None and not isinstance(bullets, list):
            warnings.append(f"slide {slide_id} bullets should be a list")
        validate_archetype_required_fields(slide_id, slide, spec, warnings)
        validate_archetype_limits(slide_id, slide, spec, warnings)
        for item in slide.get("evidence", []):
            if isinstance(item, dict) and item.get("kind") == "asset" and item.get("ref") not in asset_ids:
                errors.append(f"slide {slide_id} evidence references missing asset: {item.get('ref')}")
            if isinstance(item, dict) and item.get("kind") == "claim" and item.get("ref") not in claim_ids:
                errors.append(f"slide {slide_id} evidence references missing claim: {item.get('ref')}")
            if isinstance(item, dict) and item.get("kind") == "equation" and item.get("ref") not in equation_ids:
                errors.append(f"slide {slide_id} evidence references missing equation: {item.get('ref')}")

    review_status = (review_doc.get("summary") or {}).get("status")
    if review_status and review_status not in ALLOWED_REVIEW_STATUSES:
        warnings.append(f"review summary uses unknown status: {review_status}")
    for issue in review_doc.get("issues", []):
        if not isinstance(issue, dict):
            warnings.append(f"review issue should be an object, saw {type(issue).__name__}")
            continue
        for slide_id in issue.get("slide_ids", []):
            if slide_id not in slide_ids:
                warnings.append(f"review issue references unknown slide_id: {slide_id}")

    result = {
        "workspace": str(workspace),
        "slide_count": len(slides),
        "asset_count": len(assets_doc.get("assets", [])),
        "claim_count": len(brief_doc.get("claims", [])),
        "errors": errors,
        "warnings": warnings,
    }
    print(json.dumps(result, indent=2))
    if errors:
        raise SystemExit(1)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Manage JSON-first paper-to-slides artifacts and derived Markdown notes."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    init_parser = subparsers.add_parser(
        "init-workspace",
        help="Create the JSON-first artifact skeleton for one paper workspace",
    )
    init_parser.add_argument("pdf")
    init_parser.add_argument("--workspace")
    init_parser.add_argument("--title")
    init_parser.add_argument("--scenario", default="paper-reading")
    init_parser.add_argument("--language", default="en")
    init_parser.add_argument("--force", action="store_true")
    init_parser.set_defaults(func=cmd_init_workspace)

    source_parser = subparsers.add_parser(
        "extract-source",
        help="Extract reproducible source text into notes/source.txt",
    )
    source_parser.add_argument("pdf")
    source_parser.add_argument("--workspace", required=True)
    source_parser.set_defaults(func=cmd_extract_source)

    asset_parser = subparsers.add_parser(
        "upsert-asset",
        help="Create or replace one asset entry in notes/assets.json",
    )
    asset_parser.add_argument("--workspace", required=True)
    asset_parser.add_argument("--asset-id", required=True)
    asset_parser.add_argument("--asset-type", required=True, choices=ALLOWED_ASSET_TYPES)
    asset_parser.add_argument("--label")
    asset_parser.add_argument("--title")
    asset_parser.add_argument("--source-file")
    asset_parser.add_argument("--page", type=int)
    asset_parser.add_argument("--bbox", type=lambda value: [float(part) for part in value.split(",")])
    asset_parser.add_argument("--capture-kind")
    asset_parser.add_argument("--primary-output")
    asset_parser.add_argument("--capture-json")
    asset_parser.add_argument("--normalized-caption")
    asset_parser.add_argument("--raw-caption")
    asset_parser.add_argument("--source-section")
    asset_parser.add_argument("--quality", default="high")
    asset_parser.add_argument("--candidate-role", action="append")
    asset_parser.add_argument("--notes")
    asset_parser.add_argument("--cleanup-needed", action="store_true")
    asset_parser.add_argument("--equation-text")
    asset_parser.add_argument("--equation-context")
    asset_parser.add_argument("--notation-hint", action="append")
    asset_parser.add_argument("--display-preferred", action="store_true")
    asset_parser.set_defaults(func=cmd_upsert_asset)

    render_parser = subparsers.add_parser(
        "render-notes",
        help="Render Markdown inspection notes from the JSON artifacts",
    )
    render_parser.add_argument("--workspace", required=True)
    render_parser.set_defaults(func=cmd_render_notes)

    render_archetypes_parser = subparsers.add_parser(
        "render-archetypes-ref",
        help="Render the derived Markdown archetype reference from archetypes.json",
    )
    render_archetypes_parser.add_argument("--out")
    render_archetypes_parser.set_defaults(func=cmd_render_archetypes_reference)

    escape_context_parser = subparsers.add_parser(
        "collect-escape-context",
        help="Emit payloads and target fragment paths for slides using render_mode=escape",
    )
    escape_context_parser.add_argument("--workspace", required=True)
    escape_context_parser.add_argument("--slide-id", action="append")
    escape_context_parser.set_defaults(func=cmd_collect_escape_context)

    validate_parser = subparsers.add_parser(
        "validate-artifacts",
        help="Validate JSON artifact cross-references and basic schema assumptions",
    )
    validate_parser.add_argument("--workspace", required=True)
    validate_parser.set_defaults(func=cmd_validate_artifacts)

    emit_parser = subparsers.add_parser(
        "emit-deck",
        help="Render a deterministic Typst deck scaffold from notes/slides.json",
    )
    emit_parser.add_argument("--workspace", required=True)
    emit_parser.add_argument("--out")
    emit_parser.add_argument("--disable-escape", action="store_true")
    emit_parser.set_defaults(func=cmd_emit_deck)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
