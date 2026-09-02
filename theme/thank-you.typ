#import "title.typ": han-config, title-config, title-parts, title-slide

// CONFIG
// The closing slide inherits the title slide's metadata layout and typography.
// Only the larger closing title and contact-oriented line set differ.
#let thank-you-config = (
    title-config
        + (
            // Intentionally larger than the opening title slide; Han glyphs stay at
            // the title size.
            title: (size-delta: 6pt, han-size-delta: none),
            // Contact lines instead of the deck metadata; same slot semantics.
            bottom: title-config.bottom
                + (
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
