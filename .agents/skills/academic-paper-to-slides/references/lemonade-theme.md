# Lemonade Theme Notes

This skill is tailored to the local `lemonade.typ` slide theme.

## Entry Points

- `lemonade.typ` re-exports `theme/lemonade.typ`
- `theme/base.typ` controls global sizes, spacing, colors, and runtime state
- `theme/slide.typ` and `theme/title.typ` own the main slide layouts
- `theme/arrows.typ` owns `#solid-arrow(...)` for short filled process arrows and `connector-arrow(...)` for CeTZ relationship-edge styling
- `theme/images.typ` owns the figure item `#img(...)` and the floating `#place-xx` helpers
- `theme/assets.typ` exports common figure paths (`pku-logo`, `thu-logo`, `nsfc-logo`, `lemonade-qr`); place them with `#place-logo(pku-logo)` top-right or `#place-qr()` bottom-right (typical on the thank-you slide)
- validate with `typst compile --root . <deck>.typ /tmp/out.pdf`
- under that compile flow, prefer root-relative imports such as `/lemonade.typ` and `/theme/...`

## Deck Conventions

- let level-1 `=` sections drive the outline
- do not hand-design a separate outline slide unless the theme requires it
- no need to wrap normal slide content in `#slide[...]`
- keep a stable scaffold: theme import, optional `#set text(lang: ...)`, local helpers if needed, then `#show: lemonade-theme.with(...)`
- emit theme defaults, not overrides — see `Style Overrides` below before passing any style argument
- use `#solid-arrow()` only as a short standalone process symbol between adjacent stages, aligned and sized to the neighboring shapes and their actual gap; its defaults are a starting point, so scale it when the local geometry requires while preserving the standard silhouette. For an anchored CeTZ relationship, spread `connector-arrow(color)` into `line` or `bezier`, clip the line from the source boundary to the target boundary, and scale stroke/head together for the local canvas and final slide visibility
- a figure is `#img(source)` or `#img(source, [caption])`, and it is a `vboxs` row item like a box or a `#code` listing — there is no separate image-layout call
- use `#vboxs(img(...), ...)` as the default for normal image rows, single figures, multi-panel figure blocks, and captioned evidence; a bare `#img(...)` renders at natural size, while a row can fill the slide (`fill-height`), stack (`dir: ttb`), bleed, or carry an `after:` conclusion
- a row measures every item caption in it and reserves one band for the tallest, so images, code listings, and foreign row items with captions of different lengths still end on the same line
- mix freely: `#vboxs(ibox[...], img(fig))` puts a figure beside a box at one height
- a cell takes only row items, so a second row goes in one through `#vstack(...)` — a stacking-only item that draws nothing itself: `#vboxs(code(...), vstack(img(a, [A]), img(b, [B]), fill-height: true))`. `dir` belongs to the nested row (so a `dir: ttb` outer row can hold a side-by-side cell), stacks nest, and its `after:` is the only way to put plain content such as a callout inside one column — turn that callout's `bleed` off there. reveal timing stays with the outer row (one `step` index covers a whole stack; `step:`/`bleed:` on the stack are rejected). a stack divides its cell in proportion to what each item measures, so a short figure above a tall one is not blown up to match it; `heights: (2fr, 1fr)` names the proportions instead (and `(1fr, 1fr)` asks for an even split). The default `fill-height: false` keeps boxes and prose at natural height; pass `fill-height: true` for figures that need to scale into the cell
- reveal a row progressively with `step:` on the `vboxs` (`step: true`, a starting subslide, or one index per item); `#pause` inside a row is rejected, and a stepped row spends no subslides of its own, so count absolute subslide numbers when a `#pause` shares the slide
- `img(height:)` is a fixed length; to fill a container use `fill-height` on the row, never a ratio height (it is rejected)
- the theme overrides Touying's default presentation paper size to match standard PowerPoint canvases (`13.333in x 7.5in` for `16:9`, `10in x 7.5in` for `4:3`)
- do not add deck-local wrappers such as `figcell` for ordinary figure layout unless you first confirmed that `theme/images.typ` cannot express the needed behavior
- if a side-by-side slide does not wrap text correctly, the image helper may be escaping its column; use a plain in-cell image block instead of shrinking text
- if a side-column figure is short, first look for another recovered asset or sub-asset that can share the column; then prefer a tall crop or a vertically stacked evidence column — `#vstack(...)` inside the column when the rest of the row stays as it is, or a whole-row `#vboxs(..., dir: ttb)` — instead of leaving dead whitespace
- if a figure-led or comparison slide still needs short follow-on support, keep it inside the box system instead of leaving loose bullets around the figure row
- if the same image-layout problem appears across multiple slides, inspect `theme/images.typ` and fix the helper instead of swapping helpers page by page
- if a multi-panel source figure turns into a tiny center thumbnail, crop or split the evidence before abandoning the figure row
- keep color overrides local to the current example or deck unless the user asks to change the theme globally

## Style Overrides

`AGENTS.md` → `Deck style overrides` is the contract; this is how it applies while emitting slides. A drafted deck is judged on its content, and a style argument that no rendered page demanded is a defect, not thoroughness — it buries the one or two overrides that do carry meaning.

- write the plain call first: `#vboxs(img(a), img(b))`, `#vboxs(ibox[...], img(fig))`, `#code(indent: 2)[...]`. Add a style argument only after seeing the compiled page go wrong, and then only the one that fixes it
- on `vboxs` rows, do not pass `gap`, `after-gap`, `fill-height`, `fill-pad`, `width: 100%`, or `widths: auto` — those are the defaults already. This does not apply to the explicit `vstack(..., fill-height: true)` figure case above
- `widths` is for deliberately unequal tracks (`(2fr, 1fr)`, `(0.6fr, 0.4fr)`). Never emit a near-equal split such as `(0.48fr, 0.52fr)` or `(0.96fr, 1.04fr)`; it looks measured, means nothing, and renders like `1fr, 1fr`
- never emit a text size: no `#set text(size:)`, no `#text(size:)`, no `title-size` / `text-size` / `body-size`. A slide that does not fit gets fewer words or becomes two slides — that decision belongs in `notes/slides.json`, not in a font size
- `scale:` on a listing comes after `indent: 2`; box `inset` / `compact` / `body-inset` come after shortening the body. `body-inset: (right: 0pt)` for a framed listing at a box edge stays routine
- if the same argument would repeat on three or more slides, it is a theme/module default: change the owning `vboxs-config`, `img-config`, `code-config`, or `arrow-config` instead of repeating it in deck calls
- deck-local `cetz` canvas numbers are content, not overrides — this section does not restrict them

## Code Snippets

- use `#code[...]` from `theme/code.typ` with an ordinary raw fence inside it;
  never emit `#raw("line\nline", block: true, lang: ...)` — an escaped
  one-line string is unreadable and uneditable in the deck source
- label a listing with `#code(caption: [Label], ...)[...]`; its caption uses
  the same shared foot band as `img`, so side-by-side frames and captions align
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
