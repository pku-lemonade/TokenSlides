#import "@preview/touying:0.6.1": *
#import "@preview/theorion:0.4.0": *
#import "@preview/numbly:0.1.0": numbly
#show: show-theorion

#let light-colors = (
    bg: white,
    fg: black,
    // primary: rgb("#94070a"),
    primary: rgb("#002676"),
    secondary: rgb("#FDB515"),
    neutral: rgb("#737373"),
    neutral-lightest: white,
    neutral-darkest: black,
    table-stroke: rgb("#d4d4d4"),
    link: rgb("#2563eb"),
    footer-bg: rgb("#002676"),
    footer-fg: white,
    code-bg: rgb("#f5f5f5"),
    code-border: rgb("#d4d4d4"),
    code-fg: black,
)

// Based on the Codex CLI TUI dark theme.
#let dark-colors = (
    bg: rgb("#0D0D0D"),
    fg: rgb("#EDEDED"),
    primary: rgb("#38BDF8"),
    secondary: rgb("#FDB515"),
    neutral: rgb("#5D5D5D"),
    neutral-lightest: rgb("#EDEDED"),
    neutral-darkest: rgb("#0D0D0D"),
    table-stroke: rgb("#5D5D5D"),
    link: rgb("#38BDF8"),
    footer-bg: rgb("#002676"),
    footer-fg: rgb("#EDEDED"),
    code-bg: rgb("#0B1220"),
    code-border: rgb("#334155"),
    code-fg: rgb("#EDEDED"),
)

#let light-box-styles = (
    highlight: (fill: rgb("#fff8e1"), border: rgb("#f59e0b")),
    info: (fill: rgb("#eff6ff"), border: rgb("#3b82f6")),
    error: (fill: rgb("#fef2f2"), border: rgb("#ef4444")),
    success: (fill: rgb("#f0fdf4"), border: rgb("#22c55e")),
    neutral: (fill: rgb("#fafafa"), border: rgb("#737373")),
    purple: (fill: rgb("#f6f3ff"), border: rgb("#8b5cf6")),
)

#let dark-box-styles = (
    highlight: (fill: rgb("#0B2533"), border: dark-colors.link),
    info: (fill: rgb("#0B1220"), border: dark-colors.link),
    error: (fill: rgb("#2A0B0B"), border: rgb("#ef4444")),
    success: (fill: rgb("#0B2414"), border: rgb("#22c55e")),
    neutral: (fill: rgb("#141414"), border: dark-colors.neutral),
    purple: (fill: rgb("#1A102A"), border: rgb("#8b5cf6")),
)

#let current-colors = state("lecture-current-colors", light-colors)
#let current-box-styles = state("lecture-current-box-styles", light-box-styles)

#let resolve-theme(mode) = {
    if mode == "dark" {
        (colors: dark-colors, box-styles: dark-box-styles)
    } else {
        (colors: light-colors, box-styles: light-box-styles)
    }
}

#let fonts = (
    body: ("Inter", "Source Han Sans SC", "FZLTHProS"),
    math: "New Computer Modern Math",
    mono: ("Inconsolata", "Source Han Sans SC"),
    name: ("Inter", "FZFW ZhuZi GuDianS SH"),
)

#let font-sizes = (
    small: 18pt,
    body: 22pt,
    body-title: 26pt,
    title: 44pt,
    slide-title: 36pt,
    section: 36pt,
    code: 20pt,
)

#let box-config = (
    normal: (
        inset-left: 12pt,
        inset-right: 0em,
        inset-top: 1em,
        inset-bottom: 1em,
        box-spacing-above: 1em,
        box-spacing-below: auto,
    ),
    compact: (
        inset-left: 10pt,
        inset-right: 0em,
        inset-top: 0.5em,
        inset-bottom: 0.5em,
        box-spacing-above: 0.4em,
        box-spacing-below: auto,
    ),
    radius: 0pt,
    left-border: true,
    border-width: 4pt,
)

#let layout-16-9 = (
    footer-height: 1em,
    footer-text-size: 16pt,
    slide-top-margin: 1.25em,
    slide-bottom-margin: 0em,
    slide-left-margin: 3em,
    slide-right-margin: 2em,
    title-top-margin: 2em,
    title-bottom-margin: 2em,
    title-left-margin: 1em,
    title-right-margin: 1em,
    par-spacing: 1em,
    math-block-spacing-above: 0.8em,
    math-block-spacing-below: 0.6em,
    outline-indent: 0em,
    outline-spacing: 1em,
)

#let layout-4-3 = (
    footer-height: 1em,
    footer-text-size: 14pt,
    slide-top-margin: 1.5em,
    slide-bottom-margin: 0em,
    slide-left-margin: 2em,
    slide-right-margin: 1.5em,
    title-top-margin: 2em,
    title-bottom-margin: 2em,
    title-left-margin: 1em,
    title-right-margin: 1em,
    par-spacing: 1.1em,
    math-block-spacing-above: 1em,
    math-block-spacing-below: auto,
    outline-indent: 2em,
    outline-spacing: 1em,
)

#let heading-config = (show-numbers: false)
#let outline-config = (show-subsections: false, alpha: 20%)

#let assets = (
    logo: "assets/logo.png",
    qr-code: "assets/qr.png",
)

#let current-layout = state("current-layout", layout-16-9)

#let default-footer-config = (
    style: "bar",
    fill: auto,
    text-fill: auto,
    inset: 0.5em,
    align: right,
    show-total: true,
    show-institution: true,
    show-title: true,
    show-heading: false,
)

#let tbox(
    body,
    size: font-sizes.body-title,
    weight: "bold",
    alignment: left,
    leading: 1em,
) = {
    set par(leading: leading)
    align(alignment)[
        #text(size: size, weight: weight)[#body]
    ]
}

#let make-box(
    style-name,
    body,
    fill: auto,
    width: 100%,
    height: auto,
    inset: auto,
    radius: auto,
    above: auto,
    below: auto,
    left-border: auto,
    border-color: auto,
    border-width: auto,
    breakable: false,
    compact: false,
) = {
    context {
        let style = current-box-styles.get().at(style-name)
        let use-border = if left-border == auto { box-config.left-border } else { left-border }
        let spacing-config = if compact { box-config.compact } else { box-config.normal }
        let base-inset-left = if inset == auto { spacing-config.inset-left } else { inset }
        let base-inset-right = if inset == auto { spacing-config.inset-right } else { inset }
        let base-inset-top = if inset == auto { spacing-config.inset-top } else { inset }
        let base-inset-bottom = if inset == auto { spacing-config.inset-bottom } else { inset }

        block(
            fill: if fill == auto { style.fill } else { fill },
            breakable: breakable,
            inset: (
                left: if use-border { base-inset-left + 4pt } else { base-inset-left },
                right: base-inset-right,
                top: base-inset-top,
                bottom: base-inset-bottom,
            ),
            radius: if radius == auto { box-config.radius } else { radius },
            width: width,
            height: height,
            above: if above == auto { spacing-config.box-spacing-above } else { above },
            below: if below == auto { spacing-config.box-spacing-below } else { below },
            stroke: if use-border {
                (left: (if border-width == auto { box-config.border-width } else { border-width }) +
                             (if border-color == auto { style.border } else { border-color }))
            } else { none },
        )[#body]
    }
}

#let hbox(body, ..args) = make-box("highlight", body, ..args)
#let ibox(body, ..args) = make-box("info", body, ..args)
#let ebox(body, ..args) = make-box("error", body, ..args)
#let sbox(body, ..args) = make-box("success", body, ..args)
#let nbox(body, ..args) = make-box("neutral", body, ..args)
#let pbox(body, ..args) = make-box("purple", body, ..args)

#let cbox(body, ..args) = {
    context {
        let colors = current-colors.get()
        block(
            fill: colors.code-bg,
            radius: 0pt,
            stroke: (paint: colors.code-border, thickness: 0.8pt),
            inset: 10pt,
            ..args,
        )[
            #set text(fill: colors.code-fg)
            #body
        ]
    }
}

#let place-image(
    path,
    caption: none,
    width: 25%,
    position: top + right,
    dx: 0.5em,
    dy: 1em
) = place(position, dx: dx, dy: dy)[
    #align(center)[
        #if caption != none [
            #text(font: fonts.mono, size: font-sizes.body, weight: "medium")[#caption]
            #v(-0.8em)
        ]
        #image(path, width: width)
    ]
]

#let place-logo(..args) = place-image(assets.logo, dx: -0.5em,dy: -1em, position: top + right, ..args)
#let place-bottom-right(path, caption: none, ..args) = place-image(path, caption: caption, width: 20%, dx: -1.5em, dy: 0em, position: bottom + right)

#let place-bottom-left(path, caption: none, ..args) = place-image(path, caption: caption, width: 20%, dx: 1.5em, dy: 0em, position: bottom + left)

#let imgs(
    ..images,
    width: 100%,
    widths: auto,
    gap: 0.5em,
    valign: horizon,
    cap-size: 18pt,
    cap-weight: "medium",
    cap-color: auto,
    cap-gap: 0.2em,
    border: none,
    border-radius: 0pt,
    inset: 0pt,
) = {
    let items = images.pos()
    let count = items.len()

    let parsed = items.map(item => {
        if type(item) == array {
            (path: item.at(0), caption: item.at(1, default: none))
        } else {
            (path: item, caption: none)
        }
    })

    let col-widths = if widths == auto {
        range(count).map(_ => 1fr)
    } else { widths }

    let cols = ()
    for (i, w) in col-widths.enumerate() {
        cols.push(w)
        if i < count - 1 { cols.push(gap) }
    }

    let images-grid = grid(
        columns: cols,
        align: (center + valign,) * (count * 2 - 1),
        rows: (auto,),
        ..parsed.enumerate().map(((i, item)) => {
            let img = image(item.path)
            let cell = if border != none {
                box(
                    stroke: border,
                    radius: border-radius,
                    clip: true,
                    inset: inset,
                    img
                )
            } else { img }
            if i < count - 1 { (cell, []) } else { (cell,) }
        }).flatten()
    )

    let captions-grid = grid(
        columns: cols,
        align: (center,) * (count * 2 - 1),
        ..parsed.enumerate().map(((i, item)) => {
            let cell = if item.caption != none {
                if cap-color == auto {
                    text(size: cap-size, weight: cap-weight)[#item.caption]
                } else {
                    text(size: cap-size, weight: cap-weight, fill: cap-color)[#item.caption]
                }
            } else { [] }
            if i < count - 1 { (cell, []) } else { (cell,) }
        }).flatten()
    )

    context {
        let layout = current-layout.get()
        let dx = (layout.slide-right-margin - layout.slide-left-margin) / 2
        align(center, move(dx: dx, box(width: width, {
            block(spacing: 0pt, below: cap-gap)[#images-grid]
            block(spacing: 0pt, above: 0pt)[#captions-grid]
        })))
    }
}

#let footer-bar(self, my-heading: auto) = {
    let footer-cfg = self.store.at("footer", default: default-footer-config)
    let footer-fill = if footer-cfg.fill == auto { self.store.colors.footer-bg } else { footer-cfg.fill }
    let footer-text-fill = if footer-cfg.text-fill == auto { self.store.colors.footer-fg } else { footer-cfg.text-fill }

    set align(bottom)
    block(
        width: 100%,
        height: self.store.layout.footer-height,
        fill: footer-fill,
    )[
        #set align(horizon)
        #set text(
            size: self.store.layout.footer-text-size,
            font: self.store.fonts.mono,
            fill: footer-text-fill,
            weight: "black",
        )
        #grid(
            columns: (1fr, 3fr, 1fr),
            align: (left, center, right),
            inset: footer-cfg.inset,
            context {
                let inst = self.info.at("institution", default: none)
                if footer-cfg.show-institution and inst != none { [#upper(inst)] } else { [] }
            },
            context {
                let footer-title = self.info.at("short-title", default: none)
                if footer-title == none or footer-title == auto {
                    footer-title = self.info.title
                }
                let show-heading = footer-cfg.show-heading
                if show-heading == auto { show-heading = my-heading != none }

                let show-title = footer-cfg.show-title

                let heading = if show-heading {
                    utils.display-current-heading(level: 1, numbered: false)
                } else { none }

                if show-title and heading != none {
                    [#footer-title: #heading]
                } else if show-title {
                    [#footer-title]
                } else if heading != none {
                    [#heading]
                } else { [] }
            },
            context text(size: 1.1em)[
                #if footer-cfg.show-total {
                    [#utils.slide-counter.display() / #utils.last-slide-number]
                } else {
                    [#utils.slide-counter.display()]
                }
            ],
        )
    ]
}

#let footer-page(self) = {
    let footer-cfg = self.store.at("footer", default: default-footer-config)
    let footer-fill = if footer-cfg.fill == auto { none } else { footer-cfg.fill }
    let footer-text-fill = if footer-cfg.text-fill == auto { self.store.colors.fg } else { footer-cfg.text-fill }

    set align(bottom)
    block(
        width: 100%,
        height: self.store.layout.footer-height,
        fill: footer-fill,
    )[
        #set align(footer-cfg.align)
        #set text(
            size: self.store.layout.footer-text-size,
            font: self.store.fonts.mono,
            fill: footer-text-fill,
            weight: "black",
        )
        #block(inset: footer-cfg.inset)[
            #context [
                #if footer-cfg.show-total {
                    [#utils.slide-counter.display() / #utils.last-slide-number]
                } else {
                    [#utils.slide-counter.display()]
                }
            ]
        ]
    ]
}

#let footer(self, my-heading: auto) = {
    let footer-cfg = self.store.at("footer", default: default-footer-config)

    if footer-cfg.style == none { none }
    else if footer-cfg.style == "page" { footer-page(self) }
    else { footer-bar(self, my-heading: my-heading) }
}

#let title-slide(config: (:), ..args) = touying-slide-wrapper(self => {
    let default-config = config-page(
        footer: none,
        margin: (
            top: self.store.layout.title-top-margin,
            bottom: self.store.layout.title-bottom-margin,
            left: self.store.layout.title-left-margin,
            right: self.store.layout.title-right-margin,
        ),
    )

    self = utils.merge-dicts(self, default-config, config-page(..config))

    let body = {
        align(top + center)[
            #text(size: self.store.font-sizes.body-title, font: self.store.fonts.body, weight: "bold")[
                #self.info.subtitle
            ]
        ]
        place(center + horizon)[
            #text(size: self.store.font-sizes.title, weight: "bold")[
                #self.info.title
            ]
        ]
        place(bottom + center)[
            #set par(leading: 1em)
            #show regex("[\p{Han}]+"): set text(size: self.store.font-sizes.body-title + 6pt, font: "STHeiti")
            #text(size: self.store.font-sizes.body-title, font: self.store.fonts.body, weight: "medium")[
                #self.info.author
            ] \
            #text(size: self.store.font-sizes.body-title, font: self.store.fonts.body, weight: "medium")[
                #self.info.institution
            ] \
            #text(size: self.store.font-sizes.body-title, font: self.store.fonts.body, weight: "medium")[
                #if self.info.date != none { self.info.date } else { hide[placeholder] }
            ]
        ]
    }
    touying-slide(self: self, config: config, body)
})

#let thank-you-slide(
    title: [Thank You],
    content: none,
    config: (:),
    ..args
) = touying-slide-wrapper(self => {
    let default-config = config-page(
        footer: footer(self, my-heading: none),
        margin: (
            top: self.store.layout.title-top-margin,
            bottom: self.store.layout.title-bottom-margin,
            left: self.store.layout.title-left-margin,
            right: self.store.layout.title-right-margin,
        ),
    )

    self = utils.merge-dicts(self, default-config, config-page(..config))

    let display-author = self.info.at("author", default: none)
    let display-institution = self.info.at("institution", default: none)
    let display-email = self.info.at("email", default: none)
    let display-website = self.info.at("website", default: none)
    let display-github = self.info.at("github", default: none)

    let body = {
        place(center + horizon)[
            #text(size: self.store.font-sizes.title, weight: "bold")[#title]
        ]
        align(bottom + center)[
            #set par(leading: 1em)
            #show regex("[\p{Han}]+"): set text(size: self.store.font-sizes.body-title + 6pt, font: "FZFW ZhuZi GuDianS LH")
            #text(size: self.store.font-sizes.body-title, font: (self.store.fonts.mono), weight: "medium")[
                #if display-author != none [#display-author]
            ]\
            #text(size: self.store.font-sizes.body-title, font: self.store.fonts.mono, weight: "medium")[
                #if display-email != none [
                    #link("mailto:" + display-email)[#text(fill: self.store.colors.link)[#display-email]]\
                ]
                #if display-website != none [
                    #link(display-website)[
                        #text(fill: self.store.colors.link)[#display-website]]\
                ]
                #if display-github != none [
                    #link("https://github.com/" + display-github)[
                        #text(fill: self.store.colors.link)[github.com/#display-github]
                    ]\
                ]
                #if content != none [#content]
            ]
        ]
        v(2em)
        // place-bottom-right(assets.qr-code, caption: "pku-lemonade")
    }
    touying-slide(self: self, config: config, body)
})

#let outline-slide(
    config: (:),
    title: utils.i18n-outline-title,
    numbered: true,
    level: none,
    show-subsections: auto,
    ..args,
) = touying-slide-wrapper(self => {
    self = utils.merge-dicts(
        self,
        config-page(footer: footer(self, my-heading: none)),
    )

    let use-subsections = if show-subsections != auto {
        show-subsections
    } else {
        let user-val = self.info.at("show-subsections", default: none)
        if user-val != none { user-val } else { self.store.outline-config.show-subsections }
    }
    let outline-depth = if use-subsections { 2 } else { 1 }
    let short-heading = args.named().at("short-heading", default: true)

    let outline-alpha = self.store.outline-config.alpha
    let outline-indent = if use-subsections { (0em, 1em) } else { (self.store.layout.outline-indent,) }
    let outline-vspace = if use-subsections { (0em, 0em) } else { (self.store.layout.outline-spacing,) }
    let outline-size = if use-subsections {
        (self.store.font-sizes.body-title, self.store.font-sizes.small)
    } else {
        (self.store.font-sizes.section,)
    }

    let outline-content = components.progressive-outline(
        alpha: outline-alpha,
        level: level,
        transform: (cover: false, alpha: outline-alpha, ..args, it) => {
            let array-at(arr, idx) = arr.at(idx, default: arr.last())

            let set-text(level, body) = {
                set text(fill: if cover { utils.update-alpha(text.fill, alpha) } else { text.fill })
                set text(size: array-at(outline-size, level - 1))
                set text(weight: array-at(("bold",), level - 1))
                body
            }

            align(center)[
                #set-text(
                    it.level,
                    {
                        if type(outline-vspace) == array and outline-vspace.len() > it.level - 1 {
                            v(outline-vspace.at(it.level - 1))
                        }
                        h(range(1, it.level + 1).map(level => array-at(outline-indent, level - 1)).sum())
                        if numbered {
                            let current-numbering = if it.element.numbering != none { it.element.numbering } else { "1." }
                            numbering(
                                current-numbering,
                                ..counter(heading).at(it.element.location()),
                            )
                            h(.3em)
                        }
                        link(
                            it.element.location(),
                            if short-heading {
                                utils.short-heading(self: self, it.element)
                            } else {
                                it.element.body
                            },
                        )
                    },
                )
            ]
        },
        title: none,
        depth: outline-depth,
        ..args.named(),
    )

    let main-body = {
        align(center)[
            #text(size: self.store.font-sizes.title, weight: "bold")[#title]
        ]
        if use-subsections {
            align(center)[
                #components.adaptive-columns(outline-content)
            ]
        } else {
            place(center)[#outline-content]
        }
    }

    touying-slide(self: self, config: config, main-body)
})

#let new-section-slide(
    config: (:),
    title: utils.i18n-outline-title,
    level: 1,
    numbered: true,
    ..args,
) = outline-slide(
    config: config,
    title: title,
    level: level,
    numbered: numbered,
    ..args,
)

#let slide(title: auto, body, ..args) = touying-slide-wrapper(self => {
    if title != auto { self.store.title = title }

    self = utils.merge-dicts(self, config-page(header: none, footer: footer))

    let show-numbers = {
        let user-val = self.info.at("show-numbers", default: none)
        if user-val != none { user-val } else { self.store.heading-config.show-numbers }
    }

    let main-body = {
        block(below: 1em)[
            #text(size: self.store.font-sizes.slide-title, weight: "bold")[
                #utils.display-current-heading(
                    level: 2,
                    numbered: show-numbers,
                )
            ]
        ]
        body
    }

    touying-slide(self: self, main-body)
})

#let lecture-theme(
    aspect-ratio: "16-9",
    mode: "light",
    footer: default-footer-config,
    box-config: box-config,
    ..args,
    body
) = {
    let layout = if aspect-ratio == "4-3" { layout-4-3 } else { layout-16-9 }
    let theme = resolve-theme(mode)
    let colors = theme.colors
    let box-styles = theme.box-styles

    current-layout.update(layout)
    current-colors.update(colors)
    current-box-styles.update(box-styles)

    let footer-config = if footer == none {
        (style: "none")
    } else if type(footer) == str {
        utils.merge-dicts(default-footer-config, (style: footer))
    } else {
        utils.merge-dicts(default-footer-config, footer)
    }

    show: touying-slides.with(
        config-page(
            paper: "presentation-" + aspect-ratio,
            fill: colors.bg,
            margin: (top: layout.slide-top-margin, bottom: layout.slide-bottom-margin, left: layout.slide-left-margin, right: layout.slide-right-margin),
        ),
        config-common(
            slide-fn: slide,
            new-section-slide-fn: new-section-slide,
        ),
        config-colors(
            primary: colors.primary,
            secondary: colors.secondary,
            neutral: colors.neutral,
            neutral-lightest: colors.neutral-lightest,
            neutral-darkest: colors.neutral-darkest,
        ),
        config-store(
            layout: layout,
            heading-config: heading-config,
            outline-config: outline-config,
            colors: colors,
            fonts: fonts,
            font-sizes: font-sizes,
            box-config: box-config,
            footer: footer-config,
        ),
        ..args,
    )

    set text(size: font-sizes.body, font: fonts.body, weight: "medium", fill: colors.fg)
    set par(spacing: layout.par-spacing)
    set heading(numbering: numbly("{1}.", default: "1.1"))
    show table: set table(stroke: (paint: colors.table-stroke, thickness: 0.6pt))
    show math.equation: set text(font: fonts.math)
    show math.equation.where(block: true): set block(
        above: layout.math-block-spacing-above,
        below: layout.math-block-spacing-below,
    )
    show raw: set text(font: fonts.mono, size: font-sizes.code)
    show link: set text(fill: colors.link)

    body
}
