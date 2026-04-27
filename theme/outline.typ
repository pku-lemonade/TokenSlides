#import "base.typ": cur-ar, cur-colors, font-sizes, fonts, is-zh-lang
#import "base.typ": components, touying-slide, touying-slide-wrapper, utils

// CONFIG
//
// Override the i18n outline title for specific languages. (Defaults to Touying's i18n.)
#let outline-titles = (
    zh: "提纲",
)

#let outline-title = context {
    outline-titles.at(text.lang, default: utils.i18n-outline-title)
}

// Tighten the full-width `、` so Chinese outline numbers sit close to the title.
#let outline-zh-numbering = (..nums) => numbering("一、", ..nums) + h(-0.6em)

#let outline-numbering-styles = (
    // Arabic digits: 1. 2. 3.
    en: ("1.",),
    // Chinese: 一、 二、 三、
    zh: (outline-zh-numbering,),
)

#let outline-layouts = (
    "16-9": (
        width: 100%,
        variants: (
            sections: (indent: (0em,), spacing: (6pt,)),
            subsections: (indent: (0em, 1em), spacing: (0em, 0em)),
        ),
    ),
    "4-3": (
        width: 70%,
        variants: (
            sections: (indent: (0em,), spacing: (1em,)),
            subsections: (indent: (0em, 1em), spacing: (0em, 0em)),
        ),
    ),
)

#let outline-config = (
    title: outline-title,
    default-variant: "sections",
    alpha: 20%,
    entry-tracking: 0.1em,
    number-title-gap: 0em,
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

#let _array-at(arr, idx) = arr.at(idx, default: arr.last())

#let _centered-progressive-outline(
    self: none,
    alpha: 60%,
    level: auto,
    numbered: (false,),
    numbering-patterns: (),
    text-size: none,
    text-weight: none,
    number-title-gap: 0em,
    vspace: none,
    indent: (0em,),
    depth: 1,
    short-heading: true,
    colors: (:),
    highlight-current: false,
) = context {
    let start-page = 1
    let end-page = calc.inf
    if level != none {
        let current-heading = utils.current-heading(level: level)
        if current-heading != none {
            start-page = current-heading.location().page()
            if level != auto {
                let next-headings = query(
                    selector(heading.where(level: level)).after(inclusive: false, current-heading.location()),
                )
                if next-headings != () {
                    end-page = next-headings.at(0).location().page()
                }
            } else {
                end-page = start-page + 1
            }
        }
    }

    let entries = ()
    for item in query(heading) {
        if item.level <= depth {
            entries.push(item)
        }
    }

    let entry-size = item => {
        if type(text-size) == array and text-size.len() > 0 {
            _array-at(text-size, item.level - 1)
        } else { font-sizes.body }
    }
    let entry-weight = item => _array-at(text-weight, item.level - 1)
    let with-entry-text = (item, fill: auto, body) => {
        set text(size: entry-size(item))
        set text(weight: entry-weight(item)) if type(text-weight) == array and text-weight.len() > 0
        set text(fill: fill) if fill != auto
        body
    }
    let entry-fill = item => {
        let covered = item.location().page() < start-page or item.location().page() >= end-page
        let base-fill = if highlight-current and not covered { colors.primary } else { colors.fg }
        if covered { utils.update-alpha(base-fill, alpha) } else { base-fill }
    }

    let number-body = item => {
        if _array-at(numbered, item.level - 1) {
            let current-numbering = numbering-patterns.at(item.level - 1, default: item.numbering)
            if current-numbering != none {
                numbering(current-numbering, ..counter(heading).at(item.location()))
            }
        }
    }

    let number-measure-body = item => with-entry-text(item)[#number-body(item)]

    let number-col-width = 0pt
    for item in entries {
        number-col-width = calc.max(number-col-width, measure(number-measure-body(item)).width)
    }

    let render-entry = item => {
        let size = entry-size(item)
        let number-width = measure(number-measure-body(item)).width
        box(height: size * 1.35)[
            #align(left + horizon)[
                #h(range(1, item.level + 1).map(level => _array-at(indent, level - 1)).sum())
                #with-entry-text(item, fill: entry-fill(item))[
                    #number-body(item)
                    #h(calc.max(0pt, number-col-width - number-width + number-title-gap))
                    #link(
                        item.location(),
                        if short-heading {
                            utils.short-heading(self: self, item)
                        } else {
                            item.body
                        },
                    )
                ]
            ]
        ]
    }

    let row-gutter = if type(vspace) == array and vspace.len() > 0 {
        vspace.at(0)
    } else { 0pt }

    grid(
        columns: (auto,),
        row-gutter: row-gutter,
        align: left,
        ..entries.map(render-entry),
    )
}

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
        if is-zh-lang(text.lang) { "zh" } else { "en" }
    }
    let outline-numbering = outline-config.numbering-styles.at(numbering-style)
    let highlight-current = level != none

    let outline-content = {
        let cont = _centered-progressive-outline(
            self: self,
            level: level,
            alpha: outline-config.alpha,
            indent: variant-layout.indent,
            vspace: variant-layout.spacing,
            numbered: (numbered,),
            numbering-patterns: outline-numbering,
            number-title-gap: outline-config.number-title-gap,
            colors: colors,
            highlight-current: highlight-current,
            depth: variant-config.depth,
            text-size: variant-config.text-size,
            text-weight: ("black",),
        )

        if outline-config.entry-tracking != none {
            set text(font: fonts.mono, tracking: outline-config.entry-tracking)
            cont
        } else {
            set text(font: fonts.mono)
            cont
        }
    }

    let main-body = {
        align(center)[
            #text(size: font-sizes.title, font: fonts.mono, weight: "black")[#title]
        ]
        if variant-config.use-columns {
            align(center)[
                block(width: outline-width, inset: (bottom: 1.5em))[
                #components.adaptive-columns(outline-content)
                ]
            ]
        } else {
            place(center + horizon)[
                #outline-content
            ]
        }
    }

    touying-slide(self: self, config: config, main-body)
})
