#import "@preview/touying:0.6.1": *
#import "base.typ": font-sizes

// CONFIG
#let slide-layouts = (
    "16-9": (top: 1.25em, bottom: 0em, left: 3em, right: 2em),
    "4-3": (top: 1.5em, bottom: 0em, left: 2em, right: 1.5em),
)

#let slide-config = (show-numbers: false)

#let slide(
    config: (:),
    title: auto,
    body,
) = touying-slide-wrapper(self => {
    let heading-title = utils.display-current-heading(
        level: 2,
        numbered: slide-config.show-numbers,
    )
    let display-title = if title != auto { title } else { heading-title }

    let main-body = {
        block(below: 1em)[
            #text(size: font-sizes.slide-title, weight: "bold")[
                #display-title
            ]
        ]
        body
    }

    touying-slide(self: self, config: config, main-body)
})
