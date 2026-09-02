# Lemonade Slides

A Typst slide theme built on [Touying](https://typst.app/universe/package/touying), plus agent skills that turn a paper PDF into a deck, recover figures, and export to PowerPoint. Used for paper readings, seminar reports and lectures at PKU; every style knob sits at the top of the module that owns it.

## Requirements

- [Typst](https://typst.app) 0.14 (tested with 0.14.2). Compile from the repository root with `--root .`.
- Fonts: Inter and Inconsolata for Latin text, Source Han Sans SC for Chinese. Arial is the body fallback.
- For the skills: Python 3 with `pymupdf` (figure extraction) and `python-pptx` plus `pandoc` (editable PowerPoint export).

## Quick start

```typst
#import "/lemonade.typ": *

#show: lemonade-theme.with(
  title: [Paper Title],
  venue: [MICRO 2025],
  author: [Author et al.],
  institution: [Institution Name],
)

#title-slide()

= Motivation

== One Slide, One Claim

#ibox[*Claim:* state the takeaway directly.]

#vboxs(
  img("/examples/paper-reading/graph-hls/assets/fig1-workflow.pdf", [Short caption]),
  width: 80%,
)
```

```bash
typst compile --root . my-deck.typ /tmp/my-deck.pdf
scripts/check.sh   # compiles every reference and example deck
```

The fastest way to a real deck is to copy an example below. How the theme is used in a deck file, from rows and figures to code listings, is in [`docs/theme.md`](docs/theme.md).

## Skills

Agent skills under [`.agents/skills/`](.agents/skills/) (`.codex/skills` is a symlink to it), invoked from Codex as `$<skill>`:

| Skill | What it does | Use it when |
| --- | --- | --- |
| [`academic-paper-to-slides`](.agents/skills/academic-paper-to-slides/SKILL.md) | Builds a Lemonade deck from a paper PDF: source notes, figure registry, brief, slide plan, deck under `out/<paper>/`. | Starting a new deck or rebuilding one from its source. Not for routine edits. |
| [`figure-extraction`](.agents/skills/figure-extraction/SKILL.md) | Recovers raster, vector or composite figures from PDFs and decks with a PyMuPDF helper. | A figure is needed as a standalone asset. |
| [`figure-generation`](.agents/skills/figure-generation/SKILL.md) | Creates source-grounded generated figures for a deck through an image model. | A diagram the paper does not provide, or a replacement for a poor crop. |
| [`convert-pdf-to-pptx`](.agents/skills/convert-pdf-to-pptx/SKILL.md) | Flattens a compiled deck into a `.pptx` with one full-slide image per page. | Fidelity and reliable playback matter more than editability. |
| [`convert-typst-to-editable-pptx`](.agents/skills/convert-typst-to-editable-pptx/SKILL.md) | Rebuilds a deck as native, editable PowerPoint objects. | Someone has to edit the slides in PowerPoint. |

Typical prompts:

```text
$academic-paper-to-slides @paper.pdf
$academic-paper-to-slides @paper.pdf  Make the slides Chinese and use a seminar / reading-report style.
$figure-extraction @paper.pdf  Recover the best asset for Figure 4 and save it under out/<paper>/assets/.
Revise examples/paper-reading/graph-hls/graph-hls.typ. Tighten the boxes and revalidate.
```

The paper-to-slides skill keeps each paper in `out/<paper>/` with its notes and assets; the artifact layout, helper commands and validation steps are in [`docs/workflow.md`](docs/workflow.md).

## Examples

Complete decks to copy from, grouped by genre. Each deck has its own folder, `examples/<genre>/<deck>/<deck>.typ` with figures under `assets/`, the same shape as a generated `out/<paper>/`. Only sources and assets are tracked, so notes and previews in a deck folder stay local.

**Paper reading** (a conference paper in 10 to 15 slides)
- [`paper-reading/graph-hls`](examples/paper-reading/graph-hls/graph-hls.typ): English, 16:9, ACM artifact badges, figures beside box rows, a results table.

**Seminar report**
- [`seminar/research`](examples/seminar/research/research.typ): Chinese, dark mode, filled boxes, QR code on the closing slide.

**Lecture**
- [`lecture/algebraic-graph-theory`](examples/lecture/algebraic-graph-theory/algebraic-graph-theory.typ): 4:3, sections with an outline, speaker notes, stepped reveals, math.

## Theme reference

One compilable deck per module under [`docs/`](docs/); every public theme name appears in at least one of them (`scripts/check.sh --coverage`).

| Deck | Covers |
| --- | --- |
| [`boxes.typ`](docs/boxes.typ) | Box families, `vboxs` rows, `vstack`, stepped reveals, per-box options |
| [`tables.typ`](docs/tables.typ) | `vtable` styles, palettes, spans, fill-height |
| [`code.typ`](docs/code.typ) | Listings, highlighting, marks, captions, custom language specs |
| [`images.typ`](docs/images.typ) | `img` rows, captions, placed logos and QR codes |
| [`arrows.typ`](docs/arrows.typ) | Process arrows and CeTZ connectors |
| [`slides.typ`](docs/slides.typ) | Title and closing slides, outline variants, sections, footer slots, badges, notes |
| [`theme.typ`](docs/theme.typ) | Dark mode, accent override, filled boxes, callouts, emphasis on fills |

Knobs live at the top of each `theme/<module>.typ` as a `<feature>-config` dictionary; `theme/base.typ` holds layout, fonts and colors.

## Repository map

- `lemonade.typ`: entry point, re-exports `theme/lemonade.typ`
- `theme/`: the theme modules
- `docs/`: reference decks and the two guides above
- `examples/`: sample decks by genre
- `assets/`: shared logos and QR codes ([`assets/README.md`](assets/README.md))
- `scripts/check.sh`: compile, render-diff and coverage checks
- `.agents/skills/`: the skills
- `out/`: generated decks, ignored by git
- [`AGENTS.md`](AGENTS.md): conventions for agents and contributors

## Editor

`.vscode/` recommends the Tinymist extension, formats Typst on save, runs its lint, and stores pasted images under `assets/` next to the deck.

## License

Apache 2.0, see [`LICENSE`](LICENSE).
