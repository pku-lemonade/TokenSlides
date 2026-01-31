# Slides theme (Typst)

- Entry: `lemonade.typ` (re-exports `theme/lemonade.typ`)
- Compat: `lecture.typ` (re-exports `lemonade.typ`)
- `theme/lemonade.typ`: main theme wrapper; wires Touying config + global `set/show` rules
- `theme/base.typ`: global knobs (font sizes, spacing, colors/fonts, mode choices) + runtime state (`cur-ar`, `cur-colors`, `cur-box`)
- `theme/slide.typ`: default slide template + slide margins (`slide-layouts`)
- `theme/title.typ`: title slide template + title/thanks margins (`title-layouts`)
- `theme/thank-you.typ`: thank-you slide template (uses `title-layouts`)
- `theme/footer.typ`: footer layouts + footer renderer (`footer`)
- `theme/outline.typ`: outline slide + outline layout + numbering/title config
- `theme/boxes.typ`: box helpers (`hbox/ibox/.../cbox`) + `tbox`
- `theme/images.typ`: assets + `place-image` helpers + `imgs`
- `theme/table.typ`: table styling (`apply-table-style`)
- Validate: `typst compile --root . examples/<file>.typ /tmp/out.pdf`
- API lookup: when unsure about Typst/Touying APIs, use Context7 + web search; also inspect local package sources under `~/Library/Caches/typst/packages/preview/` (e.g. `touying/0.6.1/src`)
