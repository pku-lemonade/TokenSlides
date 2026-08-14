---
name: convert-typst-to-editable-pptx
description: Convert Typst, Touying, or Lemonade slide sources (.typ) into visually faithful, fully editable Microsoft PowerPoint (.pptx) decks by rebuilding text, cards, tables, diagrams, and connectors as native objects instead of exporting slides as PNG, PDF, or other flattened images. Use when Codex is asked to export, convert, port, or recreate a Typst presentation in PowerPoint while preserving editability, theme, layout, and slide structure, especially for decks with custom themes, Touying APIs, technical diagrams, or mixed Chinese and Latin typography.
---

# Convert Typst to Editable PowerPoint

Reconstruct the presentation as a native PowerPoint deck. Treat the compiled Typst PDF as a visual reference, never as slide artwork.

## Required Composition

Use the installed `presentations:Presentations` skill when it is available. Announce both skills, read that skill's `SKILL.md` completely, and follow its authoring and render-and-verify requirements.

Use `@oai/artifact-tool` for authoring in environments governed by that presentation skill. Do not use `python-pptx` to build the deck; reserve it for final diagnostics when permitted.

Read [references/reconstruction-guide.md](references/reconstruction-guide.md) before implementing the conversion. Read [references/qa-protocol.md](references/qa-protocol.md) before validating or delivering the output.
Read [references/point-safe-typography.md](references/point-safe-typography.md) before mapping Typst font sizes into any CSS-pixel authoring API.
Read [references/lemonade-calibration.md](references/lemonade-calibration.md) before re-deriving any empirical constant (line spacing, font faces, runtime unit quirks); it holds verified calibrations for generated theme profiles.

## Non-Negotiable Output Rules

- Rebuild slide text, fills, borders, cards, tables, arrows, and diagrams as editable PowerPoint objects.
- Never place a rendered slide, PDF page, screenshot of a slide, or page-sized SVG behind the content.
- Preserve legitimate source assets such as logos, photographs, screenshots, and figures. Prefer their original SVG or other vector form when available.
- Redraw technical diagrams and table-like layouts with native shapes and connectors unless the user explicitly asks to preserve them as images.
- Keep the source `.typ` files unchanged unless the user also asks for source edits.
- Preserve the slide count, order, hierarchy, and meaning. Do not silently omit dense content to make reconstruction easier.
- Stop and report the limitation if a required authoring capability is unavailable. Never substitute a flattened export.

## Workflow

### 1. Resolve and Compile the Source

Locate the requested entry `.typ`, its project root, includes, theme files, fonts, and assets. Discover paths locally before asking the user.

Compile a fresh PDF with the same project root used by the source:

```bash
typst compile --root <project-root> <source.typ> <scratch/source.pdf>
```

Render the PDF pages for inspection only. Fresh compilation matters for dynamic dates, conditional content, counters, and stateful themes.

### 2. Build a Slide Manifest

Read the Typst source and all relevant includes semantically. Do not rely on PDF text extraction or regex alone for custom slide macros.

Record for every slide:

- index, kind, title, and section;
- text with emphasis, code, equations, and deliberate line breaks;
- layout type, columns, margins, cards, callouts, and footer behavior;
- diagrams, connectors, tables, charts, and legitimate image assets;
- theme colors, font families, font sizes, and recurring geometry.

Keep manifests, renders, and builder files in scratch space. Keep the final output directory clean.

Use the user's requested output path. If none is given, write `<source-stem>.pptx` beside the source deck without overwriting any existing file silently.

### 3. Reconstruct the Theme and Layout

For decks in this repo's lemonade theme, do not re-derive the design system by hand. Generate a disposable profile under the task scratch directory and read it:

```bash
PROFILE="$TMP_DIR/theme-profile.json"
python <this-skill-dir>/scripts/make_theme_profile.py \
  --root <project-root> --output "$PROFILE"
```

Never write or update a profile under this skill's `references/` directory. The scratch profile carries every `<feature>-config` from `theme/*.typ` (the AGENTS.md "Config convention" is the machine contract, so new theme configs appear automatically). Take the deck's own choices — aspect ratio, mode, overrides — from the `lemonade-theme.with(...)` call in the entry file. `layout-config.<aspect>.page-size` already equals PowerPoint's standard canvas, so Typst point geometry maps 1:1. Fall back to manual capture (reconstruction guide) only for non-lemonade decks.

Match the source aspect ratio and slide dimensions. Define reusable constants for palette, typography, spacing, margins, grid lines, and footer geometry from the profile. Keep typography constants in Typst/PowerPoint points even when slide geometry uses CSS pixels.

Use exact `pt * 96 / 72` values for numeric pixel text setters and explicit `pt` strings for structured runs; never round the conversion. Do not assume a point-named setter survives serialization without an OOXML smoke test. Do not reduce source font sizes to make text fit. Match fonts, rich-text runs, spacing, bounds, insets, and deliberate line breaks instead.

Apply whole-shape text style before structured runs, then set paragraph-only
properties through ranges if the authoring runtime drops them. Keep paragraph
spacing in the runtime's documented units and verify them with a one-shape
export smoke test; verified per-version pins live in
[references/lemonade-calibration.md](references/lemonade-calibration.md).

Build reusable helpers for recurring slide types before adding content:

- title and thank-you slides;
- section or outline slides;
- standard content and card grids;
- callout bands and footers;
- native diagram nodes and connectors;
- tables and image placement.

Use explicit geometry and stable dimensions. Keep text inside its assigned bounds across PowerPoint and LibreOffice renderers.

### 4. Rebuild Content Natively

Create all text as text boxes or text-bearing shapes. Preserve bold, color, code font, and paragraph structure with rich-text runs.

Use one text box per semantic text block: title, paragraph, list, callout,
card body, or table cell. Never recreate PDF visual lines as separate text
boxes. Preserve wrapping inside the semantic block with paragraph breaks and
rich-text runs; split a block only when its parts require independent geometry
or interaction.

Create all structure as native objects:

- cards and panels: rectangles plus editable text;
- routes and flows: shapes plus real connector objects with arrowheads;
- tables: native table objects or aligned editable cell shapes;
- charts: native chart objects when supported;
- equations: native Office math when supported, otherwise editable text construction with an explicit limitation note;
- repeated grids: deterministic coordinates rather than manual placement drift.

Treat source images as assets, not layout containers. Crop and size only the original asset; do not rasterize surrounding text or decoration with it.

### 5. Export and Inspect the Actual PPTX

Export the deck, then render the exported `.pptx` itself. Do not approve the deck solely from in-memory previews.

Inspect every slide at full size and compare it with the fresh Typst render. Fix:

- clipping, overlap, missing objects, or wrong z-order;
- font substitution and incorrect line breaks;
- isolated punctuation, especially in Chinese text;
- arrow direction, connector routing, and hidden diagram nodes;
- spacing, margins, color, footer, and slide-number drift.

Iterate until every slide is clean.

### 6. Prove Editability

Re-import the final PPTX with the authoring library and confirm the expected slide count and substantial native textbox/shape counts.

Run the bundled OOXML audit:

```bash
python <this-skill-dir>/scripts/audit_pptx_editability.py <output.pptx>
```

Investigate every reported full-slide picture. The only acceptable pictures are legitimate source assets, and their count should match the manifest.

Re-check the scratch profile against the live theme before final QA. If it is stale, regenerate it and rebuild the deck:

```bash
python <this-skill-dir>/scripts/make_theme_profile.py \
  --root <project-root> --output "$PROFILE" --check
```

Generate the typography policy from that exact profile (add `--extra-size` for module-derived sizes listed in the calibration reference), then audit the serialized DrawingML:

```bash
python <this-skill-dir>/scripts/make_typography_policy.py \
  --profile "$PROFILE" --aspect <deck-aspect> \
  --output "$TMP_DIR/typography-policy.json"
python <this-skill-dir>/scripts/audit_pptx_typography.py \
  <output.pptx> --policy "$TMP_DIR/typography-policy.json"
python <this-skill-dir>/scripts/audit_pptx_lemonade.py \
  <output.pptx> --profile "$PROFILE"
```

Require explicit sizes and forbid AutoFit unless the source semantics demand otherwise. Treat unexpected centipoint sizes as an export failure, not a harmless PowerPoint display difference.

Run the presentation skill's overflow checker and package validation. Remove generated inspection sidecars from the output directory.

### 7. Deliver

Return the final `.pptx` and state:

- that the deck was rebuilt with native editable objects;
- which legitimate assets remain images;
- that every slide was rendered and checked;
- whether any narrowly scoped editability limitation remains.

Do not deliver temporary renders, manifests, audit logs, or builder workspaces unless the user asks for them.

## Failure Modes to Avoid

- Converting PDF pages to PNG/JPEG and placing one image per slide.
- Exporting each slide as SVG and calling it editable.
- Trusting Pandoc, LibreOffice, or an online converter without opening and auditing the resulting PPTX.
- Extracting only PDF text and losing slide semantics, emphasis, or theme state.
- Drawing arrows as independent line segments that no longer indicate direction.
- Validating only the source render or an in-memory preview.
- Shrinking an entire slide globally to hide one overflow; adjust the affected object instead.
