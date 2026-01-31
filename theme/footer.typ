#import "base.typ": fonts, cur-ar, cur-colors
#import "base.typ": utils

// CONFIG
#let footer-layouts = (
    // `height` uses `em` so it scales with `text-size` (set in the footer renderer).
    // Example: `text-size: 16pt` + `height: 1.6em` => 25.6pt tall footer.
    "16-9": (height: 1.5em, text-size: 14pt),
    "4-3": (height: 1.5em, text-size: 14pt),
)

#let footer-config = (
    fill: auto,
    text-fill: auto,
    inset: 0.3em,
    align: right,
    show-total: true,
    show-institution: true,
    show-title: true,
    show-heading: false,
)

#let _footer-inline-title(it) = {
    if type(it) == str {
        it.replace("\r\n", "").replace("\n", "").replace("\r", "")
    } else {
        {
            // Remove explicit line/paragraph breaks so the footer title stays on one line.
            show linebreak: []
            show parbreak: []
            it
        }
    }
}

#let _footer-bar(self, colors, footer-layout) = {
    let footer-fill = if footer-config.fill == auto { colors.footer-bg } else { footer-config.fill }
    let footer-text-fill = if footer-config.text-fill == auto { colors.footer-fg } else { footer-config.text-fill }

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

    set align(bottom)
    set text(
        size: footer-layout.text-size,
        font: fonts.mono,
        fill: footer-text-fill,
        weight: "bold",
    )
    block(
        width: 100%,
        height: footer-layout.height,
        fill: footer-fill,
    )[
        #align(horizon)[
            #block(width: 100%)[
                #grid(
                columns: (1fr, 3fr, 1fr),
                align: (left + horizon, center + horizon, right + horizon),
                inset: footer-config.inset,
                if footer-config.show-institution and inst != none { [#upper(inst)] } else { [] },
                title-cell,
                context text(size: 1em)[
                    #if footer-config.show-total {
                        [#utils.slide-counter.display() / #utils.last-slide-number]
                    } else {
                        [#utils.slide-counter.display()]
                    }
                ],
                )
            ]
        ]
    ]
}

#let _footer-page(self, colors, footer-layout) = {
    let footer-fill = if footer-config.fill == auto { none } else { footer-config.fill }
    let footer-text-fill = if footer-config.text-fill == auto { colors.fg } else { footer-config.text-fill }

    set align(bottom)
    set text(
        size: footer-layout.text-size,
        font: fonts.mono,
        fill: footer-text-fill,
        weight: "black",
    )
    block(
        width: 100%,
        height: footer-layout.height,
        fill: footer-fill,
    )[
        #align(footer-config.align + horizon)[
            #block(inset: footer-config.inset)[
                #context [
                    #if footer-config.show-total {
                        [#utils.slide-counter.display() / #utils.last-slide-number]
                    } else {
                        [#utils.slide-counter.display()]
                    }
                ]
            ]
        ]
    ]
}

// Footer renderer. Set as `config-page(footer: footer.with(style: ...))` in the theme.
#let footer(self, style: "bar") = context {
    assert(style in ("bar", "page", none))

    let aspect-ratio = cur-ar.get()
    let colors = cur-colors.get()
    let footer-layout = footer-layouts.at(aspect-ratio)

    if style == none { none }
    else if style == "page" { _footer-page(self, colors, footer-layout) }
    else { _footer-bar(self, colors, footer-layout) }
}
