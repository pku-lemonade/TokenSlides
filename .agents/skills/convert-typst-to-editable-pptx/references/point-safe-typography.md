# Point-Safe Typography

Keep layout geometry and typography in separate unit systems. The presentation
canvas uses CSS pixels at 96 DPI; Typst and PowerPoint text sizes use points.

## Contents

- Unit contract
- Authoring pattern
- Source manifest
- Acceptance gate

## Unit Contract

- `1in = 96px = 72pt`.
- Numeric artifact-tool `fontSize` values are CSS pixels.
- PowerPoint DrawingML stores `sz` in hundredths of a point.
- Preserve a Typst point size as `round(pt * 100)` in final OOXML.
- Structured paragraph `spaceBefore` and `spaceAfter` units are
  runtime-version-specific; the verified pins (integer centipoints as of
  artifact-tool 2.8.22) live in [lemonade-calibration.md](lemonade-calibration.md).

Do not copy a Typst value such as `40pt` into `fontSize: 40`; that exports as
`30pt`. Do not round a point-to-pixel conversion to an integer or half-pixel.

## Authoring Pattern

Keep the design-system constants in points, taken from the disposable profile
generated for the current conversion (`layout-config.<aspect>.font-sizes`) —
never copied from examples. The values below are the 16:9 lemonade profile; a 4:3
deck uses different sizes (22/24/32/...):

```js
const TYPE_PT = Object.freeze({
  body: 26,       // layout-config["16-9"].font-sizes.body
  cardTitle: 28,  // ...body-title
  slideTitle: 40, // ...slide-title
});

const ptToPx = (pt) => pt * 96 / 72;

function applyPointText(shape, pointSize, style = {}) {
  shape.text.style = {
    ...style,
    fontSize: ptToPx(pointSize),
    autoFit: "none",
  };
}
```

Apply the base style before structured runs. Setting the entire style after
`shape.text.set(...)` can erase run-level bold, color, and typeface overrides.
Conversely, `shape.text.set(...)` can drop paragraph line spacing from a prior
style assignment in artifact-tool 2.8.22. Set only the paragraph property on a
text range after assigning the runs:

```js
shape.text.style = {
  fontSize: ptToPx(TYPE_PT.body),
  typeface: "Source Han Sans SC Medium",
  autoFit: "none",
};
shape.text.set(paragraphs);
for (const sourceLine of sourceLines) {
  const visibleLine = sourceLine.replace(/\*([^*]+)\*/g, "$1");
  if (visibleLine) shape.text.get(visibleLine).lineSpacing = 1.13;
}
```

Range lookups must use the final visible string. If the builder's source text
contains markup tokens that are removed when runs are constructed, looking up
the marked-up source will match nothing and paragraph properties will silently
remain at their defaults.

`lineSpacing` is serialized as DrawingML `spcPct`; it is not a CSS
`line-height` multiplier. Calibrate it from rendered baseline distances. For
example, a Typst line height near `1.38em` may require about `113%` in
PowerPoint because the Office font's normal line box is already larger than
`1em`. Confirm the emitted `a:spcPct` and the final render.

For structured runs, preserve the unit explicitly:

```js
shape.text.set([
  {
    run: "native point-sized text",
    textStyle: { fontSize: `${TYPE_PT.body}pt` },
  },
]);
```

Use the same exact conversion for every numeric pixel-only font-size field,
including chart and table styles:

```js
chartStyle.fontSize = ptToPx(TYPE_PT.body);
```

Do not trust a point-named setter until a one-shape export proves the final
DrawingML `sz`. Artifact-tool versions may accept `fontSizePt` in an input
object yet omit it from serialized shape text. The verified fallbacks are exact
numeric pixel conversion for whole-shape styles and `"Npt"` strings for runs.

Never tune font size to repair wrapping. Match the source font family, weight,
fallback, mixed-script runs, line spacing, text-box bounds, insets, and authored
line breaks first. Record every intentional source size in the typography
manifest rather than introducing an untracked fit override.

Select actual font faces, not only family names. Typst commonly emits Inter
Medium and Source Han Sans SC Medium for body text while bold roles use their
Bold faces. A Regular fallback can change both color density and wrapping even
when `sz` is exact.

Typst may enable OpenType features such as Source Han's `halt`, which changes
CJK punctuation advances. PowerPoint does not expose every shaping feature.
Keep punctuation with the preceding run, remove accidental authoring spaces,
and adjust text-box geometry before considering a different glyph. Do not
change the nominal font size to hide this shaping difference.

For single-line labels that are wider in PowerPoint, keep `autoFit: "none"`
and use a separate, deliberately wider editable text box over the fixed visual
band. Never use shrink-to-fit to preserve a one-line source label.

## Source Manifest

Generate the deck-wide allowlist from the current conversion's scratch profile
instead of writing it by hand:

```bash
python <this-skill-dir>/scripts/make_typography_policy.py \
  --profile <scratch>/theme-profile.json --aspect <deck-aspect> \
  --output <scratch>/typography-policy.json
```

It emits this shape (16:9 lemonade values shown; module-derived sizes go in
via `--extra-size`, see lemonade-calibration.md):

```json
{
  "allowed_point_sizes": [18, 20, 26, 28, 34, 36, 40, 44, 46],
  "tolerance_pt": 0.01,
  "require_explicit_size": true,
  "forbid_autofit": true
}
```

For stronger role-level verification, give generated objects stable names and
add targeted expectations:

```json
{
  "tolerance_pt": 0.01,
  "require_explicit_size": true,
  "forbid_autofit": true,
  "expectations": [
    {
      "slide": 3,
      "object_name_regex": "^slide-title-",
      "text_contains": "研究背景",
      "point_size": 40
    },
    {
      "slide": 1,
      "object_name": "title-date",
      "point_sizes": [28, 34]
    }
  ]
}
```

An expectation selects visible runs by slide plus exact object name, object-name
regular expression, and/or paragraph substring. Its effective run-size set must
match `point_size` or `point_sizes`.

## Acceptance Gate

Run after exporting the actual PPTX:

```bash
python <this-skill-dir>/scripts/audit_pptx_typography.py \
  <output.pptx> --policy <scratch/typography-policy.json>
```

The audit resolves run, paragraph, and list-level DrawingML sizes. It fails
unexpected sizes, missing explicit sizes, targeted role mismatches, and enabled
AutoFit according to policy. Exit codes are `0` pass, `1` policy failure, and
`2` input/package/policy error.

Nominal point equality is necessary but not sufficient for pixel equality.
Render the final PPTX beside the Typst PDF because font substitution and
different shaping engines can still change glyph metrics and line breaks.
For cross-machine fidelity, disclose the required font files or embed fonts
with a supported PowerPoint workflow; an ordinary generated PPTX does not make
missing local fonts portable by itself.
