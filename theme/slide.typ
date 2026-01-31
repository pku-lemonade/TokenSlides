#import "@preview/touying:0.6.1": *
#import "base.typ": font-sizes, slide-layouts, cur-ar

#let slide-config = (
    show-numbered-heading: false,
    title-align: center,
    // Add spacing after title; set to `none` and use `v(...)` in slide bodies for full control.
    title-gap: none,
)

#let slide(
    config: (:),
    title: auto,
    body,
) = touying-slide-wrapper(self => context {
    let heading-title = utils.display-current-heading(
        level: 2,
        numbered: slide-config.show-numbered-heading,
    )
    let display-title = if title != auto { title } else { heading-title }
    let margins = slide-layouts.at(cur-ar.get())

    let title-block = if slide-config.title-align == center {
        // Full-bleed title: center across the whole page width (ignore page margins).
        move(dx: -margins.left)[
            block(width: 100% + margins.left + margins.right)[
                #align(center)[
                    #text(size: font-sizes.slide-title, weight: "bold")[
                        #display-title
                    ]
                ]
            ]
        ]
    } else {
        // Respect margins for non-centered titles.
        block(width: 100%)[
            #align(slide-config.title-align)[
                #text(size: font-sizes.slide-title, weight: "bold")[
                    #display-title
                ]
            ]
        ]
    }

    let main-body = {
        title-block
        if slide-config.title-gap != none { v(slide-config.title-gap) }
        body
    }

    touying-slide(self: self, config: config, main-body)
})
