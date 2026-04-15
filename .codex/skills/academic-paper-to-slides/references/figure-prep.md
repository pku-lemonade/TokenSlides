# Figure Preparation

Use this reference when a paper figure has too much surrounding chrome, is cropped too tightly, or does not fit a slide aspect ratio cleanly.

## Best-Practice Rules

- Crop to remove irrelevant outer material first: page headers, line numbers, paper captions, neighboring columns, and unrelated panels.
- Keep interpretive context: axes, legends, scale bars, inset markers, and low-edge labels must survive the crop.
- Avoid blind crop-to-fill. If the aspect ratio mismatch is large, pad to the target canvas instead of cutting away important context.
- Add a small margin back after trimming. A crop that touches labels too tightly usually looks worse on slides than one with a little breathing room.
- Do not upscale raster figures by default. Enlarging a low-resolution crop rarely improves legibility.
- Judge the result at slide scale, not only as a standalone image.

These rules align with the external guidance this skill now follows:

- Microsoft’s crop workflow explicitly supports both trimming outer margins and adding margin back by outcropping, and it treats aspect-ratio cropping as a preview that should still be adjusted manually.
- PLOS’s figure guidance stresses preserving visible scale bars, annotations, and inset markings, and warns that reductions in display size can make labels illegible.
- Pillow distinguishes between `fit` for resized-and-cropped output and `pad` for resized output on a fixed canvas, which maps well to “crop only when the loss is small; otherwise pad.”

## Local Helper

Use `scripts/prepare_figure.py` to make figure handling reproducible.

### What It Does

- trims obvious outer margins against the corner background color
- adds a small safety margin back after trim
- chooses between `fit` and `pad` in `smart` mode based on how much content would be lost
- can bias the crop toward `top`, `bottom`, `left`, or `right` when labels sit near one edge
- can write a preview sheet showing `original`, `trimmed`, and `final`

### Default Behavior

```bash
python3 .codex/skills/academic-paper-to-slides/scripts/prepare_figure.py \
  path/to/figure.png \
  --preview
```

Default settings:

- preset canvas: `wide` = `1600x900`
- mode: `smart`
- trim tolerance: `18`
- trim margin: `3%` plus `12px`
- smart-mode crop threshold: `12%`
- no raster upscaling

### Common Patterns

Wide slide figure:

```bash
python3 .codex/skills/academic-paper-to-slides/scripts/prepare_figure.py \
  figure.png \
  --preset wide \
  --preview
```

4:3 or table-style slide:

```bash
python3 .codex/skills/academic-paper-to-slides/scripts/prepare_figure.py \
  figure.png \
  --preset standard \
  --preview
```

Protect bottom labels or legends:

```bash
python3 .codex/skills/academic-paper-to-slides/scripts/prepare_figure.py \
  figure.png \
  --anchor bottom \
  --preview
```

Force padding instead of crop-to-fill:

```bash
python3 .codex/skills/academic-paper-to-slides/scripts/prepare_figure.py \
  figure.png \
  --mode pad \
  --preview
```

Allow a little more crop-to-fit when the mismatch is small:

```bash
python3 .codex/skills/academic-paper-to-slides/scripts/prepare_figure.py \
  figure.png \
  --max-crop 0.18 \
  --preview
```

### How To Read the Result

- If `mode_applied` is `fit`, the aspect mismatch was small enough to crop safely.
- If `mode_applied` is `pad`, the mismatch was too large, so the helper preserved all content and added canvas instead.
- If `mode_applied` is `pad-no-upscale`, a fit would have required enlarging the raster, so the helper kept the content size and padded instead.

### When To Override Defaults

- Increase `--tolerance` for noisy JPEG borders or scanned figures.
- Increase `--margin-ratio` if labels sit too close to the edge after trim.
- Use `--mode fit` only when you are sure the crop will not remove essential labels or context.
- Use `--allow-upscale` only when the source raster is already high quality and the slide truly needs it.

## External References

- Microsoft Support: https://support.microsoft.com/en-us/office/crop-a-picture-in-office-14d69647-bc93-4f06-9528-df95103aa1e6
- PLOS Biology, *Creating clear and informative image-based figures for scientific publications*: https://journals.plos.org/plosbiology/article?id=10.1371/journal.pbio.3001161
- Pillow `ImageOps` reference: https://pillow.readthedocs.io/en/stable/reference/ImageOps.html
