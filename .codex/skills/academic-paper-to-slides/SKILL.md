---
name: academic-paper-to-slides
description: Builds Typst slide decks in the local lemonade theme from academic papers, preprints, and manuscript PDFs. Use when the user asks to draft, revise, or reorganize paper-reading, seminar, overview, or defense slides from paper content.
---

# Academic Paper to Slides

Turn a paper into a presentation argument instead of mirroring the PDF page by page.

## Use This Skill To

- distill one paper or a small paper set into slides
- extract claims, tables, and exact numbers from a PDF while delegating figure asset recovery to `figure_extractor`
- adapt the same source into different academic contexts such as seminar, reading report, overview, or defense

## Output Layout

Keep each paper's generated artifacts inside one paper workspace directory rather than scattering them across shared top-level folders.

Preferred layout:

- `out/<paper>/<paper>.typ`
- `out/<paper>/notes/asset-manifest.md`
- `out/<paper>/notes/brief.md`
- `out/<paper>/notes/slide-map.md`
- `out/<paper>/assets/...`

Rules:

- Default to one workspace directory per paper under `out/`.
- If two source PDFs would map to the same `<paper>` name, disambiguate the workspace directory with a short parent-folder prefix such as `out/<parent>-<paper>/`.
- Keep briefs, slide maps, crops, and extracted figures inside that paper workspace instead of shared top-level folders.

## Workflow

1. Determine the talk scenario, language, and register.
   - If the user names the occasion, follow it.
   - Otherwise default to a paper reading or seminar deck.
   - Read `references/deck-structures.md` for the deck arc. For systems, architecture, storage, database, or serving papers, check whether the `Systems Paper Reading / OSDI-SOSP Style` arc fits before defaulting to a generic seminar arc.
   - Read the language reference that matches the requested output:
     - `references/chinese-academic-style.md`
     - `references/english-academic-style.md`
2. Create the paper workspace.
   - Create `out/<paper>/notes/` and `out/<paper>/assets/` before any extraction, briefing, or drafting work.
   - Keep all generated notes and assets in that workspace namespace.
3. Complete the planning artifacts checklist before writing Typst.
   - Copy this checklist and finish it in order:
     ```
     Artifact Progress:
     - [ ] Recover likely visuals and write `notes/asset-manifest.md`
     - [ ] Write `notes/brief.md` from the paper text and manifest
     - [ ] Write `notes/slide-map.md` with evidence and archetypes
     ```
   - Produce these files in order: `notes/asset-manifest.md`, `notes/brief.md`, then `notes/slide-map.md`.
   - Keep this as one planning phase. Finish all three artifacts before drafting slides.
   - Asset manifest:
     - Start with an initial asset recovery pass.
     - Prefer the paper's own figures and tables over generated visuals.
     - Run recovery as an early pass so the deck is planned against real assets.
     - Recover all likely reusable slide assets early. Save detailed cleanup for the subset that survives into the final deck.
     - If a paper figure likely needs to be split across slides or stacked beside method text, recover the promising sub-assets during the extraction pass rather than assuming a late crop-prep step will solve the layout.
     - Delegate PDF or deck figure recovery to `figure_extractor`.
     - When you already know the figure number, page, or rough target region, pass that hint to `figure_extractor` and expect `bbox`, `primary_output`, and `preview_output` back.
     - Treat `figure_extractor` as script-first infrastructure. If figure recovery behavior is wrong, fix the extraction skill or script instead of adding parent-side PDF extraction workarounds.
     - Record each recovered asset in `out/<paper>/notes/asset-manifest.md`.
     - Keep all likely candidates in the manifest even if some will not be used later.
     - For each entry capture: figure or table identifier if known, source file, page number, `bbox`, capture kind, `primary_output`, `preview_output` if present, what claim or evidence the asset might support, and whether follow-up cleanup or additional sub-asset recovery is likely.
   - Paper brief:
     - Build it after the asset manifest so the brief can refer to recovered visuals instead of rediscovering them later.
     - Use the manifest plus the paper text as the source of truth for available visuals.
     - Capture the title, problem, motivation, assumptions, main idea, method components, evaluation setting, and quantitative results.
     - Keep exact baselines, datasets, model names, metrics, and improvements.
     - Reorganize around claims, not the paper's section order.
     - Identify 3 to 6 deck-level claims. Expand the method into multiple mechanism claims instead of collapsing the technique into 1 or 2 slides.
     - Inventory which mechanisms and results are best supported by recovered assets versus exact textual evidence.
   - Slide map:
     - Write one line per planned slide: section, title, takeaway, evidence, archetype.
     - Let each slide defend one claim.
     - Assign evidence from the manifest or from exact numbers in the paper before writing the slide.
     - Spread method and results across more pages instead of compressing text.
     - Choose a stable slide archetype for each page from `references/archetypes.md`.
     - Prefer titles that will stay on one line once drafted. If a slide-map title is already long, shorten it before layout work.
     - Vary neighboring figure-heavy slides instead of repeating the same side-by-side layout by default.
     - For systems papers, give the thesis, overview, major mechanisms, and main evidence room to breathe across separate slides when needed.
     - Do not force the default method side-by-side layout when the figure is short or wide. First check whether the manifest already contains another compatible asset or sub-asset. Then prefer a stacked evidence column or a wide-evidence page before reaching for late crop work.
     - Plan boxed takeaways and captions as short lines. Prefer one-line boxes and one-line captions unless the evidence truly needs more text.
     - Use the subset of manifest assets that sharpens the argument.
4. Draft with the local presentation system.
   - Read workspace instructions first if the repo contains `AGENTS.md`.
   - Read `references/lemonade-theme.md` before drafting or revising slides in this repo.
   - Reuse the local `lemonade.typ` macros, layouts, and deck conventions instead of inventing a parallel system.
   - For repo decks compiled with `typst compile --root .`, prefer root-relative imports such as `/lemonade.typ` and `/theme/...`.
   - Use `#imgs(...)` from `theme/images.typ` as the default for single figures, comparison rows, and captioned figure blocks.
   - For method slides with a short side figure, first look for already recovered companion assets from the same paper or figure. If they exist, prefer a vertically stacked evidence column built from one or two `#imgs(...)` blocks. Only fall back to new crop prep when the existing asset inventory still cannot support the slide.
   - Introduce deck-local wrappers such as `figcell` only after confirming that `theme/images.typ` cannot express the needed layout.
   - If the same layout or helper problem appears across multiple slides, inspect the owning theme file first and fix the root cause there when appropriate.
5. Validate as a deck.
   - Prepare cropped figures with `scripts/prepare_figure.py <image> --preview` when a selected manifest asset carries paper chrome or inconsistent margins and the current asset inventory still lacks the needed shape.
   - Run `scripts/validate_deck.sh <deck.typ>` to compile and export preview images when available.
   - Use `references/visual-qa.md` as a pass/fail rubric.
   - Fix visual failures in this order: reuse another recovered asset or change archetype, recover or split a better source asset, crop cleanup, split slide, then consider local overrides.
   - On figure-led slides, default to one or two short takeaway boxes. Each box should preferably fit on one line and should rarely exceed two.
   - Prefer one-line captions. If a caption wraps, first shorten it; if needed, slightly widen the figure block when that does not materially hurt figure readability.
   - Remove low-value wording before changing layout: obvious labels, weak transitions, and phrases such as `Figure X shows ...` or `the figure above shows ...`.
   - Do not accept accidental continuation pages, especially title-only pages or orphaned body fragments created by overflow.
   - Accept the deck only when pagination, outlines, footers, and evidence readability all pass.

## Non-Negotiables

- Rebuild the paper as a presentation argument rather than a section-by-section retelling.
- Give every slide a visible takeaway; keep captions as supporting text.
- Run the initial asset pass before drafting and keep figure recovery delegated to `figure_extractor`.
- Do not leave title-only continuation pages, title-plus-image-only pages, or body-only overflow pages.
- Do not rely on captions to carry the main takeaway.
- Do not waste title, box, or caption budget on low-information phrasing such as `Figure 3 shows`, `the figure above`, or obvious restatements of the visual.
- Keep figures readable at slide scale. Split evidence or split the slide when a figure becomes too small.
- Do not accept table-plus-figure slides if the figure becomes tiny.
- Do not accept figure-led slides where the title, boxes, and caption leave the evidence as a thumbnail or narrow strip.
- Split dense slides before shrinking text.
- Reuse theme image helpers before adding deck-local layout helpers.
