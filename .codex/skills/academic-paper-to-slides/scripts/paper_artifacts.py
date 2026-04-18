#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import fitz  # type: ignore[import-not-found]
from PIL import Image


SCHEMA_VERSION = "academic-paper-to-slides/v1"
ALLOWED_ASSET_TYPES = ("figure", "table", "equation")
ALLOWED_DENSITY_TARGETS = ("low", "medium", "high")
ALLOWED_REVIEW_STATUSES = ("pending", "pass", "warning", "fail")
SCRIPT_DIR = Path(__file__).resolve().parent
REFERENCE_ARCHETYPES_PATH = SCRIPT_DIR.parent / "references" / "archetypes.md"
FALLBACK_ARCHETYPES = {
    "Title slide",
    "Outline / Roadmap",
    "Motivation / Background",
    "Figure-Led Vertical",
    "Method Overview Side-by-Side",
    "Method Overview With Stacked Evidence",
    "Method Cards (2 or 3 Only)",
    "Two-Up Comparison",
    "Table-Led Structured Slide",
    "Wide or Fat Evidence",
    "Equation-Led Explanation",
    "Results Comparison",
    "Conclusion / Takeaways",
}


def load_known_archetypes() -> set[str]:
    if not REFERENCE_ARCHETYPES_PATH.exists():
        return set(FALLBACK_ARCHETYPES)

    headings: set[str] = set()
    for line in REFERENCE_ARCHETYPES_PATH.read_text(encoding="utf-8").splitlines():
        if not line.startswith("## "):
            continue
        heading = line[3:].strip()
        heading = re.sub(r"^\d+[a-z]?\.?\s*", "", heading, flags=re.IGNORECASE)
        if heading and heading.lower() != "selection rules":
            headings.add(heading)
    return headings.union(FALLBACK_ARCHETYPES) if headings else set(FALLBACK_ARCHETYPES)


KNOWN_ARCHETYPES = load_known_archetypes()


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
            "reference": rel_or_abs(REFERENCE_ARCHETYPES_PATH),
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
        "| # | Section | Title | Takeaway | Evidence | Archetype | Role | Density |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for index, slide in enumerate(slides, start=1):
        lines.append(
            "| {index} | {section} | {title} | {takeaway} | {evidence} | {archetype} | {role} | {density} |".format(
                index=index,
                section=str(slide.get("section", "")).replace("|", "/"),
                title=str(slide.get("title", "")).replace("|", "/"),
                takeaway=str(slide.get("takeaway", "")).replace("|", "/"),
                evidence=format_slide_evidence(slide).replace("|", "/"),
                archetype=str(slide.get("archetype", "")).replace("|", "/"),
                role=str(slide.get("rhetorical_role", "")).replace("|", "/"),
                density=str(slide.get("content_density", "")).replace("|", "/"),
            )
        )
    if not slides:
        lines.append("| 1 |  |  |  |  |  |  |  |")
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


def typst_escape(text: Any) -> str:
    value = str(text or "")
    return (
        value.replace("\\", "\\\\")
        .replace("[", "\\[")
        .replace("]", "\\]")
        .replace("#", "\\#")
    )


def asset_image_expr(asset: dict[str, Any], deck_path: Path, workspace: Path) -> str | None:
    primary_output = asset.get("primary_output")
    if not primary_output:
        return None
    asset_path = resolve_repo_relative(primary_output, workspace)
    suffix = asset_path.suffix.lower()
    if suffix not in {".png", ".jpg", ".jpeg", ".webp", ".svg"}:
        return None
    relative = os.path.relpath(asset_path, deck_path.parent)
    return f'image("{relative}")'


def render_slide_typst(
    slide: dict[str, Any],
    assets_by_id: dict[str, dict[str, Any]],
    deck_path: Path,
    workspace: Path,
) -> list[str]:
    lines: list[str] = []
    title = typst_escape(slide.get("title", "Untitled Slide"))
    takeaway = typst_escape(slide.get("takeaway", ""))
    slide_id = typst_escape(slide.get("slide_id", ""))
    claim_ids = ", ".join(slide.get("claim_ids", []))
    qa_expectations = ", ".join(str(item) for item in slide.get("qa_expectations", []))

    lines.append(f"== {title}")
    lines.append("")

    if takeaway:
        lines.extend(
            [
                "#ibox[",
                f"  *Takeaway:* {takeaway}",
                "]",
                "",
            ]
        )

    image_entries = []
    for asset_id in slide.get("asset_ids", []):
        asset = assets_by_id.get(asset_id)
        if not asset:
            continue
        image_expr = asset_image_expr(asset, deck_path, workspace)
        if not image_expr:
            continue
        caption = typst_escape(asset.get("normalized_caption") or asset.get("label") or asset_id)
        image_entries.append((image_expr, caption))
        if len(image_entries) >= 2:
            break

    if image_entries:
        lines.append("#imgs(")
        for image_expr, caption in image_entries:
            lines.append(f"  ({image_expr}, [{caption}]),")
        lines.append("  width: 92%,")
        lines.append(")")
        lines.append("")

    lines.append("#v(0.6em)")
    lines.append("")
    lines.append(f"- Slide id: `{slide_id}`" if slide_id else "- Slide id: `slide`")
    if claim_ids:
        lines.append(f"- Claim ids: `{claim_ids}`")
    if slide.get("rhetorical_role"):
        lines.append(f"- Role: {typst_escape(slide.get('rhetorical_role'))}")
    if slide.get("archetype"):
        lines.append(f"- Archetype: {typst_escape(slide.get('archetype'))}")
    if slide.get("content_density"):
        lines.append(f"- Density target: {typst_escape(slide.get('content_density'))}")

    evidence = format_slide_evidence(slide)
    if evidence:
        lines.append(f"- Evidence: {typst_escape(evidence)}")
    if qa_expectations:
        lines.append(f"- QA: {typst_escape(qa_expectations)}")

    unresolved_assets = []
    for asset_id in slide.get("asset_ids", []):
        asset = assets_by_id.get(asset_id)
        if asset and asset_image_expr(asset, deck_path, workspace) is None:
            unresolved_assets.append(asset_id)
    if unresolved_assets:
        lines.append(f"- Asset ids needing manual placement: `{', '.join(unresolved_assets)}`")

    lines.append("")
    return lines


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
    lang = "zh" if str(deck.get("language", "")).lower().startswith("zh") else "en"

    lines = [
        '#import "/lemonade.typ": *',
        "",
        f'#set text(lang: "{lang}")',
        "",
        "#show: lemonade-theme.with(",
        '  aspect-ratio: "16-9",',
        '  title-align: "left",',
        '  footer: "bar",',
        "  config-info(",
        f"    title: [{title}],",
        f"    venue: [{venue}],",
        f"    author: [{authors}],",
        f"    institution: [{institution}],",
        "  ),",
        ")",
        "",
        "#title-slide()",
        "",
    ]

    current_section = None
    slides = slides_doc.get("slides", [])
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
        lines.extend(render_slide_typst(slide, assets_by_id, deck_path, workspace))

    write_text(deck_path, "\n".join(lines).rstrip() + "\n")
    print(json.dumps({"deck_typ": str(deck_path), "slide_count": len(slides)}, indent=2))


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
        if archetype and archetype not in KNOWN_ARCHETYPES:
            warnings.append(f"slide {slide_id} uses unknown archetype: {archetype}")
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
    emit_parser.set_defaults(func=cmd_emit_deck)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
