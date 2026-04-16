#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


_FITZ = None


def fitz_module():
    global _FITZ
    if _FITZ is None:
        try:
            import fitz  # type: ignore[import-not-found]
        except ImportError as exc:
            raise SystemExit(
                "PyMuPDF is required for figure extraction. Install it with "
                "`python3 -m pip install pymupdf`."
            ) from exc
        _FITZ = fitz
    return _FITZ


def to_rect(value: Any):
    fitz = fitz_module()
    rect = fitz.Rect(value)
    return fitz.Rect(
        min(rect.x0, rect.x1),
        min(rect.y0, rect.y1),
        max(rect.x0, rect.x1),
        max(rect.y0, rect.y1),
    )


def clip_rect(rect, container):
    fitz = fitz_module()
    clipped = fitz.Rect(
        max(rect.x0, container.x0),
        max(rect.y0, container.y0),
        min(rect.x1, container.x1),
        min(rect.y1, container.y1),
    )
    if clipped.x1 <= clipped.x0 or clipped.y1 <= clipped.y0:
        return fitz.Rect(0, 0, 0, 0)
    return clipped


def rect_area(rect) -> float:
    return max(0.0, rect.x1 - rect.x0) * max(0.0, rect.y1 - rect.y0)


def rect_to_list(rect) -> list[float]:
    return [round(rect.x0, 3), round(rect.y0, 3), round(rect.x1, 3), round(rect.y1, 3)]


def union_rect(a, b):
    fitz = fitz_module()
    return fitz.Rect(min(a.x0, b.x0), min(a.y0, b.y0), max(a.x1, b.x1), max(a.y1, b.y1))


def expand_rect(rect, margin: float, container):
    fitz = fitz_module()
    expanded = fitz.Rect(rect.x0 - margin, rect.y0 - margin, rect.x1 + margin, rect.y1 + margin)
    return clip_rect(expanded, container)


def rects_touch_or_close(a, b, tolerance: float) -> bool:
    return not (
        a.x1 + tolerance < b.x0
        or b.x1 + tolerance < a.x0
        or a.y1 + tolerance < b.y0
        or b.y1 + tolerance < a.y0
    )


def intersection_rect(a, b):
    return clip_rect(a, b)


def overlap_ratio(a, b) -> float:
    inter = intersection_rect(a, b)
    inter_area = rect_area(inter)
    denom = min(rect_area(a), rect_area(b))
    if inter_area <= 0 or denom <= 0:
        return 0.0
    return inter_area / denom


def intersection_over_union(a, b) -> float:
    inter = rect_area(intersection_rect(a, b))
    if inter <= 0:
        return 0.0
    union = rect_area(a) + rect_area(b) - inter
    if union <= 0:
        return 0.0
    return inter / union


def compact_text(text: str, max_len: int = 96) -> str:
    compact = " ".join(text.split())
    if len(compact) <= max_len:
        return compact
    return compact[: max_len - 1] + "..."


def page_text_blocks(page) -> list[dict[str, Any]]:
    page_rect = to_rect(page.rect)
    page_area = rect_area(page_rect)
    blocks = []
    for raw in page.get_text("blocks"):
        if len(raw) < 5:
            continue
        text = compact_text(raw[4])
        if not text:
            continue
        rect = clip_rect(to_rect(raw[:4]), page_rect)
        if rect_area(rect) <= 0:
            continue
        if rect_area(rect) / page_area > 0.25:
            continue
        blocks.append({"rect": rect, "text": text})
    return blocks


def plausible_nearby_text_blocks(base_rect, text_blocks: list[dict[str, Any]], page_rect, margin: float) -> list[dict[str, Any]]:
    page_width = max(1.0, page_rect.x1 - page_rect.x0)
    page_height = max(1.0, page_rect.y1 - page_rect.y0)
    base_width = max(1.0, base_rect.x1 - base_rect.x0)
    selected = []
    for block in text_blocks:
        rect = block["rect"]
        if not rects_touch_or_close(base_rect, rect, margin):
            continue
        width = rect.x1 - rect.x0
        height = rect.y1 - rect.y0
        if touches_page_edge(rect, page_rect, tolerance=4.0) >= 2 and (
            width / page_width >= 0.5 or height / page_height >= 0.5
        ):
            continue
        if width > max(base_width * 1.35, page_width * 0.65):
            continue
        selected.append(block)
    return selected


def touches_page_edge(rect, page_rect, tolerance: float = 2.0) -> int:
    return sum(
        (
            rect.x0 <= page_rect.x0 + tolerance,
            rect.y0 <= page_rect.y0 + tolerance,
            rect.x1 >= page_rect.x1 - tolerance,
            rect.y1 >= page_rect.y1 - tolerance,
        )
    )


def is_page_background(rect, page_rect) -> bool:
    page_area = rect_area(page_rect)
    if page_area <= 0:
        return False
    area_ratio = rect_area(rect) / page_area
    page_width = max(1.0, page_rect.x1 - page_rect.x0)
    page_height = max(1.0, page_rect.y1 - page_rect.y0)
    width_ratio = (rect.x1 - rect.x0) / page_width
    height_ratio = (rect.y1 - rect.y0) / page_height
    edge_count = touches_page_edge(rect, page_rect)
    if area_ratio >= 0.98 and edge_count >= 4:
        return True
    if width_ratio >= 0.95 and height_ratio <= 0.1 and edge_count >= 2:
        return True
    if height_ratio >= 0.95 and width_ratio <= 0.1 and edge_count >= 2:
        return True
    return False


def page_drawing_rects(page) -> list[Any]:
    page_rect = to_rect(page.rect)
    page_area = rect_area(page_rect)
    rects = []
    for drawing in page.get_drawings():
        raw_rect = drawing.get("rect")
        if raw_rect is None:
            continue
        rect = clip_rect(to_rect(raw_rect), page_rect)
        area = rect_area(rect)
        if area <= 0:
            continue
        area_ratio = area / page_area if page_area else 0.0
        if area_ratio < 0.0005:
            continue
        if is_page_background(rect, page_rect):
            continue
        if area_ratio > 0.92 and touches_page_edge(rect, page_rect) >= 3:
            continue
        rects.append(rect)
    return rects


def cluster_rects(rects: list[Any], tolerance: float = 6.0) -> list[dict[str, Any]]:
    clusters: list[dict[str, Any]] = []
    for rect in rects:
        pending = {"rect": rect, "count": 1}
        merged = True
        while merged:
            merged = False
            next_clusters = []
            for cluster in clusters:
                if rects_touch_or_close(pending["rect"], cluster["rect"], tolerance):
                    pending["rect"] = union_rect(pending["rect"], cluster["rect"])
                    pending["count"] += cluster["count"]
                    merged = True
                else:
                    next_clusters.append(cluster)
            clusters = next_clusters
        clusters.append(pending)
    return clusters


def resolve_image_placement(page, xref: int, fallback_rect):
    if xref <= 0:
        return fallback_rect
    try:
        placements = page.get_image_rects(xref, transform=True)
    except Exception:
        return fallback_rect
    rects = []
    for placement in placements:
        rect = placement[0] if isinstance(placement, tuple) else placement
        rects.append(to_rect(rect))
    if not rects:
        return fallback_rect
    rects.sort(key=lambda rect: (overlap_ratio(rect, fallback_rect), rect_area(rect)), reverse=True)
    return rects[0]


def build_image_candidates(page, drawing_rects: list[Any], text_blocks: list[dict[str, Any]]) -> list[dict[str, Any]]:
    page_rect = to_rect(page.rect)
    page_area = rect_area(page_rect)
    candidates = []
    for index, info in enumerate(page.get_image_info(xrefs=True), start=1):
        raw_bbox = info.get("bbox")
        if not raw_bbox:
            continue
        source_bbox = clip_rect(to_rect(raw_bbox), page_rect)
        if rect_area(source_bbox) <= 0:
            continue
        xref = int(info.get("xref") or 0)
        placement = clip_rect(resolve_image_placement(page, xref, source_bbox), page_rect)
        nearby_drawings = [rect for rect in drawing_rects if rects_touch_or_close(placement, rect, 12.0)]
        nearby_text = plausible_nearby_text_blocks(placement, text_blocks, page_rect, margin=14.0)

        expanded_bbox = placement
        for rect in nearby_drawings:
            expanded_bbox = union_rect(expanded_bbox, rect)
        for block in nearby_text:
            expanded_bbox = union_rect(expanded_bbox, block["rect"])
        expanded_bbox = clip_rect(expanded_bbox, page_rect)

        area_ratio = rect_area(placement) / page_area if page_area else 0.0
        expansion_ratio = rect_area(expanded_bbox) / max(rect_area(placement), 1.0)
        kind = "composite" if nearby_drawings or nearby_text or expansion_ratio > 1.08 else "raster"

        confidence = 0.35 + min(0.35, area_ratio * 0.7)
        if xref > 0:
            confidence += 0.15
        if kind == "raster":
            confidence += 0.1
        if area_ratio < 0.05:
            confidence -= 0.1
        confidence = max(0.05, min(0.95, confidence))

        reason_bits = [f"displayed image xref={xref}" if xref > 0 else "displayed image"]
        if nearby_drawings:
            reason_bits.append(f"{len(nearby_drawings)} nearby drawing region(s)")
        if nearby_text:
            reason_bits.append(f"{len(nearby_text)} nearby text block(s)")

        candidate_bbox = expanded_bbox if kind == "composite" else placement
        candidates.append(
            {
                "id": f"image-{index}",
                "kind": kind,
                "source": "image",
                "page": page.number + 1,
                "_bbox": candidate_bbox,
                "_source_bbox": placement,
                "xref": xref if xref > 0 else None,
                "width": int(info.get("width") or 0),
                "height": int(info.get("height") or 0),
                "has_mask": bool(info.get("has-mask")),
                "page_coverage": round(rect_area(candidate_bbox) / page_area, 4) if page_area else 0.0,
                "confidence": round(confidence, 3),
                "suggested_mode": "composite" if kind == "composite" else "raster",
                "nearby_drawings": len(nearby_drawings),
                "nearby_text_blocks": len(nearby_text),
                "nearby_text_preview": [block["text"] for block in nearby_text[:3]],
                "reason": "; ".join(reason_bits),
            }
        )
    return candidates


def build_vector_candidates(page, drawing_rects: list[Any], text_blocks: list[dict[str, Any]]) -> list[dict[str, Any]]:
    page_rect = to_rect(page.rect)
    page_area = rect_area(page_rect)
    clusters = cluster_rects(drawing_rects, tolerance=6.0)
    candidates = []
    index = 1
    for cluster in clusters:
        cluster_rect = clip_rect(cluster["rect"], page_rect)
        cluster_area = rect_area(cluster_rect)
        if cluster_area <= 0 or (page_area and cluster_area / page_area > 0.95):
            continue
        nearby_text = plausible_nearby_text_blocks(cluster_rect, text_blocks, page_rect, margin=14.0)
        expanded_bbox = cluster_rect
        for block in nearby_text:
            expanded_bbox = union_rect(expanded_bbox, block["rect"])
        expanded_bbox = clip_rect(expanded_bbox, page_rect)
        area_ratio = rect_area(expanded_bbox) / page_area if page_area else 0.0
        if area_ratio < 0.01:
            continue
        confidence = 0.25 + min(0.4, area_ratio * 0.8)
        if touches_page_edge(expanded_bbox, page_rect) >= 3 and area_ratio > 0.75:
            confidence -= 0.2
        if cluster["count"] >= 3:
            confidence += 0.05
        confidence = max(0.05, min(0.9, confidence))
        candidates.append(
            {
                "id": f"vector-{index}",
                "kind": "vector",
                "source": "drawings",
                "page": page.number + 1,
                "_bbox": expanded_bbox,
                "_source_bbox": cluster_rect,
                "xref": None,
                "page_coverage": round(rect_area(expanded_bbox) / page_area, 4) if page_area else 0.0,
                "confidence": round(confidence, 3),
                "suggested_mode": "vector",
                "drawing_rects": cluster["count"],
                "nearby_text_blocks": len(nearby_text),
                "nearby_text_preview": [block["text"] for block in nearby_text[:3]],
                "reason": (
                    f"vector cluster from {cluster['count']} drawing rect(s)"
                    + (f" with {len(nearby_text)} nearby text block(s)" if nearby_text else "")
                ),
            }
        )
        index += 1
    return candidates


def serialize_candidate(candidate: dict[str, Any]) -> dict[str, Any]:
    data = {key: value for key, value in candidate.items() if not key.startswith("_")}
    data["bbox"] = rect_to_list(candidate["_bbox"])
    data["source_bbox"] = rect_to_list(candidate["_source_bbox"])
    return data


def analyze_page(doc, page_number: int) -> dict[str, Any]:
    if page_number < 1 or page_number > doc.page_count:
        raise SystemExit(f"page {page_number} is out of range for PDF with {doc.page_count} page(s)")
    page = doc[page_number - 1]
    page_rect = to_rect(page.rect)
    text_blocks = page_text_blocks(page)
    drawing_rects = page_drawing_rects(page)
    candidates = build_image_candidates(page, drawing_rects, text_blocks)
    candidates.extend(build_vector_candidates(page, drawing_rects, text_blocks))
    candidates.sort(key=lambda item: (item["confidence"], item["page_coverage"]), reverse=True)
    return {
        "page": page,
        "page_number": page_number,
        "page_rect": page_rect,
        "text_blocks": text_blocks,
        "drawing_rects": drawing_rects,
        "candidates": candidates,
    }


def preview_path_for(primary_output: Path) -> Path:
    if primary_output.suffix.lower() == ".png":
        return primary_output
    return primary_output.with_name(f"{primary_output.stem}-preview.png")


def ensure_output_path(path: Path, suffix: str) -> Path:
    resolved = path.expanduser().resolve()
    if resolved.suffix.lower() != suffix.lower():
        resolved = resolved.with_suffix(suffix)
    resolved.parent.mkdir(parents=True, exist_ok=True)
    return resolved


def parse_bbox(value: str) -> tuple[float, float, float, float]:
    parts = [part.strip() for part in value.split(",")]
    if len(parts) != 4:
        raise argparse.ArgumentTypeError("bbox must be formatted as x0,y0,x1,y1")
    try:
        return tuple(float(part) for part in parts)  # type: ignore[return-value]
    except ValueError as exc:
        raise argparse.ArgumentTypeError("bbox must contain numeric coordinates") from exc


def matching_candidates(clip, candidates: list[dict[str, Any]]) -> list[dict[str, Any]]:
    matches = []
    for candidate in candidates:
        bbox = candidate["_bbox"]
        score = max(overlap_ratio(bbox, clip), intersection_over_union(bbox, clip))
        if score <= 0:
            continue
        matches.append(
            {
                "candidate": candidate,
                "score": score,
                "iou": intersection_over_union(candidate["_source_bbox"], clip),
            }
        )
    matches.sort(key=lambda item: (item["score"], item["candidate"]["confidence"]), reverse=True)
    return matches


def select_capture_mode(requested_mode: str, _clip, matches: list[dict[str, Any]]) -> tuple[str, dict[str, Any] | None]:
    best_match = matches[0]["candidate"] if matches else None
    best_image = next((item for item in matches if item["candidate"]["source"] == "image"), None)
    best_non_raster = next((item for item in matches if item["candidate"]["kind"] != "raster"), None)

    if requested_mode == "vector":
        target = best_non_raster["candidate"] if best_non_raster else best_match
        return "cropped-vector-pdf", target
    if requested_mode == "composite":
        composite = next((item for item in matches if item["candidate"]["kind"] == "composite"), None)
        if composite:
            return "cropped-composite-pdf", composite["candidate"]
        target = best_non_raster["candidate"] if best_non_raster else best_match
        return "cropped-composite-pdf", target
    if requested_mode == "raster":
        if best_image and best_image["candidate"]["xref"] and best_image["iou"] >= 0.7:
            return "native-raster", best_image["candidate"]
        return "fallback-raster", best_image["candidate"] if best_image else best_match

    if best_image and best_image["candidate"]["kind"] == "raster":
        if best_image["candidate"]["xref"] and best_image["iou"] >= 0.7:
            return "native-raster", best_image["candidate"]
        return "fallback-raster", best_image["candidate"]
    if best_image and best_image["candidate"]["kind"] == "composite":
        return "cropped-composite-pdf", best_image["candidate"]
    if best_non_raster:
        kind = "cropped-composite-pdf" if best_non_raster["candidate"]["kind"] == "composite" else "cropped-vector-pdf"
        return kind, best_non_raster["candidate"]
    if best_image:
        return "fallback-raster", best_image["candidate"]
    return "cropped-vector-pdf", best_match


def save_preview(page, clip, path: Path, dpi: int) -> Path:
    pix = page.get_pixmap(clip=clip, dpi=dpi, alpha=False)
    pix.save(path)
    return path


def save_native_raster(
    doc,
    page,
    clip,
    candidate: dict[str, Any],
    out: Path,
    preview_dpi: int,
    write_preview: bool,
) -> tuple[Path, Path | None]:
    fitz = fitz_module()
    xref = candidate.get("xref")
    if not xref:
        raise ValueError("native raster capture requires an image candidate with an xref")

    extracted = doc.extract_image(xref)
    if not extracted:
        raise ValueError(f"could not extract image xref {xref}")

    smask = int(extracted.get("smask") or 0)
    if smask > 0:
        primary = ensure_output_path(out, ".png")
        main_pix = fitz.Pixmap(extracted["image"])
        mask_image = doc.extract_image(smask)
        if not mask_image:
            raise ValueError(f"could not extract image mask xref {smask}")
        mask_pix = fitz.Pixmap(mask_image["image"])
        fitz.Pixmap(main_pix, mask_pix).save(primary)
    else:
        ext = "." + str(extracted.get("ext") or "png").lower()
        primary = ensure_output_path(out, ext)
        primary.write_bytes(extracted["image"])

    preview = preview_path_for(primary)
    if write_preview and preview != primary:
        save_preview(page, clip, preview, preview_dpi)
    if not write_preview and preview != primary:
        preview = None
    return primary, preview


def save_cropped_pdf(doc, page_number: int, clip, out: Path) -> Path:
    fitz = fitz_module()
    primary = ensure_output_path(out, ".pdf")
    cropped = fitz.open()
    target_page = cropped.new_page(width=clip.x1 - clip.x0, height=clip.y1 - clip.y0)
    target_page.show_pdf_page(target_page.rect, doc, page_number - 1, clip=clip)
    cropped.save(primary)
    cropped.close()
    return primary


def save_fallback_raster(page, clip, out: Path, preview_dpi: int) -> tuple[Path, Path]:
    primary = ensure_output_path(out, ".png")
    save_preview(page, clip, primary, preview_dpi)
    return primary, primary


def cmd_inspect_page(args: argparse.Namespace) -> None:
    fitz = fitz_module()
    pdf = Path(args.pdf).expanduser().resolve()
    doc = fitz.open(pdf)
    analysis = analyze_page(doc, args.page)
    output = {
        "pdf": str(pdf),
        "page": args.page,
        "page_rect": rect_to_list(analysis["page_rect"]),
        "candidate_count": len(analysis["candidates"]),
        "image_candidates": sum(1 for candidate in analysis["candidates"] if candidate["source"] == "image"),
        "vector_candidates": sum(1 for candidate in analysis["candidates"] if candidate["source"] == "drawings"),
        "candidates": [serialize_candidate(candidate) for candidate in analysis["candidates"]],
    }
    print(json.dumps(output, indent=2))


def cmd_capture_figure(args: argparse.Namespace) -> None:
    fitz = fitz_module()
    pdf = Path(args.pdf).expanduser().resolve()
    doc = fitz.open(pdf)
    analysis = analyze_page(doc, args.page)
    page = analysis["page"]
    page_rect = analysis["page_rect"]
    clip = clip_rect(to_rect(args.bbox), page_rect)
    if rect_area(clip) <= 0:
        raise SystemExit("bbox does not intersect the selected page")

    matches = matching_candidates(clip, analysis["candidates"])
    selection_mode, selected_candidate = select_capture_mode(args.mode, clip, matches)
    out = Path(args.out)

    if selection_mode == "native-raster":
        primary_output, preview_output = save_native_raster(
            doc,
            page,
            clip,
            selected_candidate,
            out,
            args.preview_dpi,
            args.preview_png,
        )
    elif selection_mode in ("cropped-vector-pdf", "cropped-composite-pdf"):
        primary_output = save_cropped_pdf(doc, args.page, clip, out)
        preview_output = preview_path_for(primary_output)
        if args.preview_png:
            save_preview(page, clip, preview_output, args.preview_dpi)
        else:
            preview_output = None
    else:
        primary_output, preview_output = save_fallback_raster(page, clip, out, args.preview_dpi)

    if not args.preview_png:
        preview_output = None

    output = {
        "pdf": str(pdf),
        "page": args.page,
        "bbox": rect_to_list(clip),
        "selection_mode": selection_mode,
        "primary_output": str(primary_output),
        "preview_output": str(preview_output) if preview_output else None,
        "matched_candidates": [
            {
                "id": item["candidate"]["id"],
                "kind": item["candidate"]["kind"],
                "source": item["candidate"]["source"],
                "score": round(item["score"], 3),
                "confidence": item["candidate"]["confidence"],
            }
            for item in matches[:5]
        ],
        "selected_candidate": serialize_candidate(selected_candidate) if selected_candidate else None,
    }
    print(json.dumps(output, indent=2))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Inspect PDF page content with PyMuPDF and capture raster or vector figure regions."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    inspect_parser = subparsers.add_parser("inspect-page", help="Inspect image, vector, and composite candidates on one page")
    inspect_parser.add_argument("pdf")
    inspect_parser.add_argument("--page", type=int, required=True)
    inspect_parser.set_defaults(func=cmd_inspect_page)

    capture_parser = subparsers.add_parser("capture-figure", help="Capture one figure region as raster or cropped PDF")
    capture_parser.add_argument("pdf")
    capture_parser.add_argument("--page", type=int, required=True)
    capture_parser.add_argument("--bbox", required=True, type=parse_bbox)
    capture_parser.add_argument("--mode", choices=("auto", "raster", "vector", "composite"), default="auto")
    capture_parser.add_argument("--out", required=True)
    capture_parser.add_argument("--preview-png", action=argparse.BooleanOptionalAction, default=True)
    capture_parser.add_argument("--preview-dpi", type=int, default=300)
    capture_parser.set_defaults(func=cmd_capture_figure)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
