#import "base.typ": font-sizes, cur-colors, cur-title-align, bleed
#import "base.typ": touying-slide-wrapper, touying-slide, utils

#let slide-config = (
    show-numbered-heading: false,
    title-tracking: 0.05em,
    title-body-gap: 0.1em,
)

#let slide(
    config: (:),
    title: auto,
    body,
) = touying-slide-wrapper(self => context {
    let colors = cur-colors.get()
    let title-align = cur-title-align.get()
    let title-x-align = if title-align == "center" { center } else { left }
    let heading-title = utils.display-current-heading(
        level: 2,
        numbered: slide-config.show-numbered-heading,
    )
    let display-title = if title != auto { title } else { heading-title }
    let title-text = text(
        size: font-sizes.slide-title,
        weight: "bold",
        tracking: slide-config.title-tracking,
        fill: colors.primary,
    )[
        #display-title
    ]
    let title-wrap = if title-align == "center" {
        // Full-bleed title: center across the whole page width (ignore page margins).
        body => bleed(align(center)[#body])
    } else {
        // Respect margins for non-centered titles.
        body => block(width: 100%)[
            #align(title-x-align)[#body]
        ]
    }

    let title-block = title-wrap(title-text)

    let main-body = {
        title-block
        v(slide-config.title-body-gap)
        body
    }

    touying-slide(self: self, config: config, main-body)
})
