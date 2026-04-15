---
name: academic-paper-to-slides
description: Convert academic papers, preprints, and local PDF manuscripts into Typst slide decks in the local lemonade theme. Use when the user asks to draft, revise, or reorganize slides for paper readings, seminars, research overviews, proposal/midterm/final defenses, or similar academic talks.
---

# Academic Paper to Slides

Turn a paper into a presentation argument. Do not mirror the PDF page by page.

## Use This Skill To

- distill one paper or a small paper set into slides
- extract claims, tables, and exact numbers from a PDF while delegating figure asset recovery to `figure_extractor`
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

Keep each paper's generated artifacts inside one paper workspace directory rather than scattering them across shared top-level folders.

Preferred layout:

- `examples/<paper>/<paper>.typ`
- `examples/<paper>/notes/brief.md`
- `examples/<paper>/notes/slide-map.md`
- `examples/<paper>/assets/...`

Rules:

- Default to one workspace directory per paper under `examples/`.
- If two source PDFs would map to the same `<paper>` name, disambiguate the workspace directory with a short parent-folder prefix such as `examples/<parent>-<paper>/`.
- Keep briefs, slide maps, crops, and extracted figures inside that paper workspace.
- Do not create shared top-level `notes/...` or `assets/...` folders for generated paper artifacts.

## Workflow

1. Determine the talk scenario, language, and register.
   - If the user names the occasion, follow it.
   - Otherwise default to a paper reading or seminar deck.
   - Read `references/deck-structures.md` for the deck arc. For systems, architecture, storage, database, or serving papers, check whether the `Systems Paper Reading / OSDI-SOSP Style` arc fits before defaulting to a generic seminar arc.
   - Read the language reference that matches the requested output:
     - `references/chinese-academic-style.md`
     - `references/english-academic-style.md`
2. Build the paper brief.
   - Create `examples/<paper>/notes/` and `examples/<paper>/assets/` first so downstream extraction and drafting steps write into the right namespace.
   - Prefer the paper's own figures and tables over generated visuals.
   - Keep exact numbers intact.
   - If you need any figure recovery from a PDF or slide deck, spawn subagent `figure_extractor`. Do not run figure extraction inline from the parent slide-writing context.
   - Reorganize around claims, not the paper's section order.
   - If reused paper figures need cleanup, read `references/figure-prep.md` and run `scripts/prepare_figure.py` before layout work.
3. Build the slide map.
   - Spread method and results across more pages instead of compressing text.
   - Choose a stable slide archetype for each page from `references/archetypes.md`.
   - Vary neighboring figure-heavy slides instead of repeating the same side-by-side layout by default.
   - For systems papers, give the thesis, overview, major mechanisms, and main evidence room to breathe. Do not collapse multiple independent mechanisms into one overloaded "method" slide.
   - Plan boxed takeaways and captions as short lines, not mini-paragraphs. Prefer one-line boxes and one-line captions unless the evidence truly needs more text.
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
   - Prefer one-line captions. If a caption wraps, first shorten it; if needed, slightly widen the figure block when that does not materially hurt figure readability.
   - Remove low-value wording before changing layout: obvious labels, weak transitions, and phrases such as `Figure X shows ...` or `the figure above shows ...`.
   - Do not accept accidental continuation pages, broken outlines, footer overflow, or unreadable evidence figures.

## Non-Negotiables

- Do not retell the paper section by section.
- Do not leave title-plus-image-only slides.
- Do not rely on captions to carry the main takeaway.
- Do not waste box or caption budget on low-information phrasing such as `Figure 3 shows`, `the figure above`, or obvious restatements of the visual.
- Do not accept table-plus-figure slides if the figure becomes tiny.
- Do not shrink text before trying a better composition or another slide.
- Do not run `$figure-extraction` inline from the slide-writing agent; delegate figure asset recovery to `figure_extractor`.
- Do not invent deck-local figure helpers for ordinary image layout before checking whether `theme/images.typ` already supports the needed composition.
- Do not accept figure-led slides where title, boxes, and caption leave the evidence as a thumbnail or narrow strip.
