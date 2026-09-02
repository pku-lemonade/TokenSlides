#import "/lemonade.typ": *

// Deck-level theme knobs: dark mode, an accent override, filled boxes, the
// bare page-number footer, callouts, and emphasis on a primary fill.

#show: lemonade-theme.with(
    aspect-ratio: "16-9",
    mode: "dark",
    // Any key of the mode's color dict; `accent-config` holds the named accents.
    colors-override: (primary: accent-config.california-gold, link: accent-config.california-gold),
    // Soft body fills for every box; `box-compact` tightens body insets deck-wide.
    box-fill: true,
    box-compact: false,
    footer: "page",
    title: [Theme Knobs],
    author: [Lemonade],
    institution: [Theme Reference],
)

#title-slide()

= Colors and boxes

== Mode and accent override

This deck runs `mode: "dark"` with the primary accent overridden to gold.
Links such as https://github.com/pku-lemonade take the `link` color.

#vboxs(
    hbox([Highlight])[Body fills come from `dark-box-styles` when `box-fill` is on.],
    ibox([Info])[*Strong* text in a body keeps the primary accent.],
    sbox([Success])[Per-box `compact: true` tightens one box only.],
)

== Compact versus normal insets

#vboxs(
    nbox([Deck default])[This deck sets `box-compact: false`, so bodies get the normal inset.],
    nbox([Compact], compact: true)[The same box with `compact: true`.],
)

= Callouts

== The callout family

#callout[`callout`: the mode's brightest surface; *strong* takes the primary accent.]

#bcallout[`bcallout`: the fixed blue banner, mode-independent.]

#rcallout[`rcallout`: filled with the primary accent; *strong* switches to the secondary color.]

== A custom callout

`color:` takes a style dict merged over the white style; `config:` overrides
any `callout-config` key.

#callout(
    color: (fill: rgb("#264653"), text-fill: white, emph-fill: rgb("#e9c46a")),
    config: (width: 80%, shadow: false),
)[Custom fill, 80% wide, *no shadow*.]

== Emphasis on a primary fill

Theme components apply `on-primary` themselves. Wrap your own filled blocks:

#context {
    let colors = theme().colors
    block(width: 100%, fill: colors.primary, inset: 0.6em)[
        #on-primary[On a primary fill, *strong* and _emph_ switch to the secondary color.]
    ]
}
