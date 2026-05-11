#import "base.typ": cur-ar, cur-colors, cur-font-sizes, fonts, is-zh-lang
#import "base.typ": config-page, touying-slide, touying-slide-wrapper, utils
#import "artifact-badges.typ": artifact-badges

// CONFIG
#let title-layouts = (
    "16-9": (top: 0em, bottom: 0em, left: 1em, right: 1em),
    "4-3": (top: 0em, bottom: 0em, left: 1em, right: 1em),
)

#let title-placement = (
    venue-dy: 2em,
    title-dy: -1em,
    metadata-dy: -2em,
)

#let title-han = (
    font: "FZFW ZhuZi GuDianS LH",
    size-delta: 8pt,
)

#let _title-date-format(lang) = {
    if is-zh-lang(lang) {
        "[year]年[month padding:none]月[day padding:none]日"
    } else {
        "[month repr:long] [day], [year]"
    }
}

#let _display-title-date(info) = {
    let date = info.at("date", default: datetime.today())
    if date == none {
        none
    } else if type(date) == datetime {
        date.display(_title-date-format(text.lang))
    } else {
        date
    }
}

#let title-slide(
    config: (:),
) = touying-slide-wrapper(self => context {
    let aspect-ratio = cur-ar.get()
    let colors = cur-colors.get()
    let font-sizes = cur-font-sizes.get()
    let margins = title-layouts.at(aspect-ratio)
    let date = _display-title-date(self.info)

    let default-config = config-page(
        footer: none,
        margin: margins,
    )

    let self = utils.merge-dicts(self, default-config, config)
    // Use `config-info(venue: ...)` for the visible venue line above the title.
    // Examples: [arXiv:2510.18586v2], [MICRO 2025], [OSDI 2025], [PKU LEMONADE Seminar].
    let display-venue = self.info.at("venue", default: none)

    let body = {
        artifact-badges(config: (aspect-ratio: aspect-ratio))
        if display-venue != none {
            place(top + center, dy: title-placement.venue-dy)[
                #text(size: font-sizes.slide-title, font: fonts.body, weight: "bold")[
                    #display-venue
                ]
            ]
        }
        place(horizon + center, dy: title-placement.title-dy)[
            #show regex("[\p{Han}]+"): set text(
                size: font-sizes.title + title-han.size-delta,
                font: fonts.body,
            )
            #text(size: font-sizes.title, weight: "bold", fill: colors.primary)[
                #self.info.title
            ]
        ]
        place(bottom + center, dy: title-placement.metadata-dy)[
            #set par(leading: 0.75em)
            #show regex("[\p{Han}]+"): set text(
                size: font-sizes.body-title + title-han.size-delta,
                font: title-han.font,
            )
            #text(size: font-sizes.body-title, font: fonts.body, weight: "medium")[
                #self.info.author
            ] \
            #text(size: font-sizes.body-title, font: fonts.body, weight: "medium")[
                #self.info.institution
            ] \
            #text(size: font-sizes.body-title, font: fonts.body, weight: "medium")[
                #if date != none { date } else { hide[placeholder] }
            ]
        ]
    }

    touying-slide(self: self, body)
})
