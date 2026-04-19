# `imgs` API

`imgs` is the theme's common image layout helper for single images, side-by-side image groups, vertical stacks, captions, and auto-filling the remaining slide height.

Source: [images.typ](./images.typ)

## Input Forms

`imgs` accepts positional image items in two forms:

```typst
#imgs("/path/to/image.png")
```

```typst
#imgs(
  ("/path/to/image.png", [Caption text]),
)
```

You can mix multiple items:

```typst
#imgs(
  ("/path/a.png", [Left caption]),
  ("/path/b.png", [Right caption]),
)
```

Captions are shown automatically if at least one item provides a caption.

## Common Parameters

### Layout

- `dir`: Layout direction. Use `ltr` or `rtl` for horizontal rows and `ttb` or `btt` for vertical stacks. Default: `ltr`
- `width`: Overall width of the image block. Default: `100%`
- `widths`: Per-image column widths for horizontal multi-image layouts. Default: `auto`
- `gap`: Gap between items. Horizontal rows use it as column gap; vertical stacks use it as row gap. Default: `0em`
- `valign`: Vertical alignment inside horizontal multi-image grid cells. Default: `horizon`

### Image Sizing

- `img-width`: Width passed to each image in normal mode. Default: `100%`
- `img-height`: Explicit image height. Default: `auto`
- `img-fit`: Image fit mode when height is constrained. Default: `"contain"`
- `fill-height`: Whether to fill the remaining slide height below the current text. Default: `auto`, which resolves through the theme's `imgs-config`
- `fill-pad`: Extra bottom padding kept when fill-height mode is active. Default: `auto`, which resolves through the theme's `imgs-config`

### Caption Styling

- `cap-size`: Caption font size. Default: `auto`, which resolves through the theme's `imgs-config` (currently `18pt`)
- `cap-weight`: Caption font weight. Default: `auto`, which resolves through the theme's `imgs-config` (currently `"bold"`)
- `cap-color`: Caption color. Default: `auto`
- `cap-gap`: Gap between image row and caption row. Default: `0.2em`

### Framing

- `border`: Optional border stroke around each image
- `border-radius`: Optional image corner radius. Default: `0pt`
- `inset`: Inner padding for framed images. Default: `0pt`

## Recommended Patterns

### Theme Defaults

You can set deck-wide defaults in `lemonade-theme`:

```typst
#show: lemonade-theme.with(
  imgs-config: (
    fill-height: true,
    fill-pad: 0.5em,
    cap-size: 18pt,
    cap-weight: "bold",
  ),
)
```

After that, `#imgs(...)` will inherit those defaults unless a slide overrides them explicitly.

The older `imgs-fill-height`, `imgs-fill-pad`, `imgs-cap-size`, and `imgs-cap-weight` arguments still work as compatibility shims, but new code should use `imgs-config`.

Use per-slide override when needed:

```typst
#imgs("/examples/assets/image.png", fill-height: false)
```

### 1. Plain Single Image

```typst
#imgs(
  "/examples/assets/image.png",
  width: 62%,
)
```

Use this for ordinary centered figures when you want explicit width control.

### 2. Single Image with Caption

```typst
#imgs(
  ("/examples/assets/image.png", [Figure caption]),
  width: 70%,
)
```

Use this when the slide needs a standard figure caption under the image.

### 3. Two Images Side by Side

```typst
#imgs(
  ("/examples/assets/image-1.png", [Left]),
  ("/examples/assets/image-2.png", [Right]),
  width: 100%,
  gap: 1em,
)
```

Use this for direct visual comparison.

### 4. Uneven Two-Column Layout

```typst
#imgs(
  ("/examples/assets/image-1.png", [Main figure]),
  ("/examples/assets/image-2.png", [Secondary figure]),
  width: 100%,
  widths: (1.4fr, 1fr),
  gap: 1em,
)
```

Use this when one figure should dominate.

### 5. Explicit Height Control

```typst
#imgs(
  ("/examples/assets/image.png", [Fixed height]),
  width: 80%,
  img-height: 220pt,
)
```

Use this when you want stable, manual figure sizing.

### 6. Fill Remaining Height

```typst
#imgs(
  ("/examples/assets/image.png", [Auto fill]),
  width: 78%,
  fill-height: true,
)
```

Use this on slides where text comes first and the figure should expand to use the rest of the page.
If your whole deck mostly uses this mode, prefer the theme-level `imgs-config: (fill-height: true, ...)`.
When the image is width-limited rather than height-limited, the helper now keeps spare vertical slack above the image row so the caption stays visually attached under the image.

### 7. Vertical Stacked Evidence

```typst
#imgs(
  ("/examples/assets/overview.png", [Overview]),
  ("/examples/assets/detail.png", [Detail]),
  dir: ttb,
  width: 100%,
  gap: 0.6em,
)
```

Use this for right-column evidence stacks such as overview-plus-zoom or result-plus-breakdown. When `fill-height` is active, `imgs(dir: ttb, ...)` shares the remaining height across the stacked items instead of letting each figure block fill it independently.

## Behavior Notes

- `fill-height: true` is intended for content slides where the image block appears after the main text.
- In fill-height mode, captions stay directly under the rendered image row; spare height is kept above the image instead of between the image and caption.
- Do not build a vertical evidence column by chaining multiple `#imgs(...)` blocks when the deck default is `fill-height: true`; use `#imgs(..., dir: ttb)` so the stacked items divide the available height predictably.
- Very wide composite figures may still look small in vertical layouts because width becomes the limiting dimension. In those cases, splitting or cropping the figure is still the better choice.
- `img-height` and `fill-height` are different modes:
  - `img-height` is manual and fixed.
  - `fill-height` is dynamic and depends on current slide position.

## Floating Placement Helpers

These helpers are for small anchored images such as logos and QR codes, not main evidence figures.

### 8. Place The Theme Logo

```typst
#place-logo(width: 10%)
```

Use this for the default theme logo in the top-right corner.

### 9. Place A Bottom-Right QR Code

```typst
#place-image(
  assets.qr-code,
  caption: "pku-lemonade",
  width: 20%,
  position: bottom + right,
  dx: 0em,
  dy: 1em,
)
```

Use this on thank-you or contact slides when you want a QR code plus a short mono caption.
