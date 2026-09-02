#import "base.typ": font-config, layout-of, theme
#import "base.typ": utils

// CONFIG
#let page-number-config = (
    // Placement per aspect ratio; `text-size: auto` uses the `page-number` font size.
    layouts: (
        "16-9": (dx: 0.75em, dy: 0.1em, text-size: auto),
        "4-3": (dx: 0.75em, dy: 0em, text-size: auto),
    ),
    fill: auto,
    weight: "black",
    show-total: false,
)

#let top-page-number(enabled: true) = context {
    let current-slide = utils.slide-counter.get().first()

    if not enabled or current-slide == 1 {
        none
    } else {
        let (colors, font-sizes) = theme()
        let layout = layout-of(page-number-config)
        let text-size = if layout.text-size == auto { font-sizes.page-number } else { layout.text-size }
        let text-fill = if page-number-config.fill == auto {
            colors.fg
        } else { page-number-config.fill }
        let counter = if page-number-config.show-total {
            [#utils.slide-counter.display() / #utils.last-slide-number]
        } else {
            [#utils.slide-counter.display()]
        }

        place(top + right, dx: layout.dx, dy: layout.dy)[
            #text(
                size: text-size,
                font: font-config.mono,
                fill: text-fill,
                weight: page-number-config.weight,
            )[
                #counter
            ]
        ]
    }
}
