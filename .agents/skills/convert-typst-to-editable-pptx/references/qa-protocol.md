# QA and Editability Protocol

The exported PPTX is authoritative. In-memory previews are useful iteration aids, not acceptance evidence.

## Contents

- Verify the source baseline
- Inspect authoring previews
- Render the exported PPTX
- Run overflow diagnostics
- Re-import the final file
- Audit OOXML editability
- Audit serialized typography
- Apply the acceptance gate
- Clean and deliver

## 1. Verify the Source Baseline

- Compile the requested `.typ` fresh from the correct root.
- Confirm page count, aspect ratio, dynamic date/content, and fonts.
- Inspect every source page at full size.
- Keep source renders in scratch; never embed them in the deck.

## 2. Inspect Authoring Previews

Export per-slide previews and layout diagnostics while building. Use a montage only to navigate the deck, then inspect each slide at full size.

Check slide count, object order, recurring margins, title alignment, footer behavior, and major omissions before exporting.

## 3. Render the Exported PPTX

Use the installed presentation skill's renderer. Derive the render size from
the deck's slide dimensions (`layout-config.<aspect>.page-size` in the theme
profile) — e.g. `1600x900` for a 16-9 deck, `1600x1200` for 4-3. Rendering a
4-3 deck at a 16-9 viewport invalidates every visual comparison.

```bash
python <presentations-skill-dir>/container_tools/render_slides.py \
  <output.pptx> --output_dir <scratch/pptx-render> \
  --width <w> --height <h>
```

Inspect every rendered slide, not only a contact sheet. Compare it beside the corresponding Typst render.

Fix all:

- text clipping, overlap, and missing glyphs;
- orphaned punctuation and poor CJK/Latin wrapping;
- wrong z-order or hidden diagram nodes;
- incorrect connector direction or routing;
- footer, page-number, title, and color drift;
- accidental font substitution;
- stretched, cropped, or low-resolution legitimate assets.

## 4. Run Overflow Diagnostics

Run the presentation skill's `slides_test.py` or equivalent:

```bash
uv run --with python-pptx --with pdf2image \
  python <presentations-skill-dir>/container_tools/slides_test.py <output.pptx>
```

Treat this as one signal only. It does not detect semantic omissions, text clipped inside its own box, orphan punctuation, visual overlaps, or incorrect arrows.

## 5. Re-Import the Final File

Reopen the exported PPTX with the same authoring library. Confirm the slide count and inspect native object counts after serialization:

```js
import { FileBlob, PresentationFile } from "@oai/artifact-tool";

const deck = await PresentationFile.importPptx(
  await FileBlob.load("output.pptx"),
);

if (deck.slides.items.length !== expectedSlides) {
  throw new Error("Slide count changed after export");
}

const result = await deck.inspect({
  kind: "slide,textbox,shape,image",
  maxChars: 500000,
});
console.log(result.ndjson);
```

Expect substantial textbox and native-shape counts for a content-rich deck. A successful render with one picture per slide is a failure.

## 6. Audit OOXML Editability

Run the bundled script:

```bash
python <this-skill-dir>/scripts/audit_pptx_editability.py <output.pptx>
```

The audit must reconcile:

- slide count;
- text-bearing and native shape counts;
- connector and graphic-frame counts;
- picture relationships and coverage;
- packaged media types and sizes;
- suspicious near-full-slide pictures.

Compare every picture with the editability ledger. Investigate undeclared images even when they are small.

Use `--allow-full-slide-pictures` only when the user explicitly accepts a legitimate full-slide photo or other limited-editability source asset. Never use it to excuse rendered slide pages.

## 7. Audit Serialized Typography

Generate the policy from the tracked theme profile, then audit:

```bash
python <this-skill-dir>/scripts/make_typography_policy.py \
  --aspect <deck-aspect> --output <scratch/typography-policy.json>
python <this-skill-dir>/scripts/audit_pptx_typography.py \
  <output.pptx> --policy <scratch/typography-policy.json>
```

Add `--extra-size` for module-derived sizes (see lemonade-calibration.md).
Chart parts are audited for explicit sizes; charts reported under
`chart_parts_without_explicit_sizes` must be inspected visually.

Require explicit point sizes, forbid shrinking AutoFit, and use targeted
expectations for mixed-size or role-critical text. Read
[point-safe-typography.md](point-safe-typography.md) for the policy schema and
CSS-pixel conversion contract.

## 8. Apply the Acceptance Gate

Pass only when all are true:

- `make_theme_profile.py --check` passes (the tracked theme profile is not stale);
- final slide count and order match the intended compiled states;
- every slide has been inspected at full size from the actual PPTX;
- all text that should be editable is native text;
- all diagrams, tables, arrows, and cards that should be editable are native objects;
- package pictures match declared legitimate source assets;
- no undeclared full-slide image exists;
- no visible clipping, overlap, bad wrapping, or incorrect connector remains;
- final DrawingML point sizes match the effective Typst typography policy;
- no text is visually resized by AutoFit unless explicitly required and documented;
- the final deck re-imports successfully;
- overflow diagnostics pass or every false positive is explained.

Pixel similarity alone is not a valid gate: a flattened screenshot would score perfectly while failing editability.

## 9. Clean and Deliver

Remove accidental `.inspect.ndjson`, render folders, manifests, and temporary builders from the deliverable directory. Preserve them only in scratch if further iteration is likely.

Deliver one PPTX link. State which legitimate assets remain images and disclose any narrowly scoped limitation. Do not claim full editability when a diagram, equation, or slide has been flattened.
