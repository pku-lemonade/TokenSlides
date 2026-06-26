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
    title-gap: 0pt,
    // `auto` follows the active box padding so vertical and horizontal title blocks match.
    title-inset: auto,
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

#let _box-figure-kind = "lemonade-box"
#let _box-spec-label = <lemonade-box-spec>

#let _box-spec(
    kind,
    body,
    style: none,
    title: none,
    compact: auto,
    breakable: false,
    title-size: auto,
    title-inset: auto,
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
    title-inset: title-inset,
    body-size: body-size,
    title-gap: title-gap,
    height: height,
    above: above,
    below: below,
    valign: valign,
)

#let _marker-spec(spec) = {
    let marker = (:)
    for (key, value) in spec.pairs() {
        if key != "body" {
            marker.insert(key, value)
        }
    }
    marker
}

#let _box-figure(spec, body) = figure(
    kind: _box-figure-kind,
    caption: none,
    supplement: none,
    outlined: false,
)[#metadata(_marker-spec(spec))<lemonade-box-spec>#body]

#let _resolve-compact(spec, default-compact: auto) = {
    let compact = spec.at("compact", default: default-compact)
    if compact == auto {
        if default-compact == auto { cur-box-compact.get() } else { default-compact }
    } else { compact }
}

#let _box-spacing(compact) = if compact { box-config.compact } else { box-config.normal }

#let _has-title(spec) = spec.at("title", default: none) != none

#let _frame-stroke(colors, left: true, top: true, right: true, bottom: true) = {
    let rule = box-config.frame-width + colors.table-stroke
    let stroke = (:)
    if left { stroke.insert("left", rule) }
    if top { stroke.insert("top", rule) }
    if right { stroke.insert("right", rule) }
    if bottom { stroke.insert("bottom", rule) }
    stroke
}

#let _inset-from-spacing(spacing-config) = (
    left: spacing-config.inset-left,
    right: spacing-config.inset-right,
    top: spacing-config.inset-top,
    bottom: spacing-config.inset-bottom,
)

#let _resolve-title-inset(spec, spacing-config: auto) = {
    let title-inset = spec.at("title-inset", default: auto)
    if title-inset == auto {
        let default-title-inset = topbar-box-config.title-inset
        if default-title-inset == auto {
            let spacing-config = if spacing-config == auto { box-config.normal } else { spacing-config }
            _inset-from-spacing(spacing-config)
        } else {
            default-title-inset
        }
    } else { title-inset }
}

#let _resolve-title-size(spec, font-sizes, default-title-size: auto) = {
    let title-size = spec.at("title-size", default: default-title-size)
    if title-size == auto { font-sizes.body-title } else { title-size }
}

#let _resolve-title-gap(spec, default-title-gap: auto) = {
    let title-gap = spec.at("title-gap", default: default-title-gap)
    if title-gap == auto { topbar-box-config.title-gap } else { title-gap }
}

#let _box-title-content(
    spec,
    font-sizes,
    default-title-size: auto,
) = {
    let title = spec.at("title", default: none)
    let title-size = _resolve-title-size(spec, font-sizes, default-title-size: default-title-size)
    text(size: title-size, weight: "bold", fill: white)[#title]
}

#let _plain-box-layout(spec, spacing-config, colors) = {
    let styles = cur-box.get()
    assert(spec.style in styles.keys(), message: "box: unknown box style")
    let style = styles.at(spec.style)
    let border-width = box-config.border-width
    let use-border = box-config.left-border
    let fill = if cur-box-fill.get() { style.at("fill", default: none) } else { none }
    let border = style.border
    let has-fill = fill != none
    let inset-left = if use-border { spacing-config.inset-left + border-width } else { spacing-config.inset-left }
    let stroke = if use-border {
        if has-fill {
            (left: border-width + border)
        } else {
            let stroke = _frame-stroke(colors)
            stroke.insert("left", border-width + border)
            stroke
        }
    } else { none }

    (
        fill: fill,
        stroke: stroke,
        titled-body-stroke: if use-border { _frame-stroke(colors) } else { stroke },
        title-fill: border,
        horizontal-title-stroke: if use-border { _frame-stroke(colors, right: false) } else { none },
        vertical-title-stroke: if use-border { _frame-stroke(colors, bottom: false) } else { none },
        titled-body-inset: _inset-from-spacing(spacing-config),
        inset: (
            left: inset-left,
            right: spacing-config.inset-right,
            top: spacing-config.inset-top,
            bottom: spacing-config.inset-bottom,
        ),
    )
}

#let _topbar-box-layout(spacing-config, colors) = {
    let stroke = _frame-stroke(colors)
    stroke.insert("top", topbar-box-config.top-bar-width + colors.primary)

    (
        fill: none,
        stroke: stroke,
        titled-body-stroke: _frame-stroke(colors),
        title-fill: colors.primary,
        horizontal-title-stroke: _frame-stroke(colors, right: false),
        vertical-title-stroke: _frame-stroke(colors, bottom: false),
        titled-body-inset: _inset-from-spacing(spacing-config),
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

#let _box-body-content(
    spec,
    font-sizes,
    default-body-size: auto,
) = {
    let resolved-body-size = spec.at("body-size", default: default-body-size)
    let resolved-body-size = if resolved-body-size == auto { font-sizes.body } else { resolved-body-size }
    let body = spec.at("body", default: [])

    block(width: 100%)[
        #set text(size: resolved-body-size)
        #body
    ]
}

#let _box-title-bar(
    spec,
    layout,
    font-sizes,
    default-title-size: auto,
) = {
    let resolved-title-inset = _resolve-title-inset(spec, spacing-config: layout.spacing)
    block(
        width: 100%,
        fill: layout.title-fill,
        inset: resolved-title-inset,
        radius: box-config.radius,
        stroke: layout.at("vertical-title-stroke", default: none),
    )[
        #align(center)[
            #_box-title-content(spec, font-sizes, default-title-size: default-title-size)
        ]
    ]
}

#let _box-title-cell(
    spec,
    font-sizes,
    default-title-size: auto,
) = {
    align(center + horizon)[
        #_box-title-content(spec, font-sizes, default-title-size: default-title-size)
    ]
}

#let _box-body-frame(
    spec,
    layout,
    font-sizes,
    body-height: auto,
    default-body-size: auto,
    valign: top,
    stroke: auto,
    inset: auto,
) = {
    let content = _box-body-content(spec, font-sizes, default-body-size: default-body-size)
    let stroke = if stroke == auto { layout.stroke } else { stroke }
    let inset = if inset == auto { layout.inset } else { inset }

    block(
        breakable: spec.at("breakable", default: false),
        fill: layout.fill,
        width: 100%,
        height: body-height,
        inset: inset,
        radius: box-config.radius,
        stroke: stroke,
    )[
        #if body-height == auto {
            content
        } else {
            align(valign)[
                #block(width: 100%)[#content]
            ]
        }
    ]
}

#let _box-frame-vertical-title(
    spec,
    layout,
    font-sizes,
    height: auto,
    above: 0pt,
    below: 0pt,
    default-title-size: auto,
    default-body-size: auto,
    default-title-gap: auto,
    valign: top,
) = {
    let resolved-title-gap = _resolve-title-gap(spec, default-title-gap: default-title-gap)
    let body-height = if height == auto { auto } else { 100% }
    let body-stroke = layout.at("titled-body-stroke", default: layout.stroke)
    let body-inset = layout.at("titled-body-inset", default: layout.inset)

    block(
        breakable: spec.at("breakable", default: false),
        width: 100%,
        height: height,
        above: above,
        below: below,
        spacing: 0pt,
    )[
        #grid(
            columns: (1fr,),
            rows: if height == auto { (auto, auto) } else { (auto, 1fr) },
            row-gutter: resolved-title-gap,
            inset: 0pt,
            _box-title-bar(spec, layout, font-sizes, default-title-size: default-title-size),
            _box-body-frame(
                spec,
                layout,
                font-sizes,
                body-height: body-height,
                default-body-size: default-body-size,
                valign: valign,
                stroke: body-stroke,
                inset: body-inset,
            ),
        )
    ]
}

#let _box-frame-horizontal-title(
    spec,
    layout,
    font-sizes,
    height: auto,
    above: 0pt,
    below: 0pt,
    default-title-size: auto,
    default-body-size: auto,
    default-title-gap: auto,
    valign: top,
) = {
    let resolved-title-gap = _resolve-title-gap(spec, default-title-gap: default-title-gap)
    let title-inset = _resolve-title-inset(spec, spacing-config: layout.spacing)
    let title-stroke = layout.at("horizontal-title-stroke", default: none)
    let body-stroke = layout.at("titled-body-stroke", default: layout.stroke)
    let body-inset = layout.at("titled-body-inset", default: layout.inset)

    block(
        breakable: spec.at("breakable", default: false),
        width: 100%,
        height: height,
        above: above,
        below: below,
        spacing: 0pt,
    )[
        #grid(
            columns: (auto, 1fr),
            rows: if height == auto { (auto,) } else { (1fr,) },
            column-gutter: resolved-title-gap,
            inset: (x, y) => {
                if x == 0 { title-inset } else { body-inset }
            },
            fill: (x, y) => if x == 0 { layout.title-fill } else { layout.fill },
            stroke: (x, y) => {
                if x == 0 { title-stroke } else { body-stroke }
            },
            align: (x, y) => if x == 0 { center + horizon } else { left + valign },
            _box-title-cell(
                spec,
                font-sizes,
                default-title-size: default-title-size,
            ),
            _box-body-content(spec, font-sizes, default-body-size: default-body-size),
        )
    ]
}

#let _box-frame(
    spec,
    layout,
    font-sizes,
    height: auto,
    above: 0pt,
    below: 0pt,
    default-title-size: auto,
    default-body-size: auto,
    default-title-gap: auto,
    valign: top,
) = {
    if _has-title(spec) {
        if spec.kind == "topbar" {
            _box-frame-vertical-title(
                spec,
                layout,
                font-sizes,
                height: height,
                above: above,
                below: below,
                default-title-size: default-title-size,
                default-body-size: default-body-size,
                default-title-gap: default-title-gap,
                valign: valign,
            )
        } else {
            _box-frame-horizontal-title(
                spec,
                layout,
                font-sizes,
                height: height,
                above: above,
                below: below,
                default-title-size: default-title-size,
                default-body-size: default-body-size,
                default-title-gap: default-title-gap,
                valign: valign,
            )
        }
    } else {
        let content = _box-body-content(spec, font-sizes, default-body-size: default-body-size)
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
                align(valign)[
                    #block(width: 100%)[#content]
                ]
            }
        ]
    }
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

    _box-frame(
        spec,
        layout,
        font-sizes,
        height: height,
        above: above,
        below: below,
        valign: spec.at("valign", default: top),
    )
}

#let _figure-marker-spec(it) = {
    let spec = none
    if type(it.body) == content {
        for child in it.body.fields().at("children", default: ()) {
            if spec == none and type(child) == content {
                let fields = child.fields()
                if child.func() == metadata and fields.at("label", default: none) == _box-spec-label {
                    spec = fields.value
                }
            }
        }
    }
    spec
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

#let _parse-titled-box-args(args, name) = {
    let pos = args.pos()
    let named = args.named()
    assert(pos.len() <= 2, message: name + ": use #" + name + "[body] or #" + name + "([title])[body]")
    assert(
        not ("title" in named) or pos.len() <= 1,
        message: name + ": `title:` cannot be combined with two positional content blocks",
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

    (body: body, title: title, named: named)
}

#let make-box(
    style-name,
    body,
    compact: auto,
    breakable: false,
    title: none,
    title-size: auto,
    title-inset: auto,
    body-size: auto,
    title-gap: auto,
    height: auto,
    above: auto,
    below: auto,
    valign: top,
) = {
    let spec = _box-spec(
        "plain",
        body,
        style: style-name,
        title: title,
        compact: compact,
        breakable: breakable,
        title-size: title-size,
        title-inset: title-inset,
        body-size: body-size,
        title-gap: title-gap,
        height: height,
        above: above,
        below: below,
        valign: valign,
    )
    _box-figure(spec, body)
}

#let _make-named-box(style-name, name, ..args) = {
    let parsed = _parse-titled-box-args(args, name)
    let named = parsed.named
    make-box(
        style-name,
        parsed.body,
        title: parsed.title,
        compact: named.at("compact", default: auto),
        breakable: named.at("breakable", default: false),
        title-size: named.at("title-size", default: auto),
        title-inset: named.at("title-inset", default: auto),
        body-size: named.at("body-size", default: auto),
        title-gap: named.at("title-gap", default: auto),
        height: named.at("height", default: auto),
        above: named.at("above", default: auto),
        below: named.at("below", default: auto),
        valign: named.at("valign", default: top),
    )
}

#let hbox(..args) = _make-named-box("highlight", "hbox", ..args)
#let ibox(..args) = _make-named-box("info", "ibox", ..args)
#let ebox(..args) = _make-named-box("error", "ebox", ..args)
#let sbox(..args) = _make-named-box("success", "sbox", ..args)
#let nbox(..args) = _make-named-box("neutral", "nbox", ..args)
#let pbox(..args) = _make-named-box("purple", "pbox", ..args)

#let vbox(..args) = {
    let parsed = _parse-titled-box-args(args, "vbox")
    let named = parsed.named

    let spec = _box-spec(
        "topbar",
        parsed.body,
        title: parsed.title,
        compact: named.at("compact", default: auto),
        breakable: named.at("breakable", default: false),
        title-size: named.at("title-size", default: auto),
        title-inset: named.at("title-inset", default: auto),
        body-size: named.at("body-size", default: auto),
        title-gap: named.at("title-gap", default: auto),
        height: named.at("height", default: auto),
        above: named.at("above", default: auto),
        below: named.at("below", default: auto),
        valign: named.at("valign", default: top),
    )
    _box-figure(spec, parsed.body)
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

#let apply-box-style(
    body,
) = {
    show figure.where(kind: _box-figure-kind): set align(left)
    show figure.where(kind: _box-figure-kind): it => {
        let spec = _figure-marker-spec(it)
        if spec == none {
            it
        } else if spec.kind == "tbox" {
            context {
                let font-sizes = cur-font-sizes.get()
                let size = if spec.size == auto { font-sizes.body-title } else { spec.size }
                set par(leading: spec.leading)
                align(spec.alignment)[
                    #text(size: size, weight: spec.weight)[
                        #it.body
                    ]
                ]
            }
        } else {
            spec.insert("body", it.body)
            _render-box-spec(spec)
        }
    }

    body
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
        } else {
            assert(type(widths) == array, message: "vboxs: widths must be an array")
            assert(widths.len() == count, message: "vboxs: widths length must match item count")
            widths
        }

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
                    title-inset: item.at("title-inset", default: auto),
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
                    inset: 0pt,
                    align: (x, y) => left + top,
                    ..specs.enumerate().map(((i, spec)) => _box-frame(
                        spec,
                        layouts.at(i),
                        font-sizes,
                        height: if resolved-height == auto { auto } else { 100% },
                        above: 0pt,
                        below: 0pt,
                        default-title-size: title-size,
                        default-body-size: body-size,
                        default-title-gap: title-gap,
                        valign: cell-valign(i, 0),
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
    _box-figure((
        kind: "tbox",
        size: size,
        weight: weight,
        alignment: alignment,
        leading: leading,
    ), body)
}
