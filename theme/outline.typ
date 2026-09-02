#import "base.typ": font-config, is-zh-lang, layout-of, theme
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
#let outline-zh-numbering = (..nums) => numbering("一、", ..nums) + h(-0.1em)

#let outline-numbering-styles = (
    // Arabic digits: 1. 2. 3.
    en: ("1.",),
    // Chinese: 一、 二、 三、
    zh: (outline-zh-numbering,),
)

#let outline-config = (
    // Outline geometry per aspect ratio.
    layouts: (
        "16-9": (
            width: 100%,
            variants: (
                sections: (indent: (0em,), spacing: 6pt),
                subsections: (indent: (0em, 1em), spacing: 0em),
            ),
        ),
        "4-3": (
            width: 70%,
            variants: (
                // 22pt = the former 1em at the 4-3 body size; pt keeps the
                // outline gutters unit-consistent with the 16-9 layout.
                sections: (indent: (0em,), spacing: 22pt),
                subsections: (indent: (0em, 1em), spacing: 0em),
            ),
        ),
    ),
    title: outline-title,
    default-variant: "sections",
    // Inactive-entry opacity. Keep >= 45%: at 44pt black weight the faded
    // entries still clear the 3:1 large-text contrast floor in both modes
    // (light #8c8c8c ~3.2:1, dark #727272 ~3.8:1) while reading clearly dimmer.
    alpha: 45%,
    entry-tracking: 0.1em,
    entry-weight: "black",
    number-title-gap: 0em,
    numbering-style: auto,
    numbering-styles: outline-numbering-styles,
    title-weight: "black",
    variants: (
        sections: (
            depth: 1,
            text-size: ("section",),
            use-columns: false,
        ),
        subsections: (
            depth: 2,
            text-size: ("body-title", "small"),
            use-columns: true,
        ),
    ),
)

#let _array-at(arr, idx) = arr.at(idx, default: arr.last())

// The entry list: every heading down to the variant's depth at the variant's
// per-level sizes and indents, numbers right-aligned in one column. Given a
// `level`, headings outside the current section fade to `outline-config.alpha`
// and the current one takes the primary color.
#let _outline-entries(self, variant, variant-layout, numbering-patterns, level: none, numbered: true) = context {
    let (colors, font-sizes) = theme()
    // Pages covered by the current heading at `level`.
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
                if next-headings != () { end-page = next-headings.at(0).location().page() }
            } else {
                end-page = start-page + 1
            }
        }
    }
    let entries = query(heading).filter(item => item.level <= variant.depth)

    let entry-size = item => {
        let size = _array-at(variant.text-size, item.level - 1)
        if type(size) == str { font-sizes.at(size) } else { size }
    }
    let entry-fill = item => {
        let covered = item.location().page() < start-page or item.location().page() >= end-page
        let base-fill = if level != none and not covered { colors.primary } else { colors.fg }
        if covered { utils.update-alpha(base-fill, outline-config.alpha) } else { base-fill }
    }
    let number-body = item => if numbered {
        let pattern = numbering-patterns.at(item.level - 1, default: item.numbering)
        if pattern != none { numbering(pattern, ..counter(heading).at(item.location())) }
    }
    let measured-number = item => text(size: entry-size(item), weight: outline-config.entry-weight)[#number-body(item)]
    let number-col-width = entries.map(item => measure(measured-number(item)).width).fold(0pt, calc.max)

    let render-entry = item => {
        let size = entry-size(item)
        let number-width = measure(measured-number(item)).width
        box(height: size * 1.35)[
            #align(left + horizon)[
                #h(range(item.level).map(depth => _array-at(variant-layout.indent, depth)).sum())
                #text(size: size, weight: outline-config.entry-weight, fill: entry-fill(item))[
                    #number-body(item)
                    #h(calc.max(0pt, number-col-width - number-width + outline-config.number-title-gap))
                    #link(item.location(), utils.short-heading(self: self, item))
                ]
            ]
        ]
    }

    grid(columns: (auto,), row-gutter: variant-layout.spacing, align: left, ..entries.map(render-entry))
}

#let outline-slide(
    config: (:),
    title: outline-config.title,
    numbered: true,
    level: none,
    variant: auto,
    body: none,
) = touying-slide-wrapper(self => context {
    let font-sizes = theme().font-sizes
    let variant-name = if variant == auto { outline-config.default-variant } else { variant }
    let outline-layout = layout-of(outline-config)
    let variant-layout = outline-layout.variants.at(variant-name)

    let variant-config = outline-config.variants.at(variant-name)
    let outline-width = outline-layout.width
    let numbering-style = if outline-config.numbering-style == auto {
        if is-zh-lang(text.lang) { "zh" } else { "en" }
    } else {
        outline-config.numbering-style
    }
    let outline-numbering = outline-config.numbering-styles.at(numbering-style)

    let outline-content = {
        set text(font: font-config.mono, tracking: outline-config.entry-tracking)
        _outline-entries(self, variant-config, variant-layout, outline-numbering, level: level, numbered: numbered)
    }

    let main-body = {
        align(center)[
            #text(
                size: font-sizes.title,
                font: font-config.mono,
                weight: outline-config.title-weight,
            )[#title]
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
        // Preserve Touying section content such as speaker-note wrappers.
        body
    }

    touying-slide(self: self, config: config, main-body)
})
