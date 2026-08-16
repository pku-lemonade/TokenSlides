# Lemonade Theme Notes

This skill is tailored to the local `lemonade.typ` slide theme.

## Entry Points

- `lemonade.typ` re-exports `theme/lemonade.typ`
- `theme/base.typ` controls global sizes, spacing, colors, and runtime state
- `theme/slide.typ` and `theme/title.typ` own the main slide layouts
- `theme/images.typ` owns the figure item `#img(...)` and the floating `#place-xx` helpers
- `theme/assets.typ` exports common figure paths (`pku-logo`, `thu-logo`, `nsfc-logo`, `lemonade-qr`); place them with `#place-logo(pku-logo)` top-right or `#place-qr()` bottom-right (typical on the thank-you slide)
- validate with `typst compile --root . <deck>.typ /tmp/out.pdf`
- under that compile flow, prefer root-relative imports such as `/lemonade.typ` and `/theme/...`

## Deck Conventions

- let level-1 `=` sections drive the outline
- do not hand-design a separate outline slide unless the theme requires it
- no need to wrap normal slide content in `#slide[...]`
- keep a stable scaffold: theme import, optional `#set text(lang: ...)`, local helpers if needed, then `#show: lemonade-theme.with(...)`
- keep the default text size; if a slide is too dense, split it into more pages
- a figure is `#img(source)` or `#img(source, [caption])`, and it is a `vboxs` row item like a box or a `#code` listing — there is no separate image-layout call
- use `#vboxs(img(...), ...)` as the default for normal image rows, single figures, multi-panel figure blocks, and captioned evidence; a bare `#img(...)` renders at natural size, while a row can fill the slide (`fill-height`), stack (`dir: ttb`), bleed, or carry an `after:` conclusion
- a row measures every caption in it and reserves one band for the tallest, so figures with captions of different lengths still end on the same line
- mix freely: `#vboxs(ibox[...], img(fig))` puts a figure beside a box at one height
- prefer theme-level defaults instead of repeating an option on every slide — `img-config: (...)` for one figure's look (caption typography, frame, fit), `vboxs-config: (...)` for the row (gaps, `fill-height`)
- `img(height:)` is a fixed length; to fill a container use `fill-height` on the row, never a ratio height (it is rejected)
- the theme overrides Touying's default presentation paper size to match standard PowerPoint canvases (`13.333in x 7.5in` for `16:9`, `10in x 7.5in` for `4:3`)
- do not add deck-local wrappers such as `figcell` for ordinary figure layout unless you first confirmed that `theme/images.typ` cannot express the needed behavior
- if a side-by-side slide does not wrap text correctly, the image helper may be escaping its column; use a plain in-cell image block instead of shrinking text
- if a side-column figure is short, first look for another recovered asset or sub-asset that can share the column; then prefer a tall crop or a vertically stacked evidence column built from one `#vboxs(..., dir: ttb)` stack instead of leaving dead whitespace
- if a figure-led or comparison slide still needs short follow-on support, keep it inside the box system instead of leaving loose bullets around the figure row
- if the same image-layout problem appears across multiple slides, inspect `theme/images.typ` and fix the helper instead of swapping helpers page by page
- if a multi-panel source figure turns into a tiny center thumbnail, crop or split the evidence before abandoning the figure row
- keep color overrides local to the current example or deck unless the user asks to change the theme globally

## Code Snippets

- use `#code[...]` from `theme/code.typ` with an ordinary raw fence inside it;
  never emit `#raw("line\nline", block: true, lang: ...)` — an escaped
  one-line string is unreadable and uneditable in the deck source
- `#code` is titleless; label a listing with the box helper around it
  (`#ebox[...]`) plus a `#tbox(size: 20pt)[Label]`, not with a title bar
- for a listing inside a box, pass `frame: false` so the surface is not drawn
  twice
- pass `indent: 2` on every slide listing: slides are short on width, and
  re-indenting from the source's own indent unit keeps the full code font where
  4-space source would have forced a smaller one
- reach for `scale:` only after `indent: 2` still overflows the column, and use
  the same value on both listings of a comparison
- when two listings need no labels, drop them straight into `#vboxs(...)` — a
  bare `#code` is a row item, so `#vboxs(code(indent: 2)[...],
  code(indent: 2)[...], after: hbox[...])` compares them at equal height
- keep the default `fill-height: true` on a row of listings; a short listing
  leaves space inside its panel, which still reads better than
  `fill-height: false` pushing the whole row into the top half of the slide
- to point at part of a snippet, use `hl:` / `focus:` (1-based line numbers) or
  `mark:` (tokens), not a separate annotation slide
- full API and rendered reference: `examples/code/code.typ`

## Read Next

- for composition choice, read `references/archetypes.md`
- for figure cleanup and repeatable crops, read `references/figure-prep.md`
- for language style, read `references/chinese-academic-style.md` or `references/english-academic-style.md`
- for final acceptance, read `references/visual-qa.md`

## Theme Behavior

- if a long `name@institution` footer breaks, fix the theme behavior rather than truncating the deck content
- when Typst or Touying behavior is unclear, inspect local package sources under `~/Library/Caches/typst/packages/preview/` and then check the official docs or forum
