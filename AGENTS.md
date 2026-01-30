# Slides theme (Typst)

- Entry: `lecture.typ` (re-exports `theme/lecture.typ`)
- Shared config: `theme/base.typ` (font sizes, page spacing, colors/fonts + runtime state)
- Aspect-specific: `theme/slide.typ` (slide margins), `theme/title.typ` (title/thanks margins), `theme/footer.typ` (footer size), `theme/outline.typ` (outline layout)
- Feature config blocks: `theme/boxes.typ` (boxes + `tbox`), `theme/images.typ`, `theme/footer.typ`, `theme/outline.typ`, `theme/slide.typ`, `theme/title.typ`, `theme/thank-you.typ`
- Validate: `typst compile tao.typ /tmp/tao_refactor.pdf`
