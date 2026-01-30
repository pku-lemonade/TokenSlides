#import "@preview/touying:0.6.1": *
#import "base.typ": font-sizes
#import "state.typ": cur-layout

// CONFIG
#let outline-config = (
    default-variant: "sections",
    alpha: 20%,
    variants: (
        sections: (
            depth: 1,
            indent: layout => (layout.outline-indent,),
            vspace: layout => (layout.outline-spacing,),
            text-size: _ => (font-sizes.section,),
            use-columns: false,
        ),
        subsections: (
            depth: 2,
            indent: _ => (0em, 1em),
            vspace: _ => (0em, 0em),
            text-size: _ => (font-sizes.body-title, font-sizes.small),
            use-columns: true,
        ),
    ),
)

#let outline-slide(
    config: (:),
    title: utils.i18n-outline-title,
    numbered: true,
    level: none,
    variant: auto,
    ..args,
) = touying-slide-wrapper(self => context {
    let chosen = if variant == auto { outline-config.default-variant } else { variant }
    assert(chosen in outline-config.variants.keys())

    let vcfg = outline-config.variants.at(chosen)
    let layout = cur-layout.get()

    let outline-width = layout.at("outline-width", default: 100%)

    let outline-content = components.custom-progressive-outline(
        level: level,
        alpha: outline-config.alpha,
        indent: (vcfg.indent)(layout),
        vspace: (vcfg.vspace)(layout),
        numbered: (numbered,),
        numbering: ("1.",),
        depth: vcfg.depth,
        text-size: (vcfg.text-size)(layout),
        text-weight: ("bold",),
        ..args.named(),
    )

    let main-body = {
        align(center)[
            #text(size: font-sizes.title, weight: "bold")[#title]
        ]
        if vcfg.use-columns {
            align(center)[
                block(width: outline-width, inset: (bottom: 1.5em))[
                    #components.adaptive-columns(outline-content)
                ]
            ]
        } else {
            place(center)[
                #block(width: outline-width)[#outline-content]
            ]
        }
    }

    touying-slide(self: self, config: config, main-body)
})

#let new-section-slide(
    config: (:),
    title: utils.i18n-outline-title,
    level: 1,
    numbered: true,
    variant: auto,
    ..args,
) = outline-slide(
    config: config,
    title: title,
    level: level,
    numbered: numbered,
    variant: variant,
    ..args,
)
