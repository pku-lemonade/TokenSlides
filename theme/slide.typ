#import "base.typ": bleed, theme
#import "base.typ": touying-slide, touying-slide-wrapper, utils
#import "page-number.typ": top-page-number

#let slide-config = (
    centered-title-full-bleed: true,
    show-numbered-heading: false,
    title-bottom-edge: "bounds",
    title-tracking: 0.00em,
    title-weight: "bold",
    title-body-gap: 0.5em,
)

#let slide(
    config: (:),
    title: auto,
    body,
) = touying-slide-wrapper(self => context {
    let (colors, font-sizes, title-align) = theme()
    let title-text = body => text(
        size: font-sizes.slide-title,
        weight: slide-config.title-weight,
        tracking: slide-config.title-tracking,
        bottom-edge: slide-config.title-bottom-edge,
        fill: colors.primary,
    )[
        #body
    ]
    let heading-title = utils.display-current-heading(
        level: 2,
        numbered: slide-config.show-numbered-heading,
        setting: title-text,
    )
    let display-title = if title != auto { title-text(title) } else { heading-title }
    let title-wrap = if title-align == center and slide-config.centered-title-full-bleed {
        // Full-bleed title: center across the whole page width (ignore page margins).
        body => bleed(align(center)[#body])
    } else {
        // Respect margins for non-centered titles.
        body => block(width: 100%)[
            #align(title-align)[#body]
        ]
    }

    let title-block = title-wrap(display-title)

    let main-body = {
        title-block
        v(slide-config.title-body-gap)
        block(above: 0pt, below: 0pt)[
            #body
        ]
        top-page-number()
    }

    touying-slide(self: self, config: config, main-body)
})
