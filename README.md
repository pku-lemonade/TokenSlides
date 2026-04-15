# Lemonade Slides

Typst slide theme plus Codex skills for turning papers into presentation decks.

This repo is set up to be driven from Codex, not only edited by hand. The main user path is:

1. Ask Codex to use `$academic-paper-to-slides` on a paper PDF.
2. Let it build a paper brief, slide map, figures, and deck under `examples/<paper>/`.
3. Revise the generated deck or the shared theme in place.
4. Validate with the local compile script before you stop.

## What Lives Here

- `lemonade.typ`: stable theme entrypoint that re-exports `theme/lemonade.typ`
- `theme/`: shared theme modules for layout, outline, boxes, images, footer, and tables
- `.codex/skills/academic-paper-to-slides/`: paper-to-deck workflow and writing guidance
- `.codex/skills/figure-extraction/`: figure recovery workflow for PDFs and slide decks
- `examples/<paper>/`: one workspace per generated deck

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
Recover the best asset for Figure 4 and save it under examples/<paper>/assets/.
```

## Expected Output Layout

The paper-to-slides skill keeps each paper self-contained:

- `examples/<paper>/<paper>.typ`
- `examples/<paper>/notes/brief.md`
- `examples/<paper>/notes/slide-map.md`
- `examples/<paper>/assets/...`

This keeps crops, extracted figures, and deck notes out of shared top-level folders.

## Validate A Deck

Compile a deck directly:

```bash
typst compile --root . examples/<paper>/<paper>.typ /tmp/out.pdf
```

Use the repo helper when you also want preview images:

```bash
bash .codex/skills/academic-paper-to-slides/scripts/validate_deck.sh \
  examples/<paper>/<paper>.typ
```

The validation helper writes the PDF and page previews under `/tmp/academic-paper-to-slides/` by default.

## Theme Conventions Codex Follows

- Import the theme from `/lemonade.typ`.
- Use `#show: lemonade-theme.with(...)` once near the top of the deck.
- Let top-level `=` headings drive outline sections.
- Use `#imgs(...)` for normal figure blocks instead of deck-local wrappers.
- Put repeated image defaults in `imgs-config`, not in per-slide overrides.
- Keep one paper per `examples/<paper>/` workspace.

## Minimal Manual Deck Scaffold

```typst
#import "/lemonade.typ": *

#set text(lang: "en")

#show: lemonade-theme.with(
  aspect-ratio: "16-9",
  title-align: "left",
  footer: "bar",
  imgs-config: (
    fill-height: true,
    cap-size: 18pt,
    cap-weight: "bold",
  ),
  config-info(
    title: [Paper Title],
    subtitle: [Subtitle],
    author: [Author et al.],
    institution: [Venue / Year],
  ),
)

#title-slide()

= Motivation

== One Slide, One Claim

#ibox[
  *Claim:* state the takeaway directly.
]

#imgs(
  ("/examples/paper/assets/figure.png", [Short caption]),
  width: 80%,
)
```

## Where To Edit

- Deck-specific content: `examples/<paper>/<paper>.typ`
- Shared theme behavior: `theme/*.typ`
- Paper-to-deck workflow: `.codex/skills/academic-paper-to-slides/`
- Figure recovery workflow: `.codex/skills/figure-extraction/`

## Live Example

- [examples/tokencake/tokencake.typ](examples/tokencake/tokencake.typ)
