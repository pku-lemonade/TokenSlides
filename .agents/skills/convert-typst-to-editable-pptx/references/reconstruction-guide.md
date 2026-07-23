# Native Reconstruction Guide

Use this guide to turn a Typst/Touying presentation into a deck-specific native PowerPoint builder. Preserve the authored deck; do not redesign it unless the user asks.

## Contents

- Establish the source baseline
- Record the design system
- Build a slide map and editability ledger
- Map source elements to native PowerPoint
- Structure the builder
- Reconstruct diagrams
- Handle typography deliberately
- Handle images and media
- Direct converter policy

## Establish the Source Baseline

1. Read repository instructions and the presentation entry file.
2. Resolve `#import`, `#include`, theme wrappers, slide macros, fonts, and asset paths.
3. Compile from the correct root into scratch space. Do not trust an existing PDF; dates, counters, conditional branches, and state may be stale.
4. Render every compiled PDF page at a consistent size for visual inspection.
5. Decide how Touying overlays or pauses map to PowerPoint. By default, preserve every compiled page/state as a slide and verify the final count.

Treat source and render as complementary:

- source reveals structure, semantics, asset identity, and dynamic expressions;
- render reveals final layout, wrapping, state, colors, and generated outline slides.

## Record the Design System

For lemonade decks this is generated, not captured: run
`scripts/make_theme_profile.py --root <project-root> --output
<scratch>/theme-profile.json` and read that disposable profile — every
`<feature>-config` in `theme/*.typ` is exported automatically (AGENTS.md
"Config convention"). Never create or update a profile under the skill's
`references/` directory. The deck's own choices come from its
`lemonade-theme.with(...)` arguments. `layout-config.<aspect>.page-size` is
PowerPoint's standard canvas, so Typst point geometry transfers 1:1. Empirical
constants that the profile cannot express live in
[lemonade-calibration.md](lemonade-calibration.md).

Two Lemonade mappings are easy to get subtly wrong:

- If `slide-config.centered-title-full-bleed` is true, use a zero-inset title
  textbox spanning the full slide width. Overlay the separate page-number
  object; do not reserve its width or shrink the title, because the narrower
  frame can wrap in PowerPoint even when another renderer keeps one line.
- Apply `outline-config.entry-weight` to every outline entry and
  `outline-config.title-weight` to its title. Current-section emphasis comes
  from the source color/opacity logic; do not infer a weight change from the
  active state.

For non-lemonade decks, capture these values before building slides:

- aspect ratio and page dimensions;
- title, content, section, outline, and thank-you layouts;
- body, heading, code, and fallback fonts;
- palette, border colors, line weights, and background fills;
- slide margins, gutters, card gaps, footer geometry, and page numbers;
- recurring box, callout, table, and image treatments.

Confirm that required fonts are installed. Font substitution changes wrapping and can invalidate an otherwise accurate reconstruction.

## Build a Slide Map and Editability Ledger

Create a scratch JSON or text manifest with one entry per slide:

```json
{
  "index": 1,
  "kind": "content",
  "title": "Example",
  "elements": [
    {
      "source": "Touying card grid",
      "target": "native shapes and text",
      "asset": null,
      "editable": true
    }
  ]
}
```

Record every image that is allowed to remain media. The final package's picture relationships must reconcile with this ledger.

## Map Source Elements to Native PowerPoint

| Typst/Touying source | PowerPoint target |
| --- | --- |
| Plain or emphasized text | Editable text box or shape rich-text runs |
| Rectangles, boxes, cards, bands | Native shapes with fills, borders, and text |
| Grids and columns | Explicit, stable coordinates and dimensions |
| Flowcharts and technical routes | Native nodes plus connector objects |
| Tables | Native table, or aligned editable cell shapes when styling demands it |
| Code blocks | Editable monospaced text with preserved line breaks |
| Charts | Native chart objects when supported; otherwise editable shapes and labels |
| Equations | Native Office math when supported; otherwise an editable text construction and disclosed limitation |
| Logo, photo, screenshot, source figure | Original source asset, preferably SVG/vector |
| Decorative theme graphics | Native shapes when simple; original vector only when it is a genuine source asset |
| Overlay/pause states | Separate slides unless supported animation is explicitly required |

Never use a PDF page, slide screenshot, or page-sized SVG as an element mapping.

## Structure the Builder

Use a plain `.mjs` builder and keep it in scratch space. Prefer these layers:

1. constants for page size, fonts, colors, spacing, and naming;
2. primitive helpers for shapes, text, rich-text runs, images, and connectors;
3. reusable slide-layout helpers;
4. data-driven slide content;
5. preview, inspection, export, and validation steps.

Useful primitives include `addShape`, `addText`, `applyText`, `markupRuns`, `addCard`, `addCallout`, `connect`, and `diagramBox`.

Apply a text box's base style before assigning structured rich-text runs. Assigning base style afterward can erase run-level emphasis during export.
If the export library drops paragraph properties during `text.set`, reapply
only those properties through text ranges after the runs are installed. Do not
reassign the whole base style afterward.

Give elements stable, unique names. Use explicit geometry rather than positions inferred from content.

Name shapes by role so typography expectations can target them mechanically:

| Name prefix | Theme size role |
| --- | --- |
| `slide-title-` | `font-sizes.slide-title` |
| `section-title-` | `font-sizes.section` |
| `card-title-` | `font-sizes.body-title` |
| `body-` | `font-sizes.body` |
| `caption-` | `font-sizes.small` |
| `code-` | `font-sizes.code` |
| `footer-` / `page-number-` | footer text size / `font-sizes.page-number` |

## Reconstruct Diagrams

Decompose each diagram into:

- semantic nodes;
- containment frames;
- directed edges;
- labels and annotations;
- repeated stages or lanes.

Create nodes first, then connectors, labels, and frames in a z-order verified by rendering. Connector APIs can expose counterintuitive arrow-end names; verify direction visually in the exported PPTX rather than trusting the property name.

Redraw tables and diagram screenshots even when the source embeds them as raster images, unless the user explicitly chooses limited editability.

## Handle Typography Deliberately

- Keep source typography values in points and follow
  [point-safe-typography.md](point-safe-typography.md) at the CSS-pixel boundary.
- Preserve deliberate source line breaks; do not reproduce incidental PDF extraction breaks.
- Keep following Chinese punctuation with the preceding emphasized run when practical.
- Match explicit font faces and weights, including Medium body faces and Bold emphasis faces.
- Treat Typst OpenType features such as `halt` as shaping inputs; PowerPoint may require punctuation-aware run boundaries and geometry compensation.
- Preserve script-specific and role-specific point sizes in rich-text runs.
- Add explicit line breaks for long Latin identifiers only when the final PowerPoint renderer requires them.
- Keep code, equations, and labels inside fixed bounds.
- Validate Chinese and Latin mixed text in the exported PPTX, because in-memory previews can wrap differently.

## Handle Images and Media

Keep only declared source assets. Prefer the original file rather than extracting it from a PDF render.

An SVG may produce a tiny PNG compatibility fallback in the PPTX package. Correlate media files with picture relationships and dimensions before treating that fallback as a rasterized slide.

Disclose any retained non-editable asset in the final response. A retained logo or photo is normal; a retained diagram or whole slide is not.

## Direct Converter Policy

Probe a direct converter only when it can preserve the custom Typst/Touying structure as native objects. Open and audit its output before trusting it.

For custom themes and macros, assume semantic reconstruction is required. Pandoc, LibreOffice, WPS, and browser converters are not acceptable merely because they produce a file with a `.pptx` extension.
