---
name: figure-extraction
description: Extract figures from PDFs and slide decks while preserving original embedded assets when possible. Use when the user asks to pull figures out of a PDF, recover reusable paper figures from LaTeX-generated PDFs, inspect embedded images, or render vector/page content for later cropping.
---

# Figure Extraction

Use this skill when figure extraction itself is the task. Keep extraction separate from slide writing so the main slide skill does not carry all PDF/image handling guidance.

## Workflow

1. Prefer the original source asset when it is available.
   - If the paper repo or deck assets already contain the figure file, use that directly instead of re-extracting from a PDF.
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
