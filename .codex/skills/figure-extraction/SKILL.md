---
name: figure-extraction
description: Recover reusable figure assets from PDFs and slide decks while preserving original embedded assets when possible. This workflow is owned by the `figure_extractor` agent when figure recovery is delegated from a larger task, and it can also be used directly when figure recovery itself is the task.
---

# Figure Extraction

This skill is the operating procedure for `figure_extractor`.

When a parent workflow delegates figure recovery, stay scoped to PDF inspection and asset recovery. Leave slide writing, narrative structure, and final layout choices to the parent agent. When figure recovery itself is the whole task, use the same workflow directly.

## Workflow

1. Prefer the original source asset when it is available.
   - If the paper repo or deck assets already contain the figure file, use that directly instead of re-extracting from a PDF.
   - If a parent workflow already chose the output workspace, write extracted assets into that workspace asset directory, not a shared catch-all folder.
2. Inspect the PDF before extracting.
   - Run `scripts/extract_pdf_figures.py list <file.pdf>`.
   - If the target page contains embedded images of plausible size, prefer direct extraction.
3. Extract embedded images without re-rendering when possible.
   - Run `scripts/extract_pdf_figures.py extract <file.pdf> --page N --outdir <dir>`.
   - This uses `pdfimages`, which preserves embedded image data more faithfully than rendering the page.
4. Render the page only when direct extraction is not the right tool.
   - Use `scripts/extract_pdf_figures.py render-page <file.pdf> --page N --format svg --out <file>` for vector/page content.
   - Use `--format png --dpi 300` or higher for raster output when SVG is not appropriate.
5. Crop after extraction, not before.
   - Once you have the best source asset, use `$academic-paper-to-slides` figure prep or `../academic-paper-to-slides/scripts/prepare_figure.py`.

## Ownership Boundary

- `figure_extractor` owns this workflow during delegated figure recovery.
- Parent agents should delegate PDF or deck figure recovery here instead of carrying these instructions inline.
- Stop after recovering the best reusable source asset and reporting exact output paths unless the parent task explicitly asks for further cleanup.

## Routing Rules

- If `pdfimages list` shows a matching embedded raster image, extract it directly.
- If the figure is vector art, an included PDF page, or a composite page layout, render the page instead.
- Do not use automatic extraction fallbacks by default. Choose extraction mode deliberately based on `list` output.

## Notes

- `pdfimages` extracts embedded images, not arbitrary vector drawings.
- `pdftocairo -svg` is the preferred path for single-page vector/page content when you need editable output.
- After extraction, keep scale bars, legends, subplot labels, and in-figure titles if they are part of how the figure is interpreted.

## References

- For detailed extraction guidance and sources, read `references/pdf-figure-workflow.md`.
