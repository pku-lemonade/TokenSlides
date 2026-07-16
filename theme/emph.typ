// Emphasis styling.
//
// Single source of truth for how `_emph_` / `*strong*` render. The theme
// applies it globally with the primary accent on `*strong*`; surfaces with a
// primary/accent fill re-apply it with fills that stay readable there (box
// title bars via `on-primary`, callouts and vtable cells with their own
// fills). A fill of `none` keeps the surrounding text color.

#import "base.typ": cur-colors

#let _emph-text(inner, fill, weight, tracking) = {
    if tracking != none { h(tracking) }
    if fill == none {
        text(weight: weight)[#inner]
    } else {
        text(weight: weight, fill: fill)[#inner]
    }
    if tracking != none { h(tracking) }
}

#let apply-emph-style(body, emph-fill: none, strong-fill: none, weight: "black", tracking: none) = {
    show emph: it => _emph-text(it.body, emph-fill, weight, tracking)
    show strong: it => _emph-text(it.body, strong-fill, weight, tracking)
    body
}

// Content sitting on a primary/accent fill: the global `*strong*` accent
// (primary) would vanish there, so emphasis switches to the secondary color.
// Theme components apply this automatically; wrap custom filled blocks
// manually: `#block(fill: colors.primary)[#on-primary[... *text* ...]]`.
#let on-primary(body) = context {
    let colors = cur-colors.get()
    apply-emph-style(body, emph-fill: colors.secondary, strong-fill: colors.secondary)
}
