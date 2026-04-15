---
name: academic-paper-to-slides
description: Convert academic papers, preprints, and local PDF manuscripts into Typst slide decks in the local lemonade theme. Use when the user asks to draft, revise, or reorganize slides for paper readings, seminars, research overviews, proposal/midterm/final defenses, or similar academic talks.
---

# Academic Paper to Slides

Turn a paper into a presentation argument. Do not mirror the PDF page by page.

## Use This Skill To

- distill one paper or a small paper set into slides
- extract claims, figures, tables, and exact numbers from a PDF
- adapt the same source into different academic contexts such as seminar, reading report, overview, or defense

## Required Working Artifacts

Before drafting Typst slide code, build two scratch artifacts.

1. Paper brief.
   - Capture the title, problem, motivation, assumptions, main idea, method components, evaluation setting, and quantitative results.
   - Keep exact baselines, datasets, model names, metrics, and improvements.
   - Inventory the figures and tables you may reuse, plus what each asset proves.
   - Identify 3 to 6 deck-level claims. For systems or architecture papers, expand the method into multiple mechanism claims instead of collapsing the technique into 1 or 2 slides.
2. Slide map.
   - Write one line per planned slide: section, title, takeaway, evidence, archetype.
   - Each slide should defend one claim.
   - Assign real evidence before writing the page: figure, table, or exact number.

## Output Layout

For a source PDF at `<pdf-dir>/<paper>.pdf`, keep generated notes and extracted assets in paper-specific directories rather than a shared flat folder.

Preferred layout:

- `notes/<pdf-dir>/<paper>/brief.md`
- `notes/<pdf-dir>/<paper>/slide-map.md`
- `assets/<pdf-dir>/<paper>/...`

Rules:

- Mirror the PDF path relative to the repo root when possible.
- If the PDF lives at the repo root, omit the empty directory layer: `notes/<paper>/...` and `assets/<paper>/...`.
- If several PDFs live in the same source folder, each paper still gets its own `<paper>/` subdirectory.
- Do not mix briefs, slide maps, crops, and extracted figures from different papers in one shared folder.

## Workflow

1. Determine the talk scenario, language, and register.
   - If the user names the occasion, follow it.
   - Otherwise default to a paper reading or seminar deck.
   - Read `references/deck-structures.md` for the deck arc. For systems, architecture, storage, database, or serving papers, check whether the `Systems Paper Reading / OSDI-SOSP Style` arc fits before defaulting to a generic seminar arc.
   - Read the language reference that matches the requested output:
     - `references/chinese-academic-style.md`
     - `references/english-academic-style.md`
2. Build the paper brief.
   - Create the paper-specific `notes/...` and `assets/...` directories first so downstream extraction and drafting steps write into the right namespace.
   - Prefer the paper's own figures and tables over generated visuals.
   - Keep exact numbers intact.
   - Reorganize around claims, not the paper's section order.
   - If reused paper figures need cleanup, read `references/figure-prep.md` and run `scripts/prepare_figure.py` before layout work.
   - If the source is a PDF and you first need to recover the best figure asset, explicitly ask Codex to spawn `figure_extractor`, which should use `$figure-extraction` before layout work continues.
3. Build the slide map.
   - Spread method and results across more pages instead of compressing text.
   - Choose a stable slide archetype for each page from `references/archetypes.md`.
   - Vary neighboring figure-heavy slides instead of repeating the same side-by-side layout by default.
   - For systems papers, give the thesis, overview, major mechanisms, and main evidence room to breathe. Do not collapse multiple independent mechanisms into one overloaded "method" slide.
4. Draft with the local presentation system.
   - Read workspace instructions first if the repo contains `AGENTS.md`.
   - Read `references/lemonade-theme.md` before drafting or revising slides in this repo.
   - Reuse the local `lemonade.typ` macros, layouts, and deck conventions instead of inventing a parallel system.
   - For repo decks compiled with `typst compile --root .`, prefer root-relative imports such as `/lemonade.typ` and `/theme/...`.
   - Default to `#imgs(...)` from `theme/images.typ` for single figures, comparison rows, and captioned figure blocks. Do not add deck-local wrappers such as `figcell` unless you have inspected `theme/images.typ` and confirmed a real missing capability.
   - If the same layout or helper problem appears across multiple slides, inspect the owning theme file first instead of adding repeated per-slide workarounds.
5. Validate as a deck.
   - Prepare cropped figures with `scripts/prepare_figure.py <image> --preview` when the raw asset carries paper chrome or inconsistent margins.
   - Run `scripts/validate_deck.sh <deck.typ>` to compile and export preview images when available.
   - Use `references/visual-qa.md` as a pass/fail rubric.
   - Fix visual failures in this order: crop or split evidence, change archetype, split slide, then consider local overrides.
   - On figure-led slides, default to one or two short takeaway boxes. Each box should preferably fit on one line and should rarely exceed two.
   - Do not accept accidental continuation pages, broken outlines, footer overflow, or unreadable evidence figures.

## Non-Negotiables

- Do not retell the paper section by section.
- Do not leave title-plus-image-only slides.
- Do not rely on captions to carry the main takeaway.
- Do not accept table-plus-figure slides if the figure becomes tiny.
- Do not shrink text before trying a better composition or another slide.
- Do not invent deck-local figure helpers for ordinary image layout before checking whether `theme/images.typ` already supports the needed composition.
- Do not accept figure-led slides where title, boxes, and caption leave the evidence as a thumbnail or narrow strip.
