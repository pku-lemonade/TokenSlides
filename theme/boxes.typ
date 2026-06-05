#import "@preview/shadowed:0.3.0": shadow as draw-shadow

#import "base.typ": cur-ar, cur-box, cur-box-compact, cur-box-fill, cur-colors, cur-footer-style, cur-font-sizes, cur-imgs-config
#import "footer.typ": footer-layouts

// CONFIG
#let box-config = (
    normal: (
        inset-left: 0.5em,
        inset-right: 0.5em,
        inset-top: 0.75em,
        inset-bottom: 0.75em,
        box-spacing-above: 0.25em,
        box-spacing-below: 0.25em,
    ),
    compact: (
        inset-left: 10pt,
        inset-right: 10pt,
        inset-top: 0.5em,
        inset-bottom: 0.5em,
        box-spacing-above: 0.25em,
        box-spacing-below: 0.25em,
    ),
    radius: 0pt,
    left-border: true,
    border-width: 5pt,
    frame-width: 0.6pt,
)

#let code-box-config = (
    inset: 10pt,
    radius: 0pt,
    border-width: 0.8pt,
)

#let topbar-box-config = (
    top-bar-width: 4pt,
    gap: 0.4em,
    title-gap: 0.1em,
)

#let callout-config = (
    inset: (left: 0em, right: 0em, top: 0.5em, bottom: 0.5em),
    above: 0.2em,
    below: 0em,
    radius: 0pt,
    stroke-width: 0.8pt,
    size: 36pt,
    weight: "bold",
    leading: 0em,
    tracking: 0.1em,
    shadow: true,
    shadow-fill: black.transparentize(70%),
    shadow-blur: 4pt,
    shadow-spread: 1pt,
    shadow-dx: 0pt,
    shadow-dy: 0pt,
)

#let callout-colors(colors) = (
    white: (
        fill: white,
        text-fill: black,
        emph-fill: colors.primary,
        stroke-fill: white,
    ),
    blue: (
        fill: rgb("#003262"),
        text-fill: white,
        emph-fill: rgb("#FDB515"),
        stroke-fill: rgb("#003262"),
    ),
    red: (
        fill: colors.primary,
        text-fill: white,
        emph-fill: colors.secondary,
        stroke-fill: colors.primary,
    ),
)

#let _box-spec-label = <lemonade-box-spec>

#let _box-spec(
    kind,
    body,
    style: none,
    title: none,
    compact: auto,
    breakable: false,
    title-size: auto,
    body-size: auto,
    title-gap: auto,
    height: auto,
    above: auto,
    below: auto,
    valign: top,
) = (
    kind: kind,
    style: style,
    title: title,
    body: body,
    compact: compact,
    breakable: breakable,
    title-size: title-size,
    body-size: body-size,
    title-gap: title-gap,
    height: height,
    above: above,
    below: below,
    valign: valign,
)

#let _mark-box(spec, rendered) = [
    #metadata(spec)<lemonade-box-spec>
    #rendered
]

#let _resolve-compact(spec, default-compact: auto) = {
    let compact = spec.at("compact", default: default-compact)
    if compact == auto {
        if default-compact == auto { cur-box-compact.get() } else { default-compact }
    } else { compact }
}

#let _box-spacing(compact) = if compact { box-config.compact } else { box-config.normal }

#let _plain-box-layout(spec, spacing-config, colors) = {
    let style = cur-box.get().at(spec.style)
    let border-width = box-config.border-width
    let frame-width = box-config.frame-width
    let use-border = box-config.left-border
    let fill = if cur-box-fill.get() { style.at("fill", default: none) } else { none }
    let border = style.border
    let has-fill = fill != none
    let inset-left = if use-border { spacing-config.inset-left + border-width } else { spacing-config.inset-left }
    let stroke = if use-border {
        if has-fill {
            (left: border-width + border)
        } else {
            (
                left: border-width + border,
                top: frame-width + colors.table-stroke,
                right: frame-width + colors.table-stroke,
                bottom: frame-width + colors.table-stroke,
            )
        }
    } else { none }

    (
        fill: fill,
        stroke: stroke,
        inset: (
            left: inset-left,
            right: spacing-config.inset-right,
            top: spacing-config.inset-top,
            bottom: spacing-config.inset-bottom,
        ),
    )
}

#let _topbar-box-layout(spacing-config, colors) = {
    let frame-width = box-config.frame-width
    (
        fill: none,
        stroke: (
            top: topbar-box-config.top-bar-width + colors.primary,
            left: frame-width + colors.table-stroke,
            right: frame-width + colors.table-stroke,
            bottom: frame-width + colors.table-stroke,
        ),
        inset: (
            left: spacing-config.inset-left,
            right: spacing-config.inset-right,
            top: spacing-config.inset-top,
            bottom: spacing-config.inset-bottom,
        ),
    )
}

#let _box-layout(spec, colors, default-compact: auto) = {
    let compact = _resolve-compact(spec, default-compact: default-compact)
    let spacing-config = _box-spacing(compact)
    let layout = if spec.kind == "topbar" {
        _topbar-box-layout(spacing-config, colors)
    } else {
        _plain-box-layout(spec, spacing-config, colors)
    }
    layout.insert("spacing", spacing-config)
    layout
}

#let _box-content(
    spec,
    colors,
    font-sizes,
    default-title-size: auto,
    default-body-size: auto,
    default-title-gap: auto,
) = {
    let resolved-title-size = spec.at("title-size", default: default-title-size)
    let resolved-body-size = spec.at("body-size", default: default-body-size)
    let resolved-title-gap = spec.at("title-gap", default: default-title-gap)
    let resolved-title-size = if resolved-title-size == auto { font-sizes.body-title } else { resolved-title-size }
    let resolved-body-size = if resolved-body-size == auto { font-sizes.body } else { resolved-body-size }
    let resolved-title-gap = if resolved-title-gap == auto { topbar-box-config.title-gap } else { resolved-title-gap }
    let title = spec.at("title", default: none)
    let body = spec.at("body", default: [])

    block(width: 100%)[
        #if title != none [
            #align(center)[
                #text(size: resolved-title-size, weight: "bold", fill: colors.primary)[#title]
            ]
            #v(resolved-title-gap)
        ]
        #set text(size: resolved-body-size)
        #body
    ]
}

#let _render-box-spec(spec) = context {
    let colors = cur-colors.get()
    let font-sizes = cur-font-sizes.get()
    let layout = _box-layout(spec, colors)
    let spacing-config = layout.spacing
    let height = spec.at("height", default: auto)
    let above = spec.at("above", default: auto)
    let below = spec.at("below", default: auto)
    let above = if above == auto { spacing-config.box-spacing-above } else { above }
    let below = if below == auto { spacing-config.box-spacing-below } else { below }
    let content = _box-content(spec, colors, font-sizes)

    block(
        breakable: spec.at("breakable", default: false),
        fill: layout.fill,
        width: 100%,
        height: height,
        inset: layout.inset,
        radius: box-config.radius,
        above: above,
        below: below,
        stroke: layout.stroke,
    )[
        #if height == auto {
            content
        } else {
            align(spec.at("valign", default: top))[
                #block(width: 100%)[#content]
            ]
        }
    ]
}

#let _content-box-spec(item) = {
    let found = none
    if type(item) == content {
        let fields = item.fields()
        if item.func() == metadata and fields.at("label", default: none) == _box-spec-label {
            found = fields.value
        } else {
            for child in fields.at("children", default: ()) {
                if found == none {
                    found = _content-box-spec(child)
                }
            }
        }
    }
    found
}

#let make-box(
    style-name,
    body,
    compact: auto,
    breakable: false,
) = {
    let spec = _box-spec("plain", body, style: style-name, compact: compact, breakable: breakable)
    _mark-box(spec, _render-box-spec(spec))
}

#let hbox(body, compact: auto, breakable: false) = make-box("highlight", body, compact: compact, breakable: breakable)
#let ibox(body, compact: auto, breakable: false) = make-box("info", body, compact: compact, breakable: breakable)
#let ebox(body, compact: auto, breakable: false) = make-box("error", body, compact: compact, breakable: breakable)
#let sbox(body, compact: auto, breakable: false) = make-box("success", body, compact: compact, breakable: breakable)
#let nbox(body, compact: auto, breakable: false) = make-box("neutral", body, compact: compact, breakable: breakable)
#let pbox(body, compact: auto, breakable: false) = make-box("purple", body, compact: compact, breakable: breakable)

#let mbox(
    body,
    title: none,
    compact: auto,
    breakable: false,
    title-size: auto,
    body-size: auto,
    title-gap: auto,
    height: auto,
    above: auto,
    below: auto,
    valign: top,
) = context {
    let spec = _box-spec(
        "topbar",
        body,
        title: title,
        compact: compact,
        breakable: breakable,
        title-size: title-size,
        body-size: body-size,
        title-gap: title-gap,
        height: height,
        above: above,
        below: below,
        valign: valign,
    )
    _render-box-spec(spec)
}

#let vbox(..args) = {
    let pos = args.pos()
    let named = args.named()
    assert(pos.len() <= 2, message: "vbox: use #vbox[body] or #vbox([title])[body]")
    assert(
        not ("title" in named) or pos.len() <= 1,
        message: "vbox: `title:` cannot be combined with two positional content blocks",
    )

    let title = named.at("title", default: none)
    let body = if pos.len() == 0 {
        named.at("body", default: [])
    } else if pos.len() == 1 {
        pos.at(0)
    } else {
        title = pos.at(0)
        pos.at(1)
    }

    let spec = _box-spec(
        "topbar",
        body,
        title: title,
        compact: named.at("compact", default: auto),
        breakable: named.at("breakable", default: false),
        title-size: named.at("title-size", default: auto),
        body-size: named.at("body-size", default: auto),
        title-gap: named.at("title-gap", default: auto),
        height: named.at("height", default: auto),
        above: named.at("above", default: auto),
        below: named.at("below", default: auto),
        valign: named.at("valign", default: top),
    )
    _mark-box(spec, _render-box-spec(spec))
}

#let _footer-height() = {
    if cur-footer-style.get() == none {
        0pt
    } else {
        let footer-layout = footer-layouts.at(cur-ar.get())
        measure({
            set text(size: footer-layout.text-size)
            v(footer-layout.height)
        }).height
    }
}

#let vboxs(
    ..items,
    dir: ltr,
    width: 100%,
    widths: auto,
    gap: auto,
    fill-height: auto,
    fill-pad: auto,
    compact: auto,
    breakable: false,
    title-size: auto,
    body-size: auto,
    title-gap: auto,
    valign: top,
    halign: center,
) = {
    let items = items.pos()
    let count = items.len()
    if count == 0 {
        []
    } else {
        let ordered = if dir == rtl { items.rev() } else { items }
        let gap = if gap == auto { topbar-box-config.gap } else { gap }
        let col-widths = if widths == auto {
            range(count).map(_ => 1fr)
        } else { widths }

        let parse-item = item => {
            let marked = _content-box-spec(item)
            if marked != none {
                marked
            } else if type(item) == dictionary {
                let parsed = _box-spec(
                    item.at("kind", default: "topbar"),
                    item.at("body", default: []),
                    style: item.at("style", default: none),
                    title: item.at("title", default: none),
                    compact: item.at("compact", default: auto),
                    breakable: item.at("breakable", default: breakable),
                    title-size: item.at("title-size", default: auto),
                    body-size: item.at("body-size", default: auto),
                    title-gap: item.at("title-gap", default: auto),
                    height: item.at("height", default: auto),
                    above: item.at("above", default: auto),
                    below: item.at("below", default: auto),
                    valign: item.at("valign", default: top),
                )
                for (key, value) in item.pairs() {
                    parsed.insert(key, value)
                }
                parsed
            } else if type(item) == array {
                let parsed = _box-spec(
                    "topbar",
                    item.at(1, default: []),
                    title: item.at(0, default: none),
                    breakable: breakable,
                )
                if item.len() > 2 and type(item.at(2)) == dictionary {
                    for (key, value) in item.at(2).pairs() {
                        parsed.insert(key, value)
                    }
                }
                parsed
            } else {
                _box-spec("topbar", item, breakable: breakable)
            }
        }
        let specs = ordered.map(parse-item)

        let row = resolved-height => context {
            let colors = cur-colors.get()
            let font-sizes = cur-font-sizes.get()
            let layouts = specs.map(spec => _box-layout(spec, colors, default-compact: compact))
            let resolved-rows = if resolved-height == auto { (auto,) } else { (resolved-height,) }
            let cell-valign = (x, y) => specs.at(x).at("valign", default: valign)

            block(width: 100%, spacing: 0pt, above: 0pt, below: 0pt)[
                #grid(
                    columns: col-widths,
                    column-gutter: gap,
                    rows: resolved-rows,
                    inset: (x, y) => {
                        layouts.at(x).inset
                    },
                    fill: (x, y) => layouts.at(x).fill,
                    stroke: (x, y) => layouts.at(x).stroke,
                    align: (x, y) => left + cell-valign(x, y),
                    ..specs.map(spec => _box-content(
                        spec,
                        colors,
                        font-sizes,
                        default-title-size: title-size,
                        default-body-size: body-size,
                        default-title-gap: title-gap,
                    )),
                )
            ]
        }

        context {
            let imgs-config = cur-imgs-config.get()
            let resolved-fill-height = if fill-height == auto { imgs-config.at("fill-height") } else { fill-height }
            let resolved-fill-pad = if fill-pad == auto { imgs-config.at("fill-pad") } else { fill-pad }

            if resolved-fill-height {
                block(width: 100%, height: 1fr, spacing: 0pt, above: 0pt, below: 0pt)[
                    #layout(size => {
                        let footer-height = _footer-height()
                        let pad-height = measure(v(resolved-fill-pad)).height
                        let reserved-height = calc.max(0pt, size.height - footer-height - pad-height)
                        block(width: 100%, height: reserved-height)[
                            #align(halign)[
                                #box(width: width)[#row(reserved-height)]
                            ]
                        ]
                    })
                ]
            } else {
                align(halign)[
                    #box(width: width)[#row(auto)]
                ]
            }
        }
    }
}

// High-emphasis banner/callout.
// Inside the box, `_emph_` and `*strong*` text use the emphasis color.
#let callout(
    body,
    width: 100%,
    color: "white",
    size: callout-config.size,
    fill: auto,
    text-fill: auto,
    emph-fill: auto,
    stroke: auto,
    inset: callout-config.inset,
    above: callout-config.above,
    below: callout-config.below,
    alignment: center,
    weight: callout-config.weight,
    leading: callout-config.leading,
    tracking: callout-config.tracking,
    shadow: callout-config.shadow,
    shadow-fill: callout-config.shadow-fill,
    shadow-blur: callout-config.shadow-blur,
    shadow-spread: callout-config.shadow-spread,
    shadow-dx: callout-config.shadow-dx,
    shadow-dy: callout-config.shadow-dy,
    breakable: false,
) = {
    context {
        let colors = cur-colors.get()
        let font-sizes = cur-font-sizes.get()
        let color-options = callout-colors(colors)
        assert(type(color) == str, message: "callout: color must be a string")
        assert(color in color-options.keys(), message: "callout: unknown color `" + color + "`")
        let color-style = color-options.at(color)
        let size = if size == auto { font-sizes.body-title } else { size }
        let fill = if fill == auto { color-style.fill } else { fill }
        let text-fill = if text-fill == auto { color-style.text-fill } else { text-fill }
        let emph-fill = if emph-fill == auto { color-style.emph-fill } else { emph-fill }
        let stroke = if stroke == auto { callout-config.stroke-width + color-style.stroke-fill } else { stroke }

        let body-block = block(
            breakable: breakable,
            width: 100%,
            fill: fill,
            stroke: stroke,
            radius: callout-config.radius,
            inset: inset,
        )[
            #show emph: it => {
                set text(fill: emph-fill, weight: weight)
                h(tracking)
                it.body
                h(tracking)
            }
            #show strong: it => {
                set text(fill: emph-fill, weight: weight)
                h(tracking)
                it.body
                h(tracking)
            }
            #set par(leading: leading)
            #align(alignment)[
                #text(fill: text-fill, size: size, weight: weight, tracking: tracking)[#body]
            ]
        ]

        block(width: width, above: above, below: below, breakable: false)[
            #if shadow != none and shadow != false {
                draw-shadow(
                    dx: shadow-dx,
                    dy: shadow-dy,
                    blur: shadow-blur,
                    spread: shadow-spread,
                    fill: shadow-fill,
                    radius: callout-config.radius,
                )[#body-block]
            } else {
                body-block
            }
        ]
    }
}

#let bluecallout(..args) = callout(color: "blue", ..args)
#let redcallout(..args) = callout(color: "red", ..args)
#let bcallout(..args) = bluecallout(..args)
#let rcallout(..args) = redcallout(..args)

// code box helper
#let cbox(body, breakable: false) = {
    context {
        let colors = cur-colors.get()
        block(
            breakable: breakable,
            fill: colors.code-bg,
            radius: code-box-config.radius,
            stroke: (paint: colors.code-border, thickness: code-box-config.border-width),
            inset: code-box-config.inset,
        )[
            #set text(fill: colors.code-fg)
            #body
        ]
    }
}

// Small title-ish text helper.
#let tbox(
    body,
    size: auto,
    weight: "bold",
    alignment: left,
    leading: 1em,
) = {
    context {
        let font-sizes = cur-font-sizes.get()
        let size = if size == auto { font-sizes.body-title } else { size }
        set par(leading: leading)
        align(alignment)[
            #text(size: size, weight: weight)[#body]
        ]
    }
}
