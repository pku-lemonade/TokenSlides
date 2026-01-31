#import "@preview/touying:0.6.1": *
#import "base.typ": font-sizes, cur-ar, cur-colors

// CONFIG
//
// Override the i18n outline title for specific languages. (Defaults to Touying's i18n.)
#let outline-titles = (
    zh: "提纲",
)

#let outline-title = context {
    outline-titles.at(text.lang, default: utils.i18n-outline-title)
}

// Cancel Touying's built-in `h(.3em)` after numbering for Chinese outlines (the `、` is full-width).
#let outline-zh-numbering = (..nums) => numbering("一、", ..nums) + h(-0.3em)

#let outline-numbering-styles = (
    // Arabic digits: 1. 2. 3.
    en: ("1.",),
    // Chinese: 一、 二、 三、
    zh: (outline-zh-numbering,),
)

#let outline-layouts = (
    "16-9": (
        width: 70%,
        variants: (
            sections: (indent: (3em,), spacing: (6pt,)),
            subsections: (indent: (0em, 1em), spacing: (0em, 0em)),
        ),
    ),
    "4-3": (
        width: 70%,
        variants: (
            sections: (indent: (3em,), spacing: (1em,)),
            subsections: (indent: (0em, 1em), spacing: (0em, 0em)),
        ),
    ),
)

#let outline-config = (
    title: outline-title,
    default-variant: "sections",
    alpha: 20%,
    entry-tracking: 0.1em,
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
    let colors = cur-colors.get()
    let variant-name = if variant == auto { outline-config.default-variant } else { variant }

    let aspect-ratio = cur-ar.get()
    let outline-layout = outline-layouts.at(aspect-ratio)
    let variant-layout = outline-layout.variants.at(variant-name)

    let variant-config = outline-config.variants.at(variant-name)
    let outline-width = outline-layout.width
    let numbering-style = if outline-config.numbering-style == auto {
        if text.lang == "zh" or text.lang.starts-with("zh-") { "zh" } else { "en" }
    }
    let outline-numbering = outline-config.numbering-styles.at(numbering-style)
    let highlight-current = level != none

    let outline-content = {
        let cont = components.custom-progressive-outline(
            level: level,
            alpha: outline-config.alpha,
            indent: variant-layout.indent,
            vspace: variant-layout.spacing,
            numbered: (numbered,),
            numbering: outline-numbering,
            uncover-fn: if highlight-current {
                body => {
                    show text: set text(fill: colors.primary)
                    body
                }
            } else {
                body => body
            },
            depth: variant-config.depth,
            text-size: variant-config.text-size,
            text-weight: ("bold",),
        )

        if outline-config.entry-tracking != none {
            set text(tracking: outline-config.entry-tracking)
            cont
        }
    }

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
