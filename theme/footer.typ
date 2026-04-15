#import "base.typ": fonts, is-zh-lang, cur-ar, cur-colors
#import "base.typ": utils

// CONFIG
#let footer-layouts = (
    // `height` uses `em` so it scales with `text-size` (set in the footer renderer).
    // Example: `text-size: 16pt` + `height: 1.6em` => 25.6pt tall footer.
    "16-9": (height: 1.25em, text-size: 16pt),
    "4-3": (height: 1.25em, text-size: 16pt),
)

#let footer-config = (
    fill: auto,
    text-fill: auto,
    inset: 0.3em,
    show-total: true,
    show-institution: true,
    show-title: true,
    show-heading: false,
)

#let _footer-inline-title(it) = utils.markup-text(it, mode: "typ").replace(regex("\\s*[\\r\\n]+\\s*"), "")

// Footer renderer. Set as `config-page(footer: footer.with(style: ...))` in the theme.
#let footer(self, style: "bar") = context {
    assert(style in ("bar", "page", none))

    let aspect-ratio = cur-ar.get()
    let colors = cur-colors.get()
    let footer-layout = footer-layouts.at(aspect-ratio)
    let footer-fill = if footer-config.fill == auto {
        if style == "bar" { colors.footer-bg } else { none }
    } else { footer-config.fill }
    let footer-text-fill = if footer-config.text-fill == auto {
        if style == "bar" { colors.footer-fg } else { colors.fg }
    } else { footer-config.text-fill }
    let footer-weight = if style == "bar" { "bold" } else { "black" }
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
            font: fonts.mono,
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
            } else if is-zh-lang(text.lang) {
                [#inst]
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
                    left-cell,
                    center-cell,
                    counter,
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
