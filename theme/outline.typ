#import "@preview/touying:0.6.1": *
#import "base.typ": font-sizes, cur-ar

// CONFIG
#let outline-numbering-styles = (
    // Arabic: 1. 2. 3.
    arabic: ("1.",),
    // Chinese: 一、 二、 三、
    chinese: ("一、",),
)

#let outline-layouts = (
    "16-9": (
        width: 70%,
        variants: (
            sections: (indent: (0em,), spacing: (1em,)),
            subsections: (indent: (0em, 1em), spacing: (0em, 0em)),
        ),
    ),
    "4-3": (
        width: 70%,
        variants: (
            sections: (indent: (4em,), spacing: (1em,)),
            subsections: (indent: (0em, 1em), spacing: (0em, 0em)),
        ),
    ),
)

#let outline-config = (
    title: utils.i18n-outline-title,
    default-variant: "sections",
    alpha: 20%,
    // When `auto`, picks a style based on `text.lang`.
    numbering-style: auto,
    numbering-styles: outline-numbering-styles,
    variants: (
        sections: (
            depth: 1,
            text-size: (font-sizes.section,),
            use-columns: false,
        ),
        subsections: (
            depth: 2,
            text-size: (font-sizes.body-title, font-sizes.small),
            use-columns: true,
        ),
    ),
)

#let outline-slide(
    config: (:),
    title: outline-config.title,
    numbered: true,
    level: none,
    variant: auto,
) = touying-slide-wrapper(self => context {
    let variant-name = if variant == auto { outline-config.default-variant } else { variant }

    let aspect-ratio = cur-ar.get()
    let outline-layout = outline-layouts.at(aspect-ratio)
    let variant-layout = outline-layout.variants.at(variant-name)

    let variant-config = outline-config.variants.at(variant-name)
    let outline-width = outline-layout.width
    let numbering-style = if outline-config.numbering-style == auto {
        let lang = text.lang
        if lang == "zh" or lang.starts-with("zh-") { "chinese" } else { "arabic" }
    } else {
        outline-config.numbering-style
    }
    let outline-numbering = outline-config.numbering-styles.at(numbering-style)

    let outline-content = components.custom-progressive-outline(
        level: level,
        alpha: outline-config.alpha,
        indent: variant-layout.indent,
        vspace: variant-layout.spacing,
        numbered: (numbered,),
        numbering: outline-numbering,
        depth: variant-config.depth,
        text-size: variant-config.text-size,
        text-weight: ("bold",),
    )

    let main-body = {
        align(center)[
            #text(size: font-sizes.title, weight: "bold")[#title]
        ]
        if variant-config.use-columns {
            align(center)[
                block(width: outline-width, inset: (bottom: 1.5em))[
                    #components.adaptive-columns(outline-content)
                ]
            ]
        } else {
            place(center + horizon)[
                #block(width: outline-width)[#outline-content]
            ]
        }
    }

    touying-slide(self: self, config: config, main-body)
})
