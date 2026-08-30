#import "base.typ": font-config
#import "title.typ": han-config, title-config, title-parts, title-slide

// CONFIG
// The closing slide is the title slide with these overrides — only real
// deltas appear here; everything else (layouts, venue band, ...) is
// inherited from `title-config`. Nested dicts merge explicitly.
#let thank-you-config = (
    title-config
        + (
            placement: title-config.placement + (bottom-dy: -1em),
            // Intentionally larger than the opening title slide; Han glyphs stay at
            // the title size.
            title: (size-delta: 6pt, han-size-delta: none),
            // Contact lines instead of the deck metadata; same slot semantics.
            bottom: title-config.bottom
                + (
                    font: font-config.mono,
                    size: "body",
                    // Han author/contact text is 6pt larger than its Latin base.
                    han-size-delta: 6pt,
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
)

// Extra content (QR codes, closing images, ...) goes in the positional body:
// `#thank-you-slide(title: ...)[ ... ]`.
#let thank-you-slide(
    title: [Thank You],
    config: (:),
    han: han-config,
    ..extras,
) = title-slide(
    config: config,
    preset: thank-you-config,
    han: han,
    title: title,
    extra: extras.pos().sum(default: none),
)
