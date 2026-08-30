---
name: convert-pdf-to-pptx
description: Convert a PDF or compiled Typst deck into a visually faithful flattened .pptx by placing each PDF page as one full-slide image. Use when fidelity, speed, and reliable playback matter more than object-level editability. Do not use when text, shapes, tables, or diagrams must remain editable.
---

# PDF to Visual PowerPoint

Create a static PowerPoint whose slides reproduce the source PDF. PowerPoint cannot portably use a PDF page as native slide artwork, so the default output uses a high-resolution page render.

## Boundary

- Input is a PDF; output is a verified `.pptx` with one source page per slide.
- Default to a 300 DPI PNG for each page. This is visually faithful at normal presentation and 4K-display scale, but it is not mathematically lossless and its contents are not editable.
- Flattening preserves only the visible PDF pages. It does not recover speaker notes, transitions, animations, hyperlinks, audio/video, accessibility structure, or editable objects.
- Use `svg` mode only when the user prioritizes vector scaling and a full exported-PPTX render matches the PDF. PDF-to-SVG can change fonts, masks, gradients, transparency, and embedded images; fall back to PNG on any mismatch.
- Use `$convert-typst-to-editable-pptx` instead when object-level editing is required. Do not mix flattened and reconstructed slides unless the user explicitly requests a hybrid deck.
- Keep the source PDF and any Typst source unchanged.

## Composition

- Use the installed `presentations:Presentations` skill when available. Announce both skills and read its `SKILL.md`; follow its runtime, artifact-operation marker, rendering, and packaging requirements.
- Skip template selection and narrative redesign. The PDF already owns all visible content and design.
- Use `scripts/convert_pdf_to_pptx.mjs` for deterministic conversion. It uses the PDF CropBox, preserves page order and aspect ratio, re-imports the exported PPTX, and refuses to overwrite an existing file unless `--force` is explicit.
- Require a common page aspect ratio by default because PPTX has one slide size for the entire deck. Use `--mixed-page-policy contain` only after accepting letterboxing for mixed-ratio pages.

## Workflow

1. If the source is Typst, compile a fresh PDF with the correct project root. Inspect the live PDF with `pdfinfo -box`; confirm page count, CropBox dimensions, rotation, encryption status, and aspect-ratio consistency.
2. Load workspace dependencies and set `RUNTIME_NODE`, `RUNTIME_NODE_MODULES`, and `RUNTIME_BIN_DIR` exactly as the presentation skill requires. Run:

   ```bash
   "$RUNTIME_NODE" "$SKILL_DIR/scripts/convert_pdf_to_pptx.mjs" \
     --input "$INPUT_PDF" \
     --output "$FINAL_PPTX" \
     --mode png \
     --dpi 300
   ```

3. Render the exported PPTX itself with the presentation skill's `render_slides.py`. Render the PDF pages separately and compare every page at the same pixel dimensions. Fix cropping, borders, resampling, color, page order, or aspect drift before delivery.
4. Run `slides_test.py`, `unzip -t`, and a final re-import or inspection. Confirm the slide count equals the PDF page count and each slide contains exactly one full-slide page image with no accidental overlays. In PNG mode, verify the embedded media hashes match the rendered page files and that `ppt/presProps.xml` retains the high-fidelity image-DPI setting.

Deliver only the final `.pptx` by default. State that it is flattened, report the rendering mode and DPI, and distinguish successful file validation from visual comparison.
