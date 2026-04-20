---
name: academic-paper-to-slides
description: Builds Typst slide decks in the local lemonade theme from academic papers, preprints, and manuscript PDFs. Use when the user asks to draft, revise, or reorganize paper-reading, seminar, overview, or defense slides from paper content.
---

# Academic Paper to Slides

Turn a paper into a presentation argument instead of mirroring the PDF page by page.

## Use This Skill To

- distill one paper or a small paper set into slides
- extract claims, tables, equations, and exact numbers from a PDF while delegating figure asset recovery to `figure_extractor`
- adapt the same source into different academic contexts such as seminar, reading report, overview, or defense

## Output Layout

Keep each paper's generated artifacts inside one paper workspace directory rather than scattering them across shared top-level folders.

Preferred layout:

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

Rules:

- Default to one workspace directory per paper under `out/`.
- If two source PDFs would map to the same `<paper>` name, disambiguate the workspace directory with a short parent-folder prefix such as `out/<parent>-<paper>/`.
- Keep briefs, slide maps, crops, and extracted figures inside that paper workspace instead of shared top-level folders.
- Treat `notes/*.json` as canonical artifacts. Treat the Markdown notes as derived inspection files rendered from JSON.

## Workflow

1. Determine the talk scenario, language, and register.
   - If the user names the occasion, follow it.
   - Otherwise default to a paper reading deck.
   - Read `references/deck-structures.md` for the deck arc. Use `Systems Paper Reading / OSDI-SOSP Style` by default unless the user names a different occasion such as a defense or progress report.
   - Read the language reference that matches the requested output:
     - `references/chinese-academic-style.md`
     - `references/english-academic-style.md`
2. Create the paper workspace.
   - Create `out/<paper>/notes/` and `out/<paper>/assets/` before any extraction, briefing, or drafting work.
   - Use `scripts/paper_artifacts.py init-workspace <paper.pdf> --workspace out/<paper>` to create `assets.json`, `brief.json`, `slides.json`, `review.json`, and the derived Markdown placeholders.
   - Keep all generated notes and assets in that workspace namespace.
3. Plan the artifacts before writing Typst.
   - Read `references/planning-artifacts.md`.
   - Complete the JSON artifacts and derived notes before drafting slides.
   - Run source extraction and the initial asset recovery pass before writing `notes/slides.json`.
4. Draft with the local presentation system.
   - Read workspace instructions first if the repo contains `AGENTS.md`.
   - Read `references/lemonade-theme.md` before drafting or revising slides in this repo.
   - Read `references/archetypes.md` for composition choice and split-slide decisions.
   - Reuse the local `lemonade.typ` macros, layouts, and deck conventions instead of inventing a parallel system.
   - Keep Typst generation thin and deterministic. Make content decisions in `notes/slides.json`, not ad hoc during emission.
   - Use `scripts/paper_artifacts.py emit-deck --workspace out/<paper>` by default. Reserve `render_mode: "escape"` for unusual layouts that still stay source-grounded.
5. Validate as a deck.
   - Run `scripts/paper_artifacts.py validate-artifacts --workspace out/<paper>` when the workspace has JSON artifacts.
   - Read `references/visual-qa.md` as the pass/fail rubric.
   - Read `references/figure-prep.md` when a selected registry asset needs reproducible cleanup.
   - Run `scripts/validate_deck.sh <deck.typ>` to compile the deck to a validation PDF.

## Reference Map

- `references/deck-structures.md`: default arc selection, pacing, and scenario-specific structure
- `references/planning-artifacts.md`: artifact checklist, asset and brief rules, slide-map fields, evidence planning, and escape-mode planning
- `references/english-academic-style.md` / `references/chinese-academic-style.md`: sentence, title, and phrasing guidance
- `references/archetypes.md`: composition choice and readability-driven split decisions
- `references/lemonade-theme.md`: Typst, Lemonade, and image-helper usage
- `references/figure-prep.md`: reproducible crop cleanup for selected assets
- `references/visual-qa.md`: rendered-slide acceptance rubric

## Non-Negotiables

- Rebuild the paper as a presentation argument rather than a section-by-section retelling.
- Keep `notes/*.json` canonical and re-render the Markdown notes instead of treating the `.md` files as the source of truth.
- Run the initial asset pass before drafting and keep figure recovery delegated to `figure_extractor`.
- Keep a slide-level takeaway in JSON for every planned slide.
- Assign source-grounded evidence before drafting a slide.
- Do not rely on captions alone to carry the main takeaway.
- Keep figures readable at slide scale. Split dense slides or split evidence before shrinking text.
- Reuse theme image helpers before adding deck-local layout helpers.
