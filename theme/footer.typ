#import "base.typ": font-config, info-part, layout-of, merge-config, resolve-parts, theme
#import "base.typ": utils

#let _footer-inline-title(it) = utils.markup-text(it, mode: "typ").replace(regex("\\s*[\\r\\n]+\\s*"), "")

// PARTS
// Building blocks for footer slots. Each part is `self => content`, returning
// `none` when the underlying info is absent so empty parts drop out of the
// slot join instead of leaving stray separators.
#let _institution(self) = {
    let inst = self.info.at("institution", default: none)
    if inst != none { upper(inst) }
}

#let _author = info-part("author")

#let _title(self) = {
    let title = self.info.at("short-title", default: auto)
    if title == none or title == auto { title = self.info.at("title", default: none) }
    if title != none { _footer-inline-title(title) }
}

#let _heading(self) = utils.display-current-heading(level: 1, numbered: false)

#let _title-with-heading(self) = {
    let title = _title(self)
    let heading = _heading(self)
    if title != none and heading != none { [#title: #heading] } else if title != none { title } else { heading }
}

#let _counter(self) = [#utils.slide-counter.display() / #utils.last-slide-number]

#let _page(self) = utils.slide-counter.display()

#let footer-parts = (
    institution: _institution,
    author: _author,
    title: _title,
    heading: _heading,
    title-with-heading: _title-with-heading,
    counter: _counter,
    page: _page,
)

// CONFIG
#let footer-config = (
    // Footer geometry per aspect ratio. `height` uses `em` so it scales with
    // `text-size` (e.g. `text-size: 16pt` + `height: 1.6em` => 25.6pt tall footer).
    // The theme reserves this band as the page bottom margin (`footer-band`
    // below, read by lemonade.typ), so slide content can never run under it.
    layouts: (
        "16-9": (height: 1.2em, text-size: 16pt),
        "4-3": (height: 1.2em, text-size: 16pt),
    ),
    // Band visuals: "bar" fills the band with the footer/primary color, "plain"
    // renders text directly on the slide background. `auto` fills derive from
    // the mode colors.
    style: "bar",
    fill: auto,
    text-fill: auto,
    weight: "bold",
    inset: 0.2em,
    // Slot content: a part (`self => content`), literal content (strings
    // included), or an array of those rendered in order. Parts resolving to
    // `none` drop out; literals always render. `none` leaves the slot empty.
    left: footer-parts.institution,
    middle: (footer-parts.author, " ", footer-parts.title),
    right: footer-parts.counter,
)

// Named slot arrangements, merged over `footer-config` by `resolve-footer`.
// Decks can also start from one explicitly: `footer-presets.page + (left: ...)`.
#let footer-presets = (
    bar: (style: "bar"),
    plain: (style: "plain"),
    // Lone page number without a footer bar behind it; "black" keeps the
    // number's presence that the full footers get from the bar/"bold" combo.
    page: (style: "plain", weight: "black", left: none, middle: none, right: footer-parts.page),
)

// Resolve the theme-level `footer:` argument (preset name, override dict, or
// `none`) into a full config dict merged over `footer-config`.
#let resolve-footer(footer) = {
    if footer == none { return none }
    let overrides = if type(footer) == str {
        assert(footer in footer-presets, message: "unknown footer preset: " + footer)
        footer-presets.at(footer)
    } else {
        assert(type(footer) == dictionary, message: "footer must be none, a preset name, or a config dictionary")
        footer
    }
    let config = merge-config("footer", footer-config, overrides)
    assert(config.style in ("bar", "plain"), message: "footer style must be \"bar\" or \"plain\"")
    config
}

// Absolute height of the footer band for a resolved config (0pt when the
// footer is disabled). Context-free so it can size the page bottom margin.
#let footer-band(aspect-ratio, config) = {
    if config == none {
        0pt
    } else {
        let footer-layout = config.layouts.at(aspect-ratio)
        footer-layout.height.em * footer-layout.text-size + footer-layout.height.abs
    }
}

// A slot's resolved parts concatenate; absence needs no case analysis here.
#let _render-slot(slot, self) = {
    let rendered = resolve-parts(slot, self)
    if rendered.len() == 0 { [] } else { rendered.join() }
}

// Footer renderer. Set as `config-page(footer: footer.with(config: ...))` with
// a config from `resolve-footer` in the theme.
#let footer(self, config: footer-config) = context {
    let colors = theme().colors
    let footer-layout = layout-of(config)
    let footer-fill = if config.fill == auto {
        if config.style == "bar" {
            if colors.footer-bg == auto { colors.primary } else { colors.footer-bg }
        } else { none }
    } else { config.fill }
    let footer-text-fill = if config.text-fill == auto {
        if config.style == "bar" { colors.footer-fg } else { colors.fg }
    } else { config.text-fill }

    set align(bottom)
    set text(
        size: footer-layout.text-size,
        font: font-config.mono,
        fill: footer-text-fill,
        weight: config.weight,
    )

    block(
        width: 100%,
        height: footer-layout.height,
        fill: footer-fill,
    )[
        #align(horizon)[
            #block(width: 100%)[
                #grid(
                    columns: (1fr, auto, 1fr),
                    align: (left + horizon, center + horizon, right + horizon),
                    inset: config.inset,
                    _render-slot(config.left, self),
                    _render-slot(config.middle, self),
                    _render-slot(config.right, self),
                )
            ]
        ]
    ]
}
