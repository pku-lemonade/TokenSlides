#import "@preview/touying:0.6.1": *
#import "base.typ": font-sizes

#let slide-config = (show-numbered-heading: false)

#let slide(
    config: (:),
    title: auto,
    body,
) = touying-slide-wrapper(self => {
    let heading-title = utils.display-current-heading(
        level: 2,
        numbered: slide-config.show-numbered-heading,
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
