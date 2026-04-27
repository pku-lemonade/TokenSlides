#import "base.typ": cur-ar, cur-colors, fonts
#import "base.typ": utils

// CONFIG
#let top-page-number-layouts = (
    "16-9": (dx: 1.25em, dy: 0em, text-size: 32pt),
    "4-3": (dx: 1em, dy: 0em, text-size: 32pt),
)

#let top-page-number-config = (
    fill: auto,
    weight: "black",
    show-total: false,
)

#let top-page-number(enabled: true) = context {
    let current-slide = utils.slide-counter.get().first()

    if not enabled or current-slide == 1 {
        none
    } else {
        let colors = cur-colors.get()
        let layout = top-page-number-layouts.at(cur-ar.get())
        let text-fill = if top-page-number-config.fill == auto {
            colors.fg
        } else { top-page-number-config.fill }
        let counter = if top-page-number-config.show-total {
            [#utils.slide-counter.display() / #utils.last-slide-number]
        } else {
            [#utils.slide-counter.display()]
        }

        place(top + right, dx: layout.dx, dy: layout.dy)[
            #text(
                size: layout.text-size,
                font: fonts.mono,
                fill: text-fill,
                weight: top-page-number-config.weight,
            )[
                #counter
            ]
        ]
    }
}
