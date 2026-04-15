# Figure Preparation

Use this reference when a paper figure has too much surrounding chrome, is cropped too tightly, or does not fit a slide aspect ratio cleanly.

## Best-Practice Rules

- Crop to remove irrelevant outer material first: page headers, line numbers, paper captions that live outside the panel, neighboring columns, and unrelated panels.
- Keep interpretive context: axes, legends, scale bars, inset markers, and low-edge labels must survive the crop.
- Preserve embedded chart titles, subplot labels, and in-figure annotations when they are part of how the slide reader interprets the result.
- Avoid blind crop-to-fill. If the aspect ratio mismatch is large, keep the trimmed figure at its native aspect ratio instead of cutting away important context.
- Add a small margin back after trimming. A crop that touches labels too tightly usually looks worse on slides than one with a little breathing room.
- Do not upscale raster figures by default. Enlarging a low-resolution crop rarely improves legibility.
- Judge the result at slide scale, not only as a standalone image.

These rules align with the external guidance this skill now follows:

- Microsoft’s crop workflow explicitly supports both trimming outer margins and adding margin back by outcropping, and it treats aspect-ratio cropping as a preview that should still be adjusted manually.
- PLOS’s figure guidance stresses preserving visible scale bars, annotations, and inset markings, and warns that reductions in display size can make labels illegible.
- Pillow distinguishes between `fit` for resized-and-cropped output and `pad` for resized output on a fixed canvas. That maps cleanly to explicit operator intent; it should not be hidden behind automatic fallbacks.

## Local Helper

Use `scripts/prepare_figure.py` to make figure handling reproducible.

### What It Does

- trims obvious outer margins against the corner background color
- adds a small safety margin back after trim
- defaults to `trim`, which removes true outer whitespace and keeps the image's native aspect ratio
- supports explicit `fit` when you deliberately want target-aspect cropping
- supports explicit `pad` when you deliberately want a fixed canvas
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
- mode: `trim`
- trim tolerance: `18`
- trim margin: `3%` plus `12px`
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

Force padding into a fixed canvas:

```bash
python3 .codex/skills/academic-paper-to-slides/scripts/prepare_figure.py \
  figure.png \
  --mode pad \
  --preview
```

Force aspect-ratio crop:

```bash
python3 .codex/skills/academic-paper-to-slides/scripts/prepare_figure.py \
  figure.png \
  --mode fit \
  --preview
```

### How To Read the Result

- If `mode_applied` is `fit`, the helper applied an explicit target-aspect crop.
- If `mode_applied` is `trim`, the helper removed only outer whitespace or paper chrome and preserved the figure's native aspect ratio.
- If `mode_applied` is `pad`, the helper preserved all content and added a fixed canvas; use this only when you truly want that extra canvas in the output file.

### When To Override Defaults

- Increase `--tolerance` for noisy JPEG borders or scanned figures.
- Increase `--margin-ratio` if labels sit too close to the edge after trim.
- Use `--mode fit` only when you are sure the crop will not remove essential labels or context.
- Use `--mode pad` only when you explicitly want a fixed canvas around the content.
- If `--mode fit` fails because upscaling would be required, either add `--allow-upscale` deliberately or stay with the default `trim`.
- Use `--allow-upscale` only when `--mode fit` or `--mode pad` truly needs it and the source raster is already high quality.

## External References

- Microsoft Support: https://support.microsoft.com/en-us/office/crop-a-picture-in-office-14d69647-bc93-4f06-9528-df95103aa1e6
- PLOS Biology, *Creating clear and informative image-based figures for scientific publications*: https://journals.plos.org/plosbiology/article?id=10.1371/journal.pbio.3001161
- Pillow `ImageOps` reference: https://pillow.readthedocs.io/en/stable/reference/ImageOps.html
