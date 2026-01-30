#import "@preview/touying:0.6.1": *
#import "base.typ": fonts, font-sizes
#import "state.typ": cur-layout

// CONFIG
#let title-han = (
    font: "STHeiti",
    size-delta: 6pt,
)

#let title-slide(
    config: (:),
) = touying-slide-wrapper(self => context {
    let layout = cur-layout.get()

    let default-config = config-page(
        footer: none,
        margin: (
            top: layout.title-top-margin,
            bottom: layout.title-bottom-margin,
            left: layout.title-left-margin,
            right: layout.title-right-margin,
        ),
    )

    let self = utils.merge-dicts(self, default-config, config)

    let body = {
        align(top + center)[
            #text(size: font-sizes.body-title, font: fonts.body, weight: "bold")[
                #self.info.subtitle
            ]
        ]
        place(center + horizon)[
            #text(size: font-sizes.title, weight: "bold")[
                #self.info.title
            ]
        ]
        place(bottom + center)[
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
