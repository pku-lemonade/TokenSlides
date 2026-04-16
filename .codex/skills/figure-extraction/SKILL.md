---
name: figure-extraction
description: Recovers reusable figure assets from paper PDFs and slide decks by inspecting pages and capturing raster, vector, or composite figure regions with the bundled helper script. Use when the user asks to extract, crop, or reuse figures from PDF or deck files, especially LaTeX-generated PDFs.
---

# Figure Extraction

This skill is the operating procedure for `figure_extractor`.

When a parent workflow delegates figure recovery, stay scoped to PDF inspection and asset recovery. Leave slide writing, narrative structure, and final layout choices to the parent agent. When figure recovery itself is the whole task, use the same workflow directly.

## Quick Start

- Use the bundled script as the default interface. Do not re-implement one-off PyMuPDF extraction logic inline unless you are debugging or extending the script itself.
- Inspect first:
  - `scripts/extract_pdf_figures.py inspect-page <file.pdf> --page N`
- Capture second:
  - `scripts/extract_pdf_figures.py capture-figure <file.pdf> --page N --bbox x0,y0,x1,y1 --mode auto --out <path>`
- If the script is missing a needed behavior, patch the script and then re-run it instead of bypassing it for a one-off extraction.

## Workflow

1. Prefer the original source asset when it is available.
   - If the paper repo or deck assets already contain the figure file, use that directly instead of re-extracting from a PDF.
   - If a parent workflow already chose the output workspace, write extracted assets into that workspace asset directory, not a shared catch-all folder.
2. Inspect the PDF before extracting.
   - Run `scripts/extract_pdf_figures.py inspect-page <file.pdf> --page N`.
   - Treat the script output as the source of truth for candidate bboxes and capture mode.
   - Choose a bbox deliberately. Do not guess from page screenshots if the helper can localize the region.
3. Capture from a bbox, not from a whole-page render.
   - Run `scripts/extract_pdf_figures.py capture-figure <file.pdf> --page N --bbox x0,y0,x1,y1 --mode auto --out <path>`.
   - `auto` preserves native raster bytes only when the bbox matches one displayed embedded image cleanly.
   - If the figure is vector or page-composed, the helper emits a cropped PDF as the primary asset and a PNG preview beside it.
4. Prefer preserving the visible figure over forcing native extraction.
   - If text, legends, axes, or overlays are separate page objects near the image, treat the figure as composite and keep the cropped PDF path.
   - Do not downgrade composite or vector figures to a whole-page screenshot just because they are not standalone embedded images.
5. Crop cleanup is still a separate follow-up step when needed.
   - Once you have the best source asset, use `$academic-paper-to-slides` figure prep or `../academic-paper-to-slides/scripts/prepare_figure.py` only if the captured bbox still contains paper chrome or inconsistent margins.

## Ownership Boundary

- `figure_extractor` owns this workflow during delegated figure recovery.
- Parent agents should delegate PDF or deck figure recovery here instead of carrying these instructions inline.
- Stop after recovering the best reusable source asset and reporting exact output paths unless the parent task explicitly asks for further cleanup.

## Routing Rules

- If `inspect-page` reports a high-confidence `raster` candidate and the requested bbox matches it closely, keep native raster bytes.
- If `inspect-page` reports `vector` or `composite`, capture the bbox as cropped PDF and keep the PNG only as preview or compatibility output.
- If the bbox intentionally cuts into a larger raster candidate, use `capture-figure --mode raster` and accept raster fallback instead of silently returning the full uncropped image.
- Do not use whole-page rendering as the default fallback. The helper should return the best figure-sized region it can localize.

## Notes

- This workflow is PyMuPDF-only. The helper depends on `pymupdf` and does not route through Poppler tools.
- Cropped PDF is the preferred vector-preserving artifact for LaTeX, TikZ, and mixed raster+vector figures.
- PNG preview output is for quick inspection and slide compatibility. It is not the preferred source of truth when a cropped PDF is available.
- After extraction, keep scale bars, legends, subplot labels, and in-figure titles if they are part of how the figure is interpreted.
- Parent agents should pass figure number, page hints, or a rough target description when they know them, and they should expect `bbox`, `primary_output`, and `preview_output` back from `figure_extractor`.

## References

- For detailed extraction guidance and sources, read `references/pdf-figure-workflow.md`.
