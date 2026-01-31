#import "@preview/touying:0.6.1": *
#import "base.typ": fonts, font-sizes
#import "base.typ": cur-ar

// CONFIG
#let title-layouts = (
    "16-9": (top: 0em, bottom: 2em, left: 1em, right: 1em),
    "4-3": (top: 0em, bottom: 2em, left: 1em, right: 1em),
)

#let title-han = (
    font: "FZFW ZhuZi GuDianS LH",
    size-delta: 6pt,
)

#let title-slide(
    config: (:),
) = touying-slide-wrapper(self => context {
    let aspect-ratio = cur-ar.get()
    let margins = title-layouts.at(aspect-ratio)

    let default-config = config-page(
        footer: none,
        margin: margins,
    )

    let self = utils.merge-dicts(self, default-config, config)

    let body = {
        v(2em)
        align(top + center)[
            #text(size: font-sizes.body-title, font: fonts.body, weight: "bold")[
                #self.info.subtitle
            ]
        ]
        place(horizon + center)[
            #text(size: font-sizes.title, weight: "bold")[
                #self.info.title
            ]
        ]
        align(bottom + center)[
            #set par(leading: 1em)
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
                #if self.info.date != none { self.info.date } else { hide[placeholder] }
            ]
        ]
    }

    touying-slide(self: self, body)
})
