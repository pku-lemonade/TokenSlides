#import "base.typ": font-sizes, cur-colors, bleed
#import "base.typ": touying-slide-wrapper, touying-slide, utils

#let slide-config = (
    show-numbered-heading: false,
    title-align: center,
    title-tracking: 0.05em,
)

#let slide(
    config: (:),
    title: auto,
    body,
) = touying-slide-wrapper(self => context {
    let colors = cur-colors.get()
    let heading-title = utils.display-current-heading(
        level: 2,
        numbered: slide-config.show-numbered-heading,
    )
    let display-title = if title != auto { title } else { heading-title }

    let title-block = if slide-config.title-align == center {
        // Full-bleed title: center across the whole page width (ignore page margins).
        bleed(align(center)[
            #text(size: font-sizes.slide-title, weight: "bold", tracking: slide-config.title-tracking, fill: colors.primary)[
                #display-title
            ]
        ])
    } else {
        // Respect margins for non-centered titles.
        block(width: 100%)[
            #align(slide-config.title-align)[
                #text(size: font-sizes.slide-title, weight: "bold", tracking: slide-config.title-tracking)[
                    #display-title
                ]
            ]
        ]
    }

    let main-body = {
        title-block
        body
    }

    touying-slide(self: self, config: config, main-body)
})
