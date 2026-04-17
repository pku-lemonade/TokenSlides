# PDF Figure Workflow

## Best-Practice Summary

- Prefer the original source figure file over any PDF-derived recovery.
- Inspect the PDF page structure before capturing anything. Start from image placements, drawing regions, and nearby text blocks.
- If the figure is a standalone embedded raster image, keep the native bytes when the requested bbox matches it closely.
- If the figure is vector or page-composed, generate a cropped PDF region rather than a whole-page render.
- Do not use an automatic whole-page fallback chain by default. Inspect first, then choose the bbox and capture mode explicitly.

## Why

- PyMuPDF `Page.get_image_info(xrefs=True)` reports displayed image metadata including bbox and xref without loading image bytes, which makes it the right first-pass inspection primitive.
- PyMuPDF `Page.get_image_rects()` is the robust placement API when images are invoked through Form XObjects or reused more than once on a page.
- PyMuPDF cannot directly extract vector drawings as standalone image assets, but `get_drawings()` and `cluster_drawings()` expose enough page geometry to localize likely vector figure regions.
- PyMuPDF `show_pdf_page(..., clip=...)` lets you create a new cropped PDF page from the source page while preserving vector content.
- Nature’s figure guide recommends exporting figure panels as vector artwork where possible, keeping text, arrows, and scale bars editable.
- PLOS emphasizes keeping scale bars and annotations clearly visible and warns that resizing can make them illegible.

## Practical Rule

1. Run `inspect-page` for the target page.
2. If you see a high-confidence `raster` candidate and your intended bbox matches it closely, keep native raster bytes.
3. If the figure is `vector` or `composite`, use `capture-figure` and keep the cropped PDF as primary output.
4. Use the primary output directly in Typst: PDF for vector/composite captures, original raster bytes for embedded images.
5. Then run a separate crop/trim step only if the recovered bbox still includes paper chrome or inconsistent padding.

## Local Evidence

In this repo, `examples/research-overview/research.pdf` page 13 contains one displayed embedded raster image, which is a good sanity check for native raster capture. The old `examples/vstack/vstack.pdf` path referenced by earlier notes does not exist.

## External References

- PyMuPDF page API: https://pymupdf.readthedocs.io/en/latest/page.html
- PyMuPDF image recipes: https://pymupdf.readthedocs.io/en/latest/recipes-images.html
- PyMuPDF FAQ: https://pymupdf.readthedocs.io/en/latest/faq/index.html
- PyMuPDF document API: https://pymupdf.readthedocs.io/en/latest/document.html
- Nature figure guide: https://research-figure-guide.nature.com/figures/preparing-figures-our-specifications/
- PLOS Biology figure guidance: https://journals.plos.org/plosbiology/article?id=10.1371/journal.pbio.3001161
