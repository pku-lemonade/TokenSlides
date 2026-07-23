# Slides theme (Typst)

IMPORTANT: When unsure about Typst/Touying APIs, always use Context7 + web search.

- Entry: `lemonade.typ` (re-exports `theme/lemonade.typ`)
- `theme/lemonade.typ`: main theme wrapper; wires Touying config + global `set/show` rules
- `theme/base.typ`: global knobs (`layout-config` = per-aspect font sizes/spacing/margins/page size, `font-config`, `accent-config`, `mode-config`) + runtime state (`cur-ar`, `cur-mode`, `cur-colors`, `cur-box`)
- `theme/slide.typ`: default slide template
- `theme/title.typ`: title slide template (`title-config`)
- `theme/thank-you.typ`: thank-you slide template (`thank-you-config`)
- `theme/footer.typ`: footer config + footer renderer (`footer`)
- `theme/outline.typ`: outline slide + outline layout + numbering/title config
- `theme/boxes.typ`: box helpers (`hbox/ibox/.../cbox`) + `tbox`
- `theme/images.typ`: uniform `place-xx` family (`place-image` + `place-logo`/`place-qr` presets, same API) + `imgs`
- `theme/assets.typ`: common figures as exported path values (`pku-logo`, `thu-logo`, `nsfc-logo`, `lemonade-qr`; files under `assets/logos/`, `assets/qr/`; values optionally per-mode `(light:, dark:)` resolved by `place-xx`)
- `theme/table.typ`: table styling (`apply-table-style`)
- Validate: `typst compile --root . examples/<file>.typ /tmp/out.pdf`

## Config convention

Every user-tweakable style dict is a top-level `#let <feature>-config` in the module it styles (e.g. `slide-config`, `box-config`, `footer-config`; base.typ holds the global `layout-config`, `font-config`, `accent-config`, `mode-config`). Structure inside a config:

- flat keys for aspect-independent knobs;
- aspect-ratio variants (`"16-9"` / `"4-3"`) under a `layouts:` key (see `footer-config.layouts`);
- related knob groups as nested sub-dicts (see `title-config.han`).

Unsuffixed dicts (`light-colors`, `outline-titles`) are internal building blocks or content tables. The `-config` suffix is a machine contract: export tooling (e.g. the `convert-typst-to-editable-pptx` skill) scans `theme/*.typ` for top-level `#let <name>-config` to build its design-system profile, so keep the suffix when adding or renaming a config and fold new user-facing knobs into the module's `-config` instead of adding unsuffixed dicts.

Generated design-system profiles are disposable build artifacts. Conversion tooling must write them to the task's external scratch directory with an explicit `--output`; do not add or update a profile snapshot under `.agents/skills/*/references/`.
