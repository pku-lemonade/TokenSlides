---
name: academic-paper-to-slides
description: Create new Lemonade Typst slide material from academic papers. Use for a new deck, a substantial paper-derived addition, or an explicit source-driven rebuild that needs fresh source extraction, argument design, evidence planning, and assets. Do not use for routine edits to an existing deck, theme work, validation-only work, or PowerPoint export.
---

# Academic Paper to Slides

Turn paper sources into new slide material. This is a one-way `paper -> slides` workflow.

## Boundary

- Use this skill for a new paper-derived deck, a substantial paper-derived addition, or an explicit rebuild from paper sources.
- After handoff, edit the existing deck directly under `AGENTS.md` and its canonical artifacts. Do not invoke this skill for slide copy, layout, styling, Typst debugging, theme maintenance, or validation alone.
- Do not invoke this skill just to use its scripts. Existing-deck work may call the helpers directly.

## Workflow

1. Frame the talk.
   - Follow the requested occasion, language, and register; default to a paper-reading deck.
   - If the user did not supply a complete arc, read [deck-structures.md](references/deck-structures.md). Read only the matching [Chinese](references/chinese-academic-style.md) or [English](references/english-academic-style.md) guide.
2. Create and plan the paper workspace.
   - Keep the deck, `notes/`, and `assets/` under one disambiguated `out/<paper>/` workspace.
   - For a new workspace, run `<skill-dir>/scripts/paper_artifacts.py init-workspace <paper.pdf> --workspace out/<paper>` from the repository root.
   - For an addition, do not initialize. Extend the existing source notes, asset registry, brief, and slide plan in place; preserve IDs and escape fragments before re-emission.
   - Read [planning-artifacts.md](references/planning-artifacts.md), then complete source extraction, `assets.json`, `brief.json`, and `slides.json` before emitting Typst. JSON is canonical; Markdown notes are derived.
   - Default to source-grounded generated visuals through `figure-generation`. Use `figure-extraction` only when the user requests original paper figures or a hybrid policy. Read [figure-prep.md](references/figure-prep.md) only for reproducible cleanup of a selected asset.
3. Build the slide material.
   - Follow `AGENTS.md` and use the local Lemonade theme.
   - Run `<skill-dir>/scripts/paper_artifacts.py emit-deck --workspace out/<paper>` by default. Use escape mode only for a source-grounded layout the emitter cannot express.
   - Read [archetypes.md](references/archetypes.md) only when an escape-mode slide needs composition guidance. Read [lemonade-theme.md](references/lemonade-theme.md) only when emitter-specific theme mapping is unresolved.
4. Verify the delivered deck.
   - Run `<skill-dir>/scripts/paper_artifacts.py validate-artifacts --workspace out/<paper>`.
   - Run `<skill-dir>/scripts/validate_deck.sh <deck.typ>` and inspect the rendered slides using [visual-qa.md](references/visual-qa.md).

## Contracts

- Rebuild the paper as a presentation argument, not a section-by-section retelling.
- Give every planned slide a takeaway and source-grounded evidence before drafting it.
- Keep figures readable at slide scale; split content before shrinking text.
- Emit theme defaults. Avoid per-slide size overrides and near-default layout knobs.
- Keep the workspace artifacts synchronized so later direct edits cannot be overwritten by regeneration.

The skill ends when the new slide material, canonical artifacts, and verification are delivered. Post-handoff corrections are maintenance evidence, not a reason to restart this workflow.
