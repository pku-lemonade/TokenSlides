#import "base.typ": cur-ar, cur-colors, cur-font-sizes, font-config
#import "base.typ": config-page, touying-slide, touying-slide-wrapper, utils
#import "artifact-badges.typ": artifact-badges

// CONFIG
#let thank-you-config = (
    // Thank-you-slide page margins per aspect ratio.
    layouts: (
        "16-9": (top: 0em, bottom: 0em, left: 1em, right: 1em),
        "4-3": (top: 0em, bottom: 0em, left: 1em, right: 1em),
    ),
    min-contact-lines: 2,
    leading: 0.75em,
    // Intentionally larger than the opening title slide.
    title-size-delta: 12pt,
    placement: (
        venue-dy: 2em,
        title-dy: -1em,
        contact-dy: -1em,
    ),
    // CJK face tweaks for the contact block. The decorative face is not
    // vendored with the repo — without it installed, Typst falls back to the
    // body CJK font.
    han: (font: "FZFW ZhuZi GuDianS LH", size-delta: 6pt),
)

// Extra content (QR codes, closing images, ...) goes in the positional body:
// `#thank-you-slide(title: ...)[ ... ]`.
#let thank-you-slide(
    title: [Thank You],
    config: (:),
    ..extras,
) = touying-slide-wrapper(self => context {
    let extra = extras.pos().sum(default: none)
    let aspect-ratio = cur-ar.get()
    let colors = cur-colors.get()
    let font-sizes = cur-font-sizes.get()
    let margins = thank-you-config.layouts.at(aspect-ratio)

    let default-config = config-page(
        footer: none,
        margin: margins,
    )

    let self = utils.merge-dicts(self, default-config, config)

    let display-venue = self.info.at("venue", default: none)
    let display-author = self.info.at("author", default: none)
    let display-institution = self.info.at("institution", default: none)
    let display-email = self.info.at("email", default: none)
    let display-website = self.info.at("website", default: none)
    let display-github = self.info.at("github", default: none)

    let contact-items = ()
    if display-email != none {
        contact-items.push(link("mailto:" + display-email)[#display-email])
    }
    if display-website != none {
        contact-items.push(link(display-website)[#display-website])
    }
    if display-github != none {
        contact-items.push(link("https://github.com/" + display-github)[github.com/#display-github])
    }

    let display-contact-items = contact-items
    let reserved-contact-lines = calc.max(contact-items.len(), thank-you-config.min-contact-lines)
    for _ in range(reserved-contact-lines - contact-items.len()) {
        display-contact-items.push(hide[placeholder])
    }

    let body = {
        artifact-badges(config: (aspect-ratio: aspect-ratio))
        if display-venue != none {
            place(top + center, dy: thank-you-config.placement.venue-dy)[
                #text(size: font-sizes.body-title, font: font-config.body, weight: "bold")[
                    #display-venue
                ]
            ]
        }
        place(horizon + center, dy: thank-you-config.placement.title-dy)[
            #show regex("[\p{Han}]+"): set text(font: font-config.body)
            #text(size: font-sizes.title + thank-you-config.title-size-delta, weight: "bold", fill: colors.primary)[#title]
        ]
        place(bottom + center, dy: thank-you-config.placement.contact-dy)[
            #set par(leading: thank-you-config.leading)
            #show regex("[\p{Han}]+"): set text(
                size: font-sizes.body + thank-you-config.han.size-delta,
                font: thank-you-config.han.font,
            )
            #text(size: font-sizes.body, font: font-config.mono, weight: "medium")[
                #if display-author != none [#display-author]
            ]\
            #text(size: font-sizes.body, font: font-config.mono, weight: "medium")[
                #if display-institution != none [#display-institution] else { hide[placeholder] }
            ]\
            #text(size: font-sizes.body, font: font-config.mono, weight: "medium")[
                #display-contact-items.join(linebreak())
            ]
        ]
        if extra != none { extra }
    }

    touying-slide(self: self, body)
})
