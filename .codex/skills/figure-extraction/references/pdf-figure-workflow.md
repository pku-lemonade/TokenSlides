# PDF Figure Workflow

## Best-Practice Summary

- Prefer the original source figure file over any PDF-derived recovery.
- If the PDF contains embedded raster images, extract those directly before attempting page rendering.
- If the figure is vector or page-composed, render the page as SVG or high-DPI PNG rather than screenshotting it manually.
- Keep extraction and cropping separate. First recover the best source asset, then crop or trim it.
- Do not use an automatic fallback chain by default. Inspect first, then choose extraction or rendering explicitly.

## Why

- Debian’s `pdfimages` manual describes it as a PDF image extractor that saves images from a PDF and can write JPEG/JPEG2000/JBIG2 data in native form. That makes it the right first step for embedded raster figures.
- `pdfimages -list` also reports the embedded image width and height, which lets you decide whether a likely source asset exists on the page.
- `pdftocairo` can emit SVG, PDF, PS, EPS, or raster formats and supports page selection plus page-region cropping, which makes it the right tool when the figure is vector/page content rather than an embedded raster image.
- Nature’s figure guide recommends exporting figure panels as vector artwork where possible, keeping text, arrows, and scale bars editable.
- PLOS emphasizes keeping scale bars and annotations clearly visible and warns that resizing can make them illegible.

## Practical Rule

1. Use `pdfimages list`.
2. If you see the figure as an embedded image on the page, use `extract`.
3. If not, use `render-page` as SVG first, or PNG at explicit DPI if needed.
4. Then run a separate crop/trim step.

## Local Evidence

In this repo, `pdfimages -list examples/vstack/vstack.pdf` reports embedded images whose dimensions match the original asset files closely, which means direct extraction is viable for that deck.

## External References

- Debian `pdfimages` man page: https://manpages.debian.org/bookworm/poppler-utils/pdfimages.1.en.html
- `pdftocairo` man page: https://www.mankier.com/1/pdftocairo
- Nature figure guide: https://research-figure-guide.nature.com/figures/preparing-figures-our-specifications/
- PLOS Biology figure guidance: https://journals.plos.org/plosbiology/article?id=10.1371/journal.pbio.3001161
