# Lemonade Theme Notes

This skill is tailored to the local `lemonade.typ` slide theme.

## Entry Points

- `lemonade.typ` re-exports `theme/lemonade.typ`
- `theme/base.typ` controls global sizes, spacing, colors, and runtime state
- `theme/slide.typ` and `theme/title.typ` own the main slide layouts
- `theme/images.typ` owns image placement helpers such as `#imgs(...)`
- validate with `typst compile --root . <deck>.typ /tmp/out.pdf`
- under that compile flow, prefer root-relative imports such as `/lemonade.typ` and `/theme/...`

## Deck Conventions

- let level-1 `=` sections drive the outline
- do not hand-design a separate outline slide unless the theme requires it
- no need to wrap normal slide content in `#slide[...]`
- keep a stable example-deck scaffold: theme import, optional `#set text(lang: ...)`, local asset helpers if needed, then `#show: lemonade-theme.with(...)`
- keep the default text size; if a slide is too dense, split it into more pages
- on figure-heavy slides, leave a little slack instead of filling every remaining line; stopping roughly one sentence early usually produces a clearer page
- on figure-heavy slides, avoid mixing boxed takeaways with loose body paragraphs; prefer one or two short boxes before the figure
- use concise short boxed takeaways as the density target for figure-led slides: ideally one short line per box, rarely more than two
- do not assume a slide is safe just because it is a "summary" or "overview" page; if a table leaves the figure at icon size, the slide still failed
- prefer a few reusable slide archetypes; for architecture or method-overview pages, the default should be a short-boxes-plus-figure layout
- prefer vertical layouts; use wide or fat layouts only when a figure or table truly needs them
- in wide or fat layouts, lower the text budget before lowering the figure size
- for figure-led fat slides, a good default is one short takeaway box plus only a small amount of supporting text; if the figure becomes hard to read, split the slide
- use tables for comparisons, schedules, and other regular structures
- treat concise, boxed, evidence-led Chinese slide writing as the preferred benchmark in this repo

## Figures

- use `#imgs(...)`
- prefer theme-level image defaults such as `imgs-fill-height` rather than repeating the same per-slide option
- captions render automatically when provided
- figure readability outranks text completeness on the same slide
- on horizontal or side-by-side figure slides, keep the theme's default text size by default; shorten wording before introducing local text-size overrides
- slide text and caption serve different roles:
  - slide text states the higher-level takeaway
  - caption identifies the figure
- avoid title-plus-image-only slides
- if the same image-layout problem appears on multiple slides, inspect `theme/images.typ` and fix the helper instead of swapping helpers page by page
- if a side-by-side slide does not wrap text correctly, the image placement may be escaping its column; use a plain in-cell image block instead of a helper that bleeds across the layout
- if a table and a figure compete for the same slide, verify the figure remains legible in screenshots; otherwise replace the table with short boxes or split the slide
- if a figure is still small after using a fat layout, the slide is overstuffed; crop, split, or dedicate another slide instead of accepting a tiny figure
- inspect screenshots after major figure edits; if a figure is still too small, crop, split, or change layout

## Theme Behavior

- keep color overrides local to the current example or deck unless the user asks to change the theme globally
- if a long `name@institution` footer breaks, fix the theme behavior rather than truncating the deck content
- when Typst or Touying behavior is unclear, inspect local package sources under `~/Library/Caches/typst/packages/preview/` and then check the official docs or forum
