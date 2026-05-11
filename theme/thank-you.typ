#import "base.typ": cur-ar, cur-colors, cur-font-sizes, fonts
#import "base.typ": config-page, touying-slide, touying-slide-wrapper, utils
#import "artifact-badges.typ": artifact-badges

// CONFIG
#let thank-you-layouts = (
    "16-9": (top: 0em, bottom: 0em, left: 1em, right: 1em),
    "4-3": (top: 0em, bottom: 0em, left: 1em, right: 1em),
)

#let thank-you-config = (
    min-contact-lines: 2,
    leading: 0.75em,
)

#let thank-you-placement = (
    venue-dy: 2em,
    title-dy: -1em,
    contact-dy: -1em,
)

#let thanks-han = (
    font: "FZFW ZhuZi GuDianS LH",
)

#let thank-you-slide(
    title: [Thank You],
    content: none,
    decoration: none,
    config: (:),
    ..extras,
) = touying-slide-wrapper(self => context {
    let extra = extras.pos().sum(default: none)
    let aspect-ratio = cur-ar.get()
    let colors = cur-colors.get()
    let font-sizes = cur-font-sizes.get()
    let margins = thank-you-layouts.at(aspect-ratio)

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
    if content != none { contact-items.push(content) }

    let display-contact-items = ()
    for item in contact-items {
        display-contact-items.push(item)
    }
    let reserved-contact-lines = calc.max(contact-items.len(), thank-you-config.min-contact-lines)
    for _ in range(reserved-contact-lines - contact-items.len()) {
        display-contact-items.push(hide[placeholder])
    }

    let body = {
        artifact-badges(config: (aspect-ratio: aspect-ratio))
        if display-venue != none {
            place(top + center, dy: thank-you-placement.venue-dy)[
                #text(size: font-sizes.slide-title, font: fonts.body, weight: "bold")[
                    #display-venue
                ]
            ]
        }
        place(horizon + center, dy: thank-you-placement.title-dy)[
            #show regex("[\p{Han}]+"): set text(font: fonts.body)
            #text(size: font-sizes.title + 12pt, weight: "bold", fill: colors.primary)[#title]
        ]
        place(bottom + center, dy: thank-you-placement.contact-dy)[
            #set par(leading: thank-you-config.leading)
            #show regex("[\p{Han}]+"): set text(
                size: font-sizes.body + 8pt,
                font: thanks-han.font,
            )
            #text(size: font-sizes.body, font: fonts.body, weight: "bold")[
                #self.info.title
            ]\
            #text(size: font-sizes.body, font: fonts.mono, weight: "medium")[
                #if display-author != none [#display-author]
            ]\
            #text(size: font-sizes.body, font: fonts.mono, weight: "medium")[
                #if display-institution != none [#display-institution] else { hide[placeholder] }
            ]\
            #text(size: font-sizes.body, font: fonts.mono, weight: "medium")[
                #display-contact-items.join(linebreak())
            ]
        ]
        if decoration != none { decoration }
        if extra != none { extra }
    }

    touying-slide(self: self, body)
})
