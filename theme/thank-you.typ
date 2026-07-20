#import "base.typ": font-config
#import "hero.typ": hero-han-font, hero-parts, hero-slide

// CONFIG
// Everything the closing slide renders — edit here. The scaffold (band
// placement, Han handling, line padding) is shared with the title slide in
// hero.typ.
#let thank-you-config = (
    // Thank-you-slide page margins per aspect ratio.
    layouts: (
        "16-9": (top: 0em, bottom: 0em, left: 1em, right: 1em),
        "4-3": (top: 0em, bottom: 0em, left: 1em, right: 1em),
    ),
    placement: (
        venue-dy: 2em,
        title-dy: -1em,
        bottom-dy: -1em,
    ),
    // Intentionally larger than the opening title slide; Han glyphs stay at
    // the title size (`han-size-delta: none`).
    title: (size-delta: 12pt, han-size-delta: none),
    // Contact lines at the bottom; same slot semantics as title-config.
    bottom: (
        font: font-config.mono,
        size: "body",
        weight: "medium",
        leading: 0.75em,
        min-lines: 4,
        lines: (
            hero-parts.author,
            hero-parts.institution,
            hero-parts.email,
            hero-parts.website,
            hero-parts.github,
        ),
        han: (font: hero-han-font, size-delta: 6pt),
    ),
)

// Extra content (QR codes, closing images, ...) goes in the positional body:
// `#thank-you-slide(title: ...)[ ... ]`.
#let thank-you-slide(
    title: [Thank You],
    config: (:),
    ..extras,
) = hero-slide(
    thank-you-config,
    config: config,
    title: title,
    extra: extras.pos().sum(default: none),
)
