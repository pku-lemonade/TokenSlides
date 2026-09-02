// How `_emph_` / `*strong*` render. The theme applies it globally with the
// primary accent on `*strong*`; filled surfaces (box title bars, callouts,
// vtable cells) re-apply it with fills that stay readable there.

#import "base.typ": theme

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
    let colors = theme().colors
    apply-emph-style(body, emph-fill: colors.secondary, strong-fill: colors.secondary)
}
