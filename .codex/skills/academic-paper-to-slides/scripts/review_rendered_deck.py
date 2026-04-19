#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import fitz  # type: ignore[import-not-found]


SCHEMA_VERSION = "academic-paper-to-slides/v1"
SEVERITY_ORDER = {"none": 0, "warning": 1, "error": 2}
SCRIPT_DIR = Path(__file__).resolve().parent
ARCHETYPE_SPECS_PATH = SCRIPT_DIR.parent / "references" / "archetypes.json"
ALLOWED_RENDER_MODES = ("script", "escape")
ESCAPE_HINT_MAX_WORDS = 18
ESCAPE_HINT_MAX_CHARS = 140


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


def load_archetype_specs() -> dict[str, dict[str, Any]]:
    if not ARCHETYPE_SPECS_PATH.exists():
        return {}
    with ARCHETYPE_SPECS_PATH.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    archetypes = payload.get("archetypes")
    return archetypes if isinstance(archetypes, dict) else {}


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


def page_area(rect: fitz.Rect) -> float:
    return max(0.0, rect.width) * max(0.0, rect.height)


def extract_page_content(page: fitz.Page) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]]]:
    raw = page.get_text("dict")
    text_blocks: list[dict[str, Any]] = []
    image_blocks: list[dict[str, Any]] = []
    spans: list[dict[str, Any]] = []

    for block in raw.get("blocks", []):
        bbox = [round(float(value), 3) for value in block.get("bbox", [0, 0, 0, 0])]
        rect = fitz.Rect(bbox)
        if rect.is_empty:
            continue
        if block.get("type") == 0:
            parts = []
            font_sizes = []
            for line in block.get("lines", []):
                for span in line.get("spans", []):
                    text = " ".join(str(span.get("text", "")).split())
                    if not text:
                        continue
                    size = float(span.get("size") or 0.0)
                    font_sizes.append(size)
                    parts.append(text)
                    spans.append(
                        {
                            "text": text,
                            "size": round(size, 3),
                            "bbox": [round(float(value), 3) for value in span.get("bbox", bbox)],
                        }
                    )
            if parts:
                text_blocks.append(
                    {
                        "text": " ".join(parts),
                        "bbox": bbox,
                        "font_sizes": font_sizes,
                    }
                )
        elif block.get("type") == 1:
            image_blocks.append(
                {
                    "bbox": bbox,
                    "width": block.get("width"),
                    "height": block.get("height"),
                }
            )
    return text_blocks, image_blocks, spans


def append_issue(
    issues: list[dict[str, Any]],
    page_number: int | None,
    slide_id: str | None,
    issue_type: str,
    severity: str,
    summary: str,
    details: dict[str, Any] | None = None,
) -> None:
    issues.append(
        {
            "issue_id": "",
            "issue_type": issue_type,
            "severity": severity,
            "detected_stage": "rendered-slide-qa",
            "page_number": page_number,
            "slide_ids": [slide_id] if slide_id else [],
            "summary": summary,
            "details": details or {},
        }
    )


def slide_id_for_index(slides: list[dict[str, Any]], index: int) -> str:
    slide = slides[index - 1] if 0 < index <= len(slides) else {}
    return slide.get("slide_id") or f"slide-{index:02d}"


def build_render_plan(slides: list[dict[str, Any]]) -> list[dict[str, Any]]:
    if not slides:
        return []

    has_explicit_outline_slides = any(
        isinstance(slide, dict)
        and (
            slide.get("archetype") == "Outline / Roadmap"
            or slide.get("rhetorical_role") == "section-divider"
        )
        for slide in slides
    )

    if has_explicit_outline_slides:
        plan = []
        for index, slide in enumerate(slides, start=1):
            if not isinstance(slide, dict):
                continue
            kind = "title" if index == 1 and slide.get("archetype") == "Title slide" else "slide"
            if slide.get("archetype") == "Outline / Roadmap" or slide.get("rhetorical_role") == "section-divider":
                kind = "outline"
            plan.append(
                {
                    "kind": kind,
                    "slide_id": slide.get("slide_id") or f"slide-{index:02d}",
                    "section": slide.get("section"),
                }
            )
        return plan

    plan: list[dict[str, Any]] = []
    first_slide = slides[0] if slides else {}
    title_slide_id = first_slide.get("slide_id") if first_slide.get("archetype") == "Title slide" else "title-slide"
    plan.append({"kind": "title", "slide_id": title_slide_id or "title-slide"})

    current_section = None
    for index, slide in enumerate(slides, start=1):
        if not isinstance(slide, dict):
            continue
        if index == 1 and slide.get("archetype") == "Title slide":
            continue
        section = slide.get("section")
        if section and section != current_section:
            plan.append({"kind": "outline", "slide_id": None, "section": section})
            current_section = section
        plan.append({"kind": "slide", "slide_id": slide.get("slide_id") or f"slide-{index:02d}"})
    return plan


def append_escape_issues(
    issues: list[dict[str, Any]],
    slides: list[dict[str, Any]],
    compile_metadata: dict[str, Any] | None,
) -> None:
    archetype_specs = load_archetype_specs()
    for index, slide in enumerate(slides, start=1):
        if not isinstance(slide, dict):
            continue
        render_mode = normalize_render_mode(slide.get("render_mode"))
        if render_mode != "escape":
            continue
        slide_id = slide.get("slide_id") or f"slide-{index:02d}"
        append_issue(
            issues,
            None,
            slide_id,
            "escape-hatch-used",
            "warning",
            "Slide used escape render mode instead of the scripted archetype body.",
            {"archetype": slide.get("archetype"), "escape_hint": slide.get("escape_hint")},
        )

        spec = archetype_specs.get(str(slide.get("archetype") or ""))
        allowed_modes = (spec or {}).get("allowed_render_modes") or ["script"]
        if "escape" not in allowed_modes:
            append_issue(
                issues,
                None,
                slide_id,
                "escape-invalid-config",
                "warning",
                "Escape render mode is not allowed for this archetype.",
                {"archetype": slide.get("archetype"), "allowed_render_modes": allowed_modes},
            )

        hint_issue = escape_hint_issue(str(slide.get("escape_hint") or "").strip())
        if hint_issue:
            append_issue(
                issues,
                None,
                slide_id,
                "escape-invalid-config",
                "warning",
                f"Escape render mode is configured incorrectly: {hint_issue}.",
                {"archetype": slide.get("archetype")},
            )

    if compile_metadata and compile_metadata.get("escape_fallback_used"):
        slide_ids = compile_metadata.get("escape_fallback_slide_ids") or []
        issues.append(
            {
                "issue_id": "",
                "issue_type": "escape-fallback-used",
                "severity": "warning",
                "detected_stage": "rendered-slide-qa",
                "page_number": None,
                "slide_ids": slide_ids,
                "summary": "Validation re-emitted the deck with escape disabled after a compile failure.",
                "details": {
                    "fallback_deck": compile_metadata.get("compiled_deck_typ"),
                    "original_deck": compile_metadata.get("original_deck_typ"),
                },
            }
        )


def analyze_page(
    page: fitz.Page,
    page_number: int,
    slide_id: str,
    preview_path: Path,
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    rect = page.rect
    text_blocks, image_blocks, spans = extract_page_content(page)
    word_count = len(page.get_text("words"))
    occupied_rects = [fitz.Rect(item["bbox"]) for item in text_blocks + image_blocks]
    occupied_area = sum(page_area(item) for item in occupied_rects)
    occupancy_ratio = round(min(1.0, occupied_area / max(page_area(rect), 1.0)), 4)
    image_area = sum(page_area(fitz.Rect(item["bbox"])) for item in image_blocks)
    image_area_ratio = round(min(1.0, image_area / max(page_area(rect), 1.0)), 4)

    width = max(rect.width, 1.0)
    height = max(rect.height, 1.0)
    top_cutoff = rect.y0 + height * 0.33
    bottom_cutoff = rect.y0 + height * 0.60
    title_band = rect.y0 + height * 0.15
    side_margin = width * 0.025
    footer_band = rect.y1 - height * 0.06
    body_bottom_guard = rect.y1 - height * 0.10

    all_top = bool(occupied_rects) and all(item.y1 <= top_cutoff for item in occupied_rects)
    all_bottom = bool(occupied_rects) and all(item.y0 >= bottom_cutoff for item in occupied_rects)
    has_substantial_occupancy = occupancy_ratio >= 0.25

    min_font_size = None
    small_text_spans = 0
    for span in spans:
        size = float(span.get("size") or 0.0)
        if size <= 0:
            continue
        min_font_size = size if min_font_size is None else min(min_font_size, size)
        if size < 12.0 and len(str(span.get("text", "")).strip()) >= 12:
            small_text_spans += 1

    edge_crowding_blocks = []
    footer_overlap_blocks = []
    for block in text_blocks + image_blocks:
        block_rect = fitz.Rect(block["bbox"])
        is_body_block = block_rect.y0 >= title_band and block_rect.y1 <= body_bottom_guard
        if is_body_block and (
            block_rect.x0 <= rect.x0 + side_margin or block_rect.x1 >= rect.x1 - side_margin
        ):
            edge_crowding_blocks.append(block["bbox"])
        if block_rect.y1 < footer_band or block_rect.y0 >= footer_band:
            continue
        block_ratio = page_area(block_rect) / max(page_area(rect), 1.0)
        if "text" in block:
            font_sizes = block.get("font_sizes", [])
            font_max = max(font_sizes) if font_sizes else 0.0
            word_count = len(str(block.get("text", "")).split())
            if word_count >= 20 or font_max >= 22.0 or block_ratio >= 0.08:
                footer_overlap_blocks.append(block["bbox"])
        elif block_ratio >= 0.12:
            footer_overlap_blocks.append(block["bbox"])

    issues: list[dict[str, Any]] = []
    if page_number != 1 and word_count < 5 and not image_blocks and not has_substantial_occupancy:
        append_issue(
            issues,
            page_number,
            slide_id,
            "near-empty-page",
            "error",
            "Page is almost empty after render.",
            {"word_count": word_count, "image_count": len(image_blocks)},
        )
    elif page_number != 1 and not image_blocks and word_count <= 28 and all_top and not has_substantial_occupancy:
        append_issue(
            issues,
            page_number,
            slide_id,
            "title-only-page",
            "error",
            "Page looks like a title-only continuation page.",
            {"word_count": word_count, "occupancy_ratio": occupancy_ratio},
        )
    elif page_number != 1 and not image_blocks and word_count <= 50 and all_bottom and not has_substantial_occupancy:
        append_issue(
            issues,
            page_number,
            slide_id,
            "orphan-body-page",
            "error",
            "Page looks like an orphaned body fragment caused by overflow.",
            {"word_count": word_count, "occupancy_ratio": occupancy_ratio},
        )

    if small_text_spans >= 3:
        append_issue(
            issues,
            page_number,
            slide_id,
            "small-text-risk",
            "warning",
            "Several text spans render unusually small.",
            {"small_text_spans": small_text_spans, "min_font_size": min_font_size},
        )

    if edge_crowding_blocks:
        append_issue(
            issues,
            page_number,
            slide_id,
            "edge-crowding",
            "warning",
            "Some content sits very close to the slide edge.",
            {"count": len(edge_crowding_blocks)},
        )

    if footer_overlap_blocks:
        append_issue(
            issues,
            page_number,
            slide_id,
            "footer-band-overlap",
            "warning",
            "Content extends into the footer band and may collide with footer metadata.",
            {"count": len(footer_overlap_blocks)},
        )

    if image_blocks and image_area_ratio < 0.06 and word_count > 20:
        append_issue(
            issues,
            page_number,
            slide_id,
            "undersized-visual",
            "warning",
            "Image evidence is very small relative to the page.",
            {"image_area_ratio": image_area_ratio, "image_count": len(image_blocks)},
        )

    page_result = {
        "page_number": page_number,
        "slide_id": slide_id,
        "preview_path": rel_or_abs(preview_path),
        "word_count": word_count,
        "image_count": len(image_blocks),
        "occupancy_ratio": occupancy_ratio,
        "image_area_ratio": image_area_ratio,
        "min_font_size": round(min_font_size, 3) if min_font_size is not None else None,
        "small_text_spans": small_text_spans,
    }
    return page_result, issues


def write_previews(pdf_path: Path, output_dir: Path) -> list[Path]:
    preview_dir = output_dir / "pages"
    preview_dir.mkdir(parents=True, exist_ok=True)
    previews = []
    with fitz.open(pdf_path) as doc:
        for index, page in enumerate(doc, start=1):
            pix = page.get_pixmap(matrix=fitz.Matrix(1.6, 1.6), alpha=False)
            preview_path = preview_dir / f"page-{index:02d}.png"
            pix.save(preview_path)
            previews.append(preview_path)
    return previews


def build_review(
    pdf_path: Path,
    slides_json_path: Path | None,
    workspace: Path | None,
    output_dir: Path,
    output_json: Path,
    compile_metadata_path: Path | None = None,
) -> dict[str, Any]:
    slides_doc = load_json(slides_json_path) if slides_json_path and slides_json_path.exists() else {}
    slides = slides_doc.get("slides", [])
    render_plan = build_render_plan(slides) if slides else []
    compile_metadata = (
        load_json(compile_metadata_path)
        if compile_metadata_path and compile_metadata_path.exists()
        else {}
    )
    previews = write_previews(pdf_path, output_dir)
    page_results = []
    issues: list[dict[str, Any]] = []

    if slides:
        append_escape_issues(issues, slides, compile_metadata)

    with fitz.open(pdf_path) as doc:
        expected_pages = len(render_plan) if render_plan else len(slides)
        if slides and expected_pages != len(doc):
            append_issue(
                issues,
                None,
                None,
                "page-count-mismatch",
                "error",
                "Rendered page count does not match the expected render plan.",
                {
                    "planned_slides": len(slides),
                    "expected_rendered_pages": expected_pages,
                    "rendered_pages": len(doc),
                },
            )

        for index, page in enumerate(doc, start=1):
            if render_plan and index <= len(render_plan):
                plan_entry = render_plan[index - 1]
                slide_id = plan_entry.get("slide_id") or f"outline:{plan_entry.get('section', index)}"
            else:
                slide_id = slide_id_for_index(slides, index) if slides else f"slide-{index:02d}"
            page_result, page_issues = analyze_page(page, index, slide_id, previews[index - 1])
            if render_plan and index <= len(render_plan):
                plan_entry = render_plan[index - 1]
                page_result["page_kind"] = plan_entry.get("kind")
                if plan_entry.get("section"):
                    page_result["section"] = plan_entry.get("section")
            page_results.append(page_result)
            issues.extend(page_issues)

    error_count = sum(1 for issue in issues if issue["severity"] == "error")
    warning_count = sum(1 for issue in issues if issue["severity"] == "warning")
    for index, issue in enumerate(issues, start=1):
        issue["issue_id"] = f"{issue['issue_type']}-{index:03d}"
    status = "fail" if error_count else "warning" if warning_count else "pass"

    review = {
        "schema_version": SCHEMA_VERSION,
        "workspace": rel_or_abs(workspace) if workspace else None,
        "deck_pdf": rel_or_abs(pdf_path),
        "generated_at": iso_now(),
        "summary": {
            "status": status,
            "error_count": error_count,
            "warning_count": warning_count,
            "page_count": len(page_results),
            "expected_slide_count": len(slides) if slides else None,
            "expected_rendered_page_count": len(render_plan) if render_plan else (len(slides) if slides else None),
            "output_dir": rel_or_abs(output_dir),
            "escape_fallback_used": bool(compile_metadata.get("escape_fallback_used")),
        },
        "pages": page_results,
        "issues": issues,
    }
    save_json(output_json, review)
    return review


def main() -> None:
    parser = argparse.ArgumentParser(description="Render page previews and review a compiled slide deck PDF.")
    parser.add_argument("pdf")
    parser.add_argument("--workspace")
    parser.add_argument("--slides-json")
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--output-json")
    parser.add_argument("--compile-metadata")
    parser.add_argument("--fail-on", choices=("none", "warning", "error"), default="error")
    args = parser.parse_args()

    pdf_path = Path(args.pdf).expanduser().resolve()
    if not pdf_path.exists():
        raise SystemExit(f"pdf not found: {pdf_path}")

    workspace = Path(args.workspace).expanduser().resolve() if args.workspace else None
    output_dir = Path(args.output_dir).expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    slides_json_path = Path(args.slides_json).expanduser().resolve() if args.slides_json else None
    if slides_json_path is None and workspace:
        candidate = workspace / "notes" / "slides.json"
        if candidate.exists():
            slides_json_path = candidate

    if args.output_json:
        output_json = Path(args.output_json).expanduser().resolve()
    elif workspace and (workspace / "notes").exists():
        output_json = workspace / "notes" / "review.json"
    else:
        output_json = output_dir / "review.json"

    compile_metadata_path = Path(args.compile_metadata).expanduser().resolve() if args.compile_metadata else None

    review = build_review(pdf_path, slides_json_path, workspace, output_dir, output_json, compile_metadata_path)
    print(json.dumps(review, indent=2))

    threshold = SEVERITY_ORDER[args.fail_on]
    max_seen = max((SEVERITY_ORDER[issue["severity"]] for issue in review["issues"]), default=0)
    if threshold > 0 and max_seen >= threshold:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
