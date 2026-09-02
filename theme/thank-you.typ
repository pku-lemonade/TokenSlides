#import "title.typ": han-config, title-config, title-parts, title-slide

// CONFIG
// The closing slide is the title slide with these deltas: a larger title whose
// Han glyphs stay at the title size, and contact lines in place of the deck
// metadata. Nested dicts merge over `title-config` so new title-config keys
// reach this slide too.
#let thank-you-config = (
    title-config
        + (
            // Intentionally larger than the opening title slide; Han glyphs stay at
            // the title size.
            title: title-config.title + (size-delta: 6pt, han-size-delta: none),
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
) = {
    // The sink takes positional extras only; a misspelt option must not vanish.
    assert(extras.named().len() == 0, message: "thank-you-slide: unknown options " + repr(extras.named().keys()))
    title-slide(
        config: config,
        preset: thank-you-config,
        han: han,
        title: title,
        extra: extras.pos().sum(default: none),
    )
}
