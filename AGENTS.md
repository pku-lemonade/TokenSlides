# Slides theme (Typst)

- Entry: `lecture.typ` (re-exports `theme/lecture.typ`)
- Shared config: `theme/base.typ` (colors/fonts/sizes + runtime state)
- Aspect-specific: `theme/slide.typ` (slide margins), `theme/title.typ` (title/thanks margins), `theme/footer.typ` (footer size), `theme/outline.typ` (outline layout), `theme/lecture.typ` (par/math spacing)
- Feature config blocks: `theme/boxes.typ`, `theme/images.typ`, `theme/footer.typ`, `theme/outline.typ`, `theme/slide.typ`, `theme/title.typ`, `theme/thank-you.typ`
- Validate: `typst compile tao.typ /tmp/tao_refactor.pdf`
