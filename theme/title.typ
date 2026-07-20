#import "base.typ": font-config
#import "hero.typ": hero-han-font, hero-parts, hero-slide

// CONFIG
// Everything the opening title slide renders — edit here. The scaffold (band
// placement, Han handling, line padding) is shared with the thank-you slide
// in hero.typ.
#let title-config = (
    // Title-slide page margins per aspect ratio.
    layouts: (
        "16-9": (top: 0em, bottom: 0em, left: 1em, right: 1em),
        "4-3": (top: 0em, bottom: 0em, left: 1em, right: 1em),
    ),
    placement: (
        venue-dy: 2em,
        title-dy: -1em,
        bottom-dy: -2em,
    ),
    title: (size-delta: 0pt, han-size-delta: 6pt),
    // Metadata lines under the title. `lines` renders like footer slots:
    // parts resolve against the deck info, absent ones drop out, and the
    // block pads with hidden lines up to `min-lines` so its height (and the
    // title's optical center) stays stable.
    bottom: (
        font: font-config.body,
        size: "body-title",
        weight: "medium",
        leading: 0.75em,
        min-lines: 3,
        lines: (hero-parts.author, hero-parts.institution, hero-parts.date),
        han: (font: hero-han-font, size-delta: 6pt),
    ),
)

// Use `config-info(venue: ...)` for the visible venue line above the title.
// Examples: [arXiv:2510.18586v2], [MICRO 2025], [OSDI 2025], [PKU LEMONADE Seminar].
#let title-slide(config: (:)) = hero-slide(title-config, config: config)
