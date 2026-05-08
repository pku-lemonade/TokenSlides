---
name: figure-generation
description: Creates source-grounded generated figure assets for academic slide decks by delegating bitmap creation/editing to $imagegen. Use when a parent paper-to-slides workflow needs polished lecture diagrams, visual replacements for paper figures/tables, or a consistent visual series registered as workspace assets.
---

# Figure Generation

This skill is the operating procedure for generated slide figures. It is the generated-asset sibling of `figure_extractor`: the parent workflow owns the deck story and evidence; this skill owns image creation, local validation, and registry-ready metadata.

## Input Contract

The parent should pass:

- workspace and target output path under `out/<paper>/assets/`
- slide id, slide title, and intended archetype
- `visual_intent`: what the figure must teach
- `source_evidence`: paper text, exact values, or source figure references that ground the visual
- required labels or in-image text, if any
- caption draft and candidate slide role
- style target, usually polished ACM SOSP/OSDI systems lecture diagram quality
- constraints, especially no invented metrics, no unsupported claims, and no unreadable text

If required labels are not known, ask the parent for them before generating. Do not invent quantitative labels, axes, or numbers.

## Workflow

1. Read only the evidence needed for the visual.
2. Decide whether the task is `generate` or `edit` under `$imagegen`.
   - Use `generate` for a new explanatory diagram.
   - Use `edit` when preserving layout/style from a starting reference or making a series from one base diagram.
3. Build a concise production prompt.
   - State the teaching intent.
   - Name required labels exactly.
   - Request clean systems-diagram quality.
   - Avoid over-specifying deck-specific symbols unless the parent supplied them.
4. Use `$imagegen` and save the selected output into the workspace.
5. Inspect the rendered bitmap.
   - Labels are legible and accurate.
   - The visual matches the evidence and does not add claims.
   - Style is consistent with neighboring generated figures.
   - No title band, watermark, or explanatory paragraph appears inside the image unless explicitly requested.
6. Iterate once with a targeted prompt if a required label, layout, or style invariant fails.
7. Return registry-ready metadata to the parent.

## Output Metadata

Return enough information for `academic-paper-to-slides/scripts/paper_artifacts.py upsert-asset`:

- `asset_id`
- `asset_type: figure`
- `source_mode: generated`
- `primary_output`
- `normalized_caption`
- `candidate_roles`
- `generation_prompt`
- `source_evidence`
- notes on validation or remaining risk

## Boundaries

- Do not write slide prose or choose the deck arc.
- Do not call `figure_extractor` unless the parent explicitly switches the asset to extracted or hybrid.
- Do not leave project-bound assets under the default image-generation output directory.
- Do not use generated figures for exact empirical plots unless the parent supplies exact data and asks for a redrawn chart.
