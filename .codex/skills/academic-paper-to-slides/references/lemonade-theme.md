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
- keep a stable scaffold: theme import, optional `#set text(lang: ...)`, local helpers if needed, then `#show: lemonade-theme.with(...)`
- keep the default text size; if a slide is too dense, split it into more pages
- use `#imgs(...)` as the default for normal image rows, single figures, multi-panel figure blocks, and captioned evidence
- captions render automatically whenever an image item provides one
- prefer theme-level image defaults via `imgs-config: (...)` instead of repeating the same option on every slide
- the theme overrides Touying's default presentation paper size to match standard PowerPoint canvases (`13.333in x 7.5in` for `16:9`, `10in x 7.5in` for `4:3`)
- do not add deck-local wrappers such as `figcell` for ordinary figure layout unless you first confirmed that `theme/images.typ` cannot express the needed behavior
- if a side-by-side slide does not wrap text correctly, the image helper may be escaping its column; use a plain in-cell image block instead of shrinking text
- if a side-column figure is short, first look for another recovered asset or sub-asset that can share the column; then prefer a tall crop or a vertically stacked evidence column built from one or two `#imgs(...)` blocks instead of leaving dead whitespace
- if the same image-layout problem appears across multiple slides, inspect `theme/images.typ` and fix the helper instead of swapping helpers page by page
- if a multi-panel source figure turns into a tiny center thumbnail, crop or split the evidence before abandoning `#imgs(...)`
- keep color overrides local to the current example or deck unless the user asks to change the theme globally

## Read Next

- for composition choice, read `references/archetypes.md`
- for figure cleanup and repeatable crops, read `references/figure-prep.md`
- for language style, read `references/chinese-academic-style.md` or `references/english-academic-style.md`
- for final acceptance, read `references/visual-qa.md`

## Theme Behavior

- if a long `name@institution` footer breaks, fix the theme behavior rather than truncating the deck content
- when Typst or Touying behavior is unclear, inspect local package sources under `~/Library/Caches/typst/packages/preview/` and then check the official docs or forum
