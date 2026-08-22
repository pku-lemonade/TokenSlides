# Lemonade Calibration (profile-version 1)

Persisted empirical constants for converting lemonade-theme decks. These are
facts that cannot be derived from `theme-profile.json` — they came from render
comparisons and OOXML smoke tests. Read this before re-deriving any of them;
update this file (and only then the conversion) when a render check disagrees.

## Geometry contract

- `layout-config.<aspect>.page-size` equals PowerPoint's standard canvas
  (13.333in x 7.5in / 10in x 7.5in), so Typst point coordinates map 1:1 to
  PowerPoint points. Do not rescale geometry.
- `em` values in the profile resolve against the current text size. At slide
  body level that is `layout-config.<aspect>.font-sizes.body`. Page-margin
  `em` values should match the same base, but confirm against the rendered
  Typst PDF before relying on it.

## Line spacing

- Typst line height near `1.38em` with Source Han Sans SC Medium body text
  renders closest to DrawingML `spcPct` **113%**. Office fonts carry a normal
  line box larger than `1em`, so never copy a Typst multiplier directly.
  Calibrate from rendered baseline distances and confirm the emitted
  `a:spcPct`.

## Font face mapping

`font-config` lists family stacks; PowerPoint needs concrete faces:

| Theme role | Typst stack + weight | PowerPoint face |
| --- | --- | --- |
| body (Latin) | Inter, medium | Inter Medium |
| body (CJK) | Source Han Sans SC, medium | Source Han Sans SC Medium |
| bold emphasis | same stacks, bold | Inter Bold / Source Han Sans SC Bold |
| code / footer / page number | Inconsolata | Inconsolata (Regular/Bold per weight) |
| title-slide CJK metadata/contact | `han-config.font`, medium | Source Han Sans SC Medium |

A Regular fallback changes color density and wrapping even when `sz` is exact.

## Sizes derived in module code (not in any config)

`make_typography_policy.py` covers `layout-config.<aspect>.font-sizes` plus
`han-config.size-delta` applied to `title` and `body-title`. These extra
sizes are hardcoded in theme modules — pass them with `--extra-size` when the
deck uses the corresponding slides:

| Source | Derived size |
| --- | --- |
| `thank-you.typ` title | `font-sizes.title + 12pt` |
| `thank-you.typ` CJK contact lines | `font-sizes.body + 6pt` |

## OpenType shaping

The theme enables `halt` (`features: ("halt",)`), which tightens CJK
punctuation advances. PowerPoint does not expose this feature: keep trailing
punctuation in the preceding run, remove accidental authoring spaces, and
compensate with text-box geometry — never with a different nominal size.

## Authoring-runtime unit pins (verify per installed version)

Observed on `@oai/artifact-tool` 2.8.22 — re-verify with a one-shape export
smoke test before trusting on any other version:

- numeric `fontSize` is CSS pixels (`pt * 96 / 72`, never rounded);
- `fontSizePt` may be accepted in input objects yet dropped at serialization;
- structured `spaceBefore` / `spaceAfter` are integer centipoints
  (`20pt` -> `2000`);
- `"Npt"` strings work for structured run `textStyle.fontSize`;
- assigning whole-shape `text.style` after `text.set(...)` erases run-level
  overrides; `text.set(...)` drops paragraph line spacing from a prior style
  assignment — reapply paragraph-only properties via text ranges afterwards.
