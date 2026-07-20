#import "base.typ": cur-ar, cur-colors, font-config
#import "base.typ": utils

// CONFIG
#let footer-config = (
    // Footer geometry per aspect ratio. `height` uses `em` so it scales with
    // `text-size` (e.g. `text-size: 16pt` + `height: 1.6em` => 25.6pt tall footer).
    // The theme reserves this band as the page bottom margin (see `footer-band`
    // in lemonade.typ), so slide content can never run under the footer.
    layouts: (
        "16-9": (height: 1.2em, text-size: 16pt),
        "4-3": (height: 1.2em, text-size: 16pt),
    ),
    fill: auto,
    text-fill: auto,
    inset: 0.2em,
    show-total: true,
    show-institution: true,
    show-title: true,
    show-heading: false,
)

// Absolute height of the footer band for a given aspect ratio (0pt when the
// footer is disabled). Context-free so it can size the page bottom margin.
#let footer-band(aspect-ratio, style) = {
    if style == none {
        0pt
    } else {
        let footer-layout = footer-config.layouts.at(aspect-ratio)
        footer-layout.height.em * footer-layout.text-size + footer-layout.height.abs
    }
}

#let _footer-inline-title(it) = utils.markup-text(it, mode: "typ").replace(regex("\\s*[\\r\\n]+\\s*"), "")

// Footer renderer. Set as `config-page(footer: footer.with(style: ...))` in the theme.
#let footer(self, style: "bar") = context {
    assert(style in ("bar", "plain", "page", none))

    let aspect-ratio = cur-ar.get()
    let colors = cur-colors.get()
    let footer-layout = footer-config.layouts.at(aspect-ratio)
    let show-full-footer = style in ("bar", "plain")
    let footer-fill = if footer-config.fill == auto {
        if style == "bar" {
            if colors.footer-bg == auto { colors.primary } else { colors.footer-bg }
        } else { none }
    } else { footer-config.fill }
    let footer-text-fill = if footer-config.text-fill == auto {
        if style == "bar" { colors.footer-fg } else { colors.fg }
    } else { footer-config.text-fill }
    // Full footers get "bold"; the page-only counter renders "black" so the
    // lone number keeps presence without a footer bar behind it.
    let footer-weight = if show-full-footer { "bold" } else { "black" }
    let counter = text(size: 1em, weight: footer-weight)[
        #if footer-config.show-total {
            [#utils.slide-counter.display() / #utils.last-slide-number]
        } else {
            [#utils.slide-counter.display()]
        }
    ]

    if style == none { none } else {
        set align(bottom)
        set text(
            size: footer-layout.text-size,
            font: font-config.mono,
            fill: footer-text-fill,
            weight: footer-weight,
        )

        let content = if style == "page" {
            align(right + horizon)[
                #block(inset: footer-config.inset)[#counter]
            ]
        } else {
            let author = self.info.at("author", default: none)
            let inst = self.info.at("institution", default: none)

            let footer-title = self.info.at("short-title", default: auto)
            if footer-title == none or footer-title == auto { footer-title = self.info.title }
            footer-title = _footer-inline-title(footer-title)

            let heading = if footer-config.show-heading {
                utils.display-current-heading(level: 1, numbered: false)
            } else { none }

            let title-cell = if footer-config.show-title and heading != none {
                [#footer-title: #heading]
            } else if footer-config.show-title {
                [#footer-title]
            } else if heading != none {
                [#heading]
            } else { [] }

            let left-cell = if not footer-config.show-institution or inst == none {
                []
            } else {
                [#upper(inst)]
            }

            let center-cell = if author != none and title-cell != [] {
                [#author  #title-cell]
            } else if author != none {
                [#author]
            } else {
                title-cell
            }

            align(horizon)[
                #block(width: 100%)[
                    #grid(
                        columns: (1fr, auto, 1fr),
                        align: (left + horizon, center + horizon, right + horizon),
                        inset: footer-config.inset,
                        left-cell, center-cell, counter,
                    )
                ]
            ]
        }

        block(
            width: 100%,
            height: footer-layout.height,
            fill: footer-fill,
        )[
            #content
        ]
    }
}
