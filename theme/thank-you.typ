#import "base.typ": font-config
#import "title.typ": title-config, title-parts, title-slide

// CONFIG
// The closing slide is the title slide with these overrides — only real
// deltas appear here; everything else (layouts, han, venue band, ...) is
// inherited from `title-config`. Nested dicts merge explicitly.
#let thank-you-config = title-config + (
    placement: title-config.placement + (bottom-dy: -1em),
    // Intentionally larger than the opening title slide; Han glyphs stay at
    // the title size.
    title: (size-delta: 12pt, han-size-delta: none),
    // Contact lines instead of the deck metadata; same slot semantics.
    bottom: title-config.bottom + (
        font: font-config.mono,
        size: "body",
        min-lines: 4,
        lines: (
            title-parts.author,
            title-parts.institution,
            title-parts.email,
            title-parts.website,
            title-parts.github,
        ),
    ),
)

// Extra content (QR codes, closing images, ...) goes in the positional body:
// `#thank-you-slide(title: ...)[ ... ]`.
#let thank-you-slide(
    title: [Thank You],
    config: (:),
    ..extras,
) = title-slide(
    config: config,
    preset: thank-you-config,
    title: title,
    extra: extras.pos().sum(default: none),
)
