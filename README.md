# Lemonade Slides

Typst slide theme plus Codex skills for turning papers into presentation decks.

This repo is set up to be driven from Codex, not only edited by hand. The main user path is:

1. Ask Codex to use `$academic-paper-to-slides` on a paper PDF.
2. Let it build source notes, asset registry, brief, slide plan, figures, and deck under `out/<paper>/`.
3. Revise the generated deck or the shared theme in place.
4. Validate with the local compile script before you stop.

## What Lives Here

- `lemonade.typ`: stable theme entrypoint that re-exports `theme/lemonade.typ`
- `theme/`: shared theme modules for layout, outline, boxes, code, images, footer, and tables
- `assets/`: shared figures (PKU/THU/NSFC logos, QR codes) exported as path values from `theme/assets.typ` — see `assets/README.md`
- `.codex/skills/academic-paper-to-slides/`: paper-to-deck workflow and writing guidance
- `.codex/skills/figure-extraction/`: figure recovery workflow for PDFs and slide decks
- `out/<paper>/`: one workspace per generated deck
- `examples/`: checked-in sample decks and references

## Quick Start With Codex

Create a new paper-reading deck:

```text
$academic-paper-to-slides @paper.pdf
```

Ask for a Chinese reading-report deck:

```text
$academic-paper-to-slides @paper.pdf
Make the slides Chinese and use a seminar / reading-report style.
```

Revise an existing deck:

```text
Revise examples/tokencake/tokencake.typ.
Tighten the boxes, keep captions to one line when possible, and revalidate.
```

Change the shared theme:

```text
Update the theme so outline slides use mono text and validate tokencake again.
```

Extract figures without building a deck:

```text
$figure-extraction @paper.pdf
Recover the best asset for Figure 4 and save it under out/<paper>/assets/.
```

The local figure helper is PyMuPDF-based. For direct CLI use, install `pymupdf` in the Python environment that runs `.codex/skills/figure-extraction/scripts/extract_pdf_figures.py`.

## Expected Output Layout

The paper-to-slides skill keeps each paper self-contained:

- `out/<paper>/<paper>.typ`
- `out/<paper>/notes/source.txt`
- `out/<paper>/notes/assets.json`
- `out/<paper>/notes/brief.json`
- `out/<paper>/notes/slides.json`
- `out/<paper>/notes/review.json`
- `out/<paper>/notes/asset-manifest.md`
- `out/<paper>/notes/brief.md`
- `out/<paper>/notes/slide-map.md`
- `out/<paper>/assets/...`

The JSON files are canonical. The Markdown notes are derived inspection artifacts rendered from that JSON so the planning state stays machine-checkable.

This keeps crops, extracted figures, and deck notes out of shared top-level folders.

## Artifact Helpers

Initialize a paper workspace and JSON artifacts:

```bash
python3 .codex/skills/academic-paper-to-slides/scripts/paper_artifacts.py \
  init-workspace paper.pdf --workspace out/<paper>
```

Extract source text into `notes/source.txt`:

```bash
python3 .codex/skills/academic-paper-to-slides/scripts/paper_artifacts.py \
  extract-source paper.pdf --workspace out/<paper>
```

Re-render the human-readable notes after editing `assets.json`, `brief.json`, or `slides.json`:

```bash
python3 .codex/skills/academic-paper-to-slides/scripts/paper_artifacts.py \
  render-notes --workspace out/<paper>
```

Emit a deterministic Typst scaffold from `notes/slides.json`:

```bash
python3 .codex/skills/academic-paper-to-slides/scripts/paper_artifacts.py \
  emit-deck --workspace out/<paper>
```

Disable escape fragments and force scripted layouts for all slides:

```bash
python3 .codex/skills/academic-paper-to-slides/scripts/paper_artifacts.py \
  emit-deck --workspace out/<paper> --disable-escape
```

The emitter is archetype-aware rather than fully generic. The canonical archetype contract now lives in [`.codex/skills/academic-paper-to-slides/references/archetypes.json`](./.codex/skills/academic-paper-to-slides/references/archetypes.json). The human-facing [`archetypes.md`](./.codex/skills/academic-paper-to-slides/references/archetypes.md) is derived from that JSON spec.

Slides can carry:

- `archetype`, `asset_ids`, and `equation_ids`
- richer layout fields such as `boxes`, `bullets`, `table`, `cards`, and `equation`
- `render_mode: "script" | "escape"`
- short `escape_hint` instructions when `render_mode` is `escape`

For escape slides, collect the exact payload the main Codex context should render into a fragment:

```bash
python3 .codex/skills/academic-paper-to-slides/scripts/paper_artifacts.py \
  collect-escape-context --workspace out/<paper>
```

Write the fragment to `out/<paper>/fragments/<slide_id>.typ`, then run `emit-deck`. The script only consumes fragment artifacts; it does not make its own model call.

Regenerate the derived archetype reference:

```bash
python3 .codex/skills/academic-paper-to-slides/scripts/paper_artifacts.py \
  render-archetypes-ref
```

## Validate A Deck

Compile a deck directly:

```bash
typst compile --root . out/<paper>/<paper>.typ /tmp/out.pdf
```

Use the repo helper when you want a validation PDF in a stable temp location:

```bash
bash .codex/skills/academic-paper-to-slides/scripts/validate_deck.sh \
  out/<paper>/<paper>.typ
```

The validation helper writes the PDF under `/tmp/academic-paper-to-slides/` by default, validates JSON artifacts when a paper workspace exists, renders page previews, and writes review findings to `notes/review.json` or `review/review.json`.

When `slides.json` is present, the rendered-page review accounts for Lemonade outline pages inserted by `=` section headings. Expected rendered page count can therefore be larger than planned slide count.

If a deck compile fails and the workspace contains escape-mode slides, the validation helper retries once by re-emitting the deck with `--disable-escape`. The rendered review records that fallback in `review.json`.

## Theme Conventions Codex Follows

- Import the theme from `/lemonade.typ`.
- Use `#show: lemonade-theme.with(...)` once near the top of the deck.
- Let top-level `=` headings drive outline sections.
- Use `#img(...)` for figures, laid out by `#vboxs(...)`, instead of deck-local wrappers.
- Put repeated defaults in `img-config` (one figure's look) or `vboxs-config` (the row), not in per-slide overrides.
- Keep one generated paper per `out/<paper>/` workspace.

## Minimal Manual Deck Scaffold

```typst
#import "/lemonade.typ": *

#set text(lang: "en")

#show: lemonade-theme.with(
  aspect-ratio: "16-9",
  title-align: "left",
  // "bar": full footer with primary fill; "plain": full footer without fill.
  footer: "bar",
  img-config: (
    cap-size: 18pt,
    cap-weight: "bold",
  ),
  title: [Paper Title],
  venue: [MICRO 2025],
  author: [Author et al.],
  institution: [Institution Name],
)

#title-slide()

= Motivation

== One Slide, One Claim

#ibox[
  *Claim:* state the takeaway directly.
]

#vboxs(
  img(image("assets/figure.png"), [Short caption]),
  width: 80%,
)
```

A figure is a `vboxs` row item, the same as a box or a `#code` listing, so one
call covers every arrangement: `#vboxs(img(a), img(b))` for two at one height,
`dir: ttb` to stack them, and `#vboxs(ibox[...], img(a))` for a figure beside a
box. A bare `#img(...)` renders on its own at its natural size.

A row reveals itself with `step:`, not with `#pause` inside it:

```typst
#vboxs(
  vbox([Phase 1])[...], vbox([Phase 2])[...], vbox([Phase 3])[...],
  after: hbox[Only then, the conclusion.],
  step: true,          // one item per subslide; `after` lands one past the last
)
```

`step: 2` starts the same sequence on subslide 2, and `step: (1, 1, 2)` gives an
index per item — the first two together, then the third. Indices are absolute
subslide numbers and a row spends none of its own, so a `#pause` before the row
means `step: 2`, and a `#pause` after it keeps counting the pauses alone. Items
reveal in the order written, even in an `rtl` row, and an item still on its way
is covered rather than dropped, so nothing in the row moves between subslides.

## VS Code Workspace Defaults

The repo ships shared VS Code workspace settings in `.vscode/`:

- recommends the Tinymist extension
- formats Typst with Tinymist / Typstyle on save
- runs Tinymist lint on save
- stores pasted or dragged images under `assets/` next to the current deck file

For local edits, use relative paths such as `image("assets/figure.png")`. The shared `#img(...)` helper accepts preloaded `image(...)` content so the file still resolves relative to the deck file instead of the theme package.

See [`examples/images/images.typ`](examples/images/images.typ) for the compilable image API reference and layout examples.

## Code Snippets

Write snippets as ordinary Typst raw fences inside `#code[...]` — never as
`#raw("line\nline", block: true)`. Markup may sit beside the listing.

````typst
#code(focus: (2, 3), mark: ("@ t",))[
  ```python
  @tm.func
  def axpy[t: Time](x: Tile @ t, y: Tile @ t) -> Tile @ (t + 1):
      return tm.fma(alpha, x, y)
  ```
  Both operands must arrive at the same logical time.
]
````

- `hl: (2, 3)` bands those 1-based lines; `focus:` also mutes every other line;
  `dim:` mutes only the lines given. `range(2, 5)` works as the argument.
- Line numbers are on by default, zero-padded to two digits, so the lines `hl:`
  and `focus:` name are ones the audience can see. `numbers: false` drops the
  gutter for one listing; `code-config.numbers` is the deck-wide default, and
  `number-digits` / `number-gap` / `number-tint` size and shade it. A listing of
  more than 99 lines widens its own gutter.
- A long line wraps with its continuation hanging under its own first code
  column, and the highlight band covers every row of it.
  `code-config.wrap-indent` pushes continuations deeper still. A single token
  wider than the frame has no break opportunity and overflows visibly — shorten
  it, or reach for `indent:` and then `scale:`.
- A listing is as wide as the text column. The gap to its right is the slide's
  `layout-config.margins.right` (base.typ), which moves prose and tables with
  it; `code-config.inset` is the code-local part and the one to reach for first.
- A listing taller than its slide splits and continues on the next page rather
  than disappearing (`code-config.breakable`, and the breakable box figures in
  `apply-box-style`). Treat a split listing as a sign to cut lines or `scale:`
  it — the overflow is shown so it can be fixed, not because it reads well.
- `mark: ("@ t",)` accents a token wherever it appears, on top of the
  highlighting rather than instead of it, and outranks whatever the highlighter
  made of it — a marked token inside a comment or a string is still marked. Pass
  a `regex` for a pattern.
- A mark has to fall inside one piece of what the highlighter cut the line into.
  A spec only cuts out what its own rules describe, so most marks land — `@ t`
  and `tm.load` are untouched plain text as far as `python-lang` is concerned.
  One that crosses a boundary, like `while q < Q` over the `while` keyword,
  silently does not match: mark `q < Q` instead, or put `lang: none` on that
  listing to drop highlighting and mark everything.
- Syntect cuts at every token, so a listing it highlights turns highlighting off
  as soon as it has a mark — a mark that quietly fails to show is worse than a
  listing without color.
- `caption: [Label]` labels a listing under its frame, in the same style and on
  the same reserved band as an `#img` caption — so listings and figures side by
  side in one row all end on the same line, however long a caption runs.
- `frame: false` drops the surface for listings already inside a box helper;
  `scale: 80%` shrinks one so two fit side by side.
- In a row, a listing's frame fills the height the row hands it, which is what
  keeps side-by-side frames matching. `stretch: false` draws the frame at its
  natural height instead, while the cell keeps the row's — the captions stay
  aligned either way.
- `indent: 2` re-indents the snippet from its own indent unit (the smallest
  non-zero indent in the source) down to two spaces per level. Slides are short
  on width, so this is usually what buys a listing a larger font — reach for it
  before `scale:`.
- The surface and the token styling both come from a palette dict —
  `light-code-palette` / `dark-code-palette` in `theme/code.typ`, picked per
  mode through `code-config.palettes`. The default uses restrained semantic
  colors for comments, keywords, decorators, names, strings, numbers, and
  other syntax while preserving each mode's surface. Pass `theme:` your own
  palette dict for one listing, or `theme: none` for a single flat ink.
- `font:` sets the listing font, defaulting to `code-config.font`. It is a
  separate knob from `font-config.mono`, which dresses footers, outlines,
  tables, and inline `raw` in prose.

### Languages

Two highlighters, picked per listing. A fence whose tag is registered in
`code-config.langs` is highlighted by rules this theme owns; anything else goes
to syntect, whose spans are repainted into the same palette buckets. Python
ships as a spec (`python-lang` in `theme/code.typ`); `lang: none` hands one
listing back to syntect, and `lang:` a name or a spec forces the other way.

A spec is an ordered list of `(bucket, pattern)` rules — declare one at the top
of a deck and register it under the fence tag it answers to:

```typst
#let tdsl = code-lang(
  ("comment", "#.*"),
  ("name", "\\bkernel\\s+([A-Za-z_][A-Za-z0-9_]*)"),
  ("keyword", ("kernel", "tile", "at", "yield")),
  ("number", "\\b[0-9]+\\b"),
)

#show: lemonade-theme.with(code-langs: (tdsl: tdsl), ..)
```

- `bucket` is a palette `syntax` row, so a spec and a syntect listing wear the
  same theme. `pattern` is a regex **source string** or an array of literal
  words — never a `regex` value, which cannot be spliced into the combined
  pattern the spec compiles to.
- Rules are tried in order and the first match wins, which is what keeps a
  keyword inside a comment or a string quiet. Typst's regex engine has no
  look-around; capture instead, as the `name` rule above does — the capture
  takes the bucket and the `kernel` around it goes back through the rules.
- `code-langs: (python: none)` hands Python back to syntect deck-wide.

For a full language rather than a slide-sized one, syntect will load a real
grammar: `#set raw(syntaxes: read("x.sublime-syntax", encoding: none))` at the
top of a deck reaches inside `#code` as well.

A listing has no title bar: label it with `caption:`, or with a box helper
around it when the box's own accent carries meaning. A bare `#code` is a `vboxs`
row item, so two listings can be the columns of one equal-height row:

```typst
#vboxs(
  code(caption: [Row-major], indent: 2)[...],
  code(caption: [Blocked], indent: 2)[...],
  after: hbox[Same recurrence, two loop structures.],
)
```

See [`examples/code/code.typ`](examples/code/code.typ).

## Where To Edit

- Generated deck content: `out/<paper>/<paper>.typ`
- Checked-in sample decks: `examples/<paper>/<paper>.typ`
- Shared theme behavior: `theme/*.typ`
- Paper-to-deck workflow: `.codex/skills/academic-paper-to-slides/`
- Figure recovery workflow: `.codex/skills/figure-extraction/`

## Live Example

- [examples/tokencake/tokencake.typ](examples/tokencake/tokencake.typ)
