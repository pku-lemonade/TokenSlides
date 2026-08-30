---
name: convert-typst-to-editable-pptx
description: Rebuild a Typst, Touying, or Lemonade deck as a visually faithful, fully editable .pptx with native PowerPoint objects. Use only when object-level editability is required. For a faster flattened conversion that preserves the compiled PDF's appearance, use convert-pdf-to-pptx instead.
---

# Typst to Editable PowerPoint

Rebuild a Typst deck as native PowerPoint. The compiled PDF is a visual reference, never slide artwork.

## Boundary

- Input is a Typst source deck; output is a verified editable `.pptx`.
- If the user values exact visual reproduction or turnaround more than object-level editing, stop and route to `$convert-pdf-to-pptx`; do not reconstruct the deck unnecessarily.
- After handoff, use the presentation skill for PPTX-only edits and normal repo guidance for Typst-only edits.
- Re-enter this skill only when the user asks to create or regenerate PowerPoint from Typst.

## Composition

- Use the installed `presentations:Presentations` skill when available. Announce both skills and read its `SKILL.md`. Follow its artifact-tool, runtime, rendering, and packaging requirements.
- Treat the Typst deck as the visual source. Skip template selection. This skill's source-fidelity and native-editability rules override generic visual routing: do not replace source diagrams with Graphviz or generated images when that would reduce editability.
- Use `@oai/artifact-tool` where that presentation skill requires it. Do not use `python-pptx` for authoring; reserve it for permitted diagnostics.
- Keep the source `.typ` files unchanged unless the user also requests source edits.

## Reference Router

- Read [reconstruction-guide.md](references/reconstruction-guide.md) before authoring. It owns source analysis, design-system capture, semantic mapping, and native builder structure.
- Read [point-safe-typography.md](references/point-safe-typography.md) when the authoring API crosses between Typst points, CSS pixels, and OOXML.
- Read [lemonade-calibration.md](references/lemonade-calibration.md) only for Lemonade profile facts or runtime-specific empirical constants.
- Read [qa-protocol.md](references/qa-protocol.md) before acceptance. It owns commands, audits, and delivery cleanup.

## Invariants

- Build text, cards, tables, diagrams, and connectors as editable native objects.
- Never place a rendered slide or PDF page, a screenshot of a slide, or a page-sized bitmap/SVG surrogate of a slide in the final PPTX.
- Preserve legitimate source media such as logos, photos, screenshots, and figures; prefer original vector assets.
- Preserve slide count, order, hierarchy, and meaning. Do not drop dense content or reduce source font sizes to force a fit.
- Use one text box per semantic text block, not one per visual line.
- Stop and report a missing authoring capability. Never fall back to a flattened export.

## Workflow

1. Compile a fresh source PDF with the correct project root. Read the source and relevant includes semantically, then keep the slide manifest and all intermediate files in scratch space.
2. Reconstruct recurring theme geometry and slide types before content. For Lemonade decks, generate a disposable live theme profile with `scripts/make_theme_profile.py`; never write a profile into `references/`.
3. Export the `.pptx`, render the exported file itself, and compare every slide with the fresh Typst render. Fix clipping, overlap, font substitution, line breaks, z-order, connector direction, and geometry drift.
4. Re-import the final file and run editability, typography, overflow, and package audits. For Lemonade decks, also run the live-profile and Lemonade contract audits.

Use the requested output path and never overwrite an existing file silently. By default, deliver only the final `.pptx`. State which legitimate assets remain images, that the exported deck was visually checked, and any narrow editability limitation.
