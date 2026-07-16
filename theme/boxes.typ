#import "base.typ": cur-ar, cur-box, cur-box-compact, cur-box-fill, cur-colors, cur-font-sizes, cur-footer-style
#import "emph.typ": on-primary
#import "footer.typ": footer-layouts

// USER CONFIG
// - Geometry and title typography: edit `box-config` below.
// - Equal-row layout defaults: edit `vboxs-config` below.
// - Accent palettes: edit `light-box-styles` / `dark-box-styles` in base.typ.
// - Body and title font sizes: edit `body` / `body-title` in base.typ.
// - Soft body fills are enabled with `lemonade-theme(box-fill: true)`.
//
// Per-box `compact`, `title-size`, and `title-inset` override these defaults.
// A vboxs `title-size` applies to the row unless a box sets its own title size.
#let box-config = (
    normal: (
        body-inset: (left: 0.5em, right: 0.5em, top: 0.75em, bottom: 0.75em),
        above: 0.5em,
        below: 0.5em,
    ),
    compact: (
        body-inset: (left: 10pt, right: 10pt, top: 0.5em, bottom: 0.5em),
        above: 0.25em,
        below: 0.25em,
    ),
    accent-width: 5pt,
    title-inset: (left: 0.1em, right: 0.1em, top: 0.5em, bottom: 0.5em),
    title-weight: "bold",
    title-text-fill: white,
    title-align: center,
    frame-width: 1pt,
)

#let vboxs-config = (
    gap: 0.4em,
    after-gap: 0.3em,
    fill-height: true,
    fill-pad: 0.3em,
)

#let code-box-config = (
    inset: 10pt,
    border-width: 0.8pt,
)

#let _box-figure-kind = "lemonade-box"
#let _box-spec-label = <lemonade-box-spec>

#let _frame-stroke(colors, left: true, top: true, right: true, bottom: true) = {
    let rule = box-config.frame-width + colors.table-stroke
    let stroke = (:)
    if left { stroke.insert("left", rule) }
    if top { stroke.insert("top", rule) }
    if right { stroke.insert("right", rule) }
    if bottom { stroke.insert("bottom", rule) }
    stroke
}

#let _box-visuals(spec, colors) = {
    let styles = cur-box.get()
    let style = if spec.style == none {
        none
    } else {
        assert(spec.style in styles.keys(), message: "box: unknown style `" + spec.style + "`")
        styles.at(spec.style)
    }
    (
        accent: if style == none { colors.primary } else { style.border },
        fill: if style != none and cur-box-fill.get() { style.at("fill", default: none) } else { none },
        frame: _frame-stroke(colors),
        frame-no-left: _frame-stroke(colors, left: false),
    )
}

#let _title-content(spec, font-sizes, row-title-size: none) = {
    let default-size = if row-title-size == none { font-sizes.body-title } else { row-title-size }
    let title-size = spec.at("title-size", default: default-size)
    text(size: title-size, weight: box-config.title-weight, fill: box-config.title-text-fill)[#on-primary(spec.title)]
}

#let _body-content(spec, font-sizes) = block(width: 100%)[
    #set text(size: font-sizes.body)
    #spec.body
]

// Plain boxes use a separate accent/title column. Keeping it separate from the
// body frame avoids diagonal joins between thick colored and thin neutral rules.
#let _plain-frame(
    spec,
    visuals,
    metrics,
    font-sizes,
    height: auto,
    above: 0pt,
    below: 0pt,
    row-title-size: none,
) = {
    let has-title = spec.title != none
    let title-inset = spec.at("title-inset", default: box-config.title-inset)
    let columns = if has-title { (auto, 1fr) } else { (box-config.accent-width, 1fr) }
    let rows = if height == auto { (auto,) } else { (1fr,) }
    let leading-cell = if has-title { _title-content(spec, font-sizes, row-title-size: row-title-size) } else { [] }

    block(width: 100%, height: height, above: above, below: below, spacing: 0pt)[
        #grid(
            columns: columns,
            rows: rows,
            column-gutter: 0pt,
            inset: (x, y) => if x == 0 { if has-title { title-inset } else { 0pt } } else { metrics.body-inset },
            fill: (x, y) => if x == 0 { visuals.accent } else { visuals.fill },
            stroke: (x, y) => if x == 0 { none } else { visuals.frame-no-left },
            align: (x, y) => if x == 0 { box-config.title-align + horizon } else { left + top },
            leading-cell,
            _body-content(spec, font-sizes),
        )
    ]
}

#let _title-bar(spec, visuals, font-sizes, row-title-size: none) = {
    let title-inset = spec.at("title-inset", default: box-config.title-inset)
    block(
        width: 100%,
        fill: visuals.accent,
        inset: title-inset,
        outset: (left: box-config.frame-width / 2, right: box-config.frame-width / 2),
    )[
        #align(box-config.title-align)[#_title-content(spec, font-sizes, row-title-size: row-title-size)]
    ]
}

#let _top-accent(visuals) = block(
    width: 100%,
    height: box-config.accent-width,
    fill: visuals.accent,
    outset: (left: box-config.frame-width / 2, right: box-config.frame-width / 2),
)

#let _body-frame(spec, visuals, metrics, font-sizes, height: auto) = block(
    width: 100%,
    height: height,
    fill: visuals.fill,
    inset: metrics.body-inset,
    stroke: visuals.frame,
)[
    #_body-content(spec, font-sizes)
]

#let _top-frame(
    spec,
    visuals,
    metrics,
    font-sizes,
    height: auto,
    above: 0pt,
    below: 0pt,
    row-title-size: none,
) = {
    let has-title = spec.title != none
    let header = if has-title {
        _title-bar(spec, visuals, font-sizes, row-title-size: row-title-size)
    } else {
        _top-accent(visuals)
    }
    let body-height = if height == auto { auto } else { 100% }

    block(width: 100%, height: height, above: above, below: below, spacing: 0pt)[
        #grid(
            columns: (1fr,),
            rows: if height == auto { (auto, auto) } else { (auto, 1fr) },
            row-gutter: 0pt,
            inset: 0pt,
            header,
            _body-frame(spec, visuals, metrics, font-sizes, height: body-height),
        )
    ]
}

#let _render-spec(
    spec,
    height: auto,
    outer-spacing: true,
    row-title-size: none,
) = context {
    let colors = cur-colors.get()
    let font-sizes = cur-font-sizes.get()
    let compact = spec.at("compact", default: cur-box-compact.get())
    let metrics = if compact { box-config.compact } else { box-config.normal }
    let visuals = _box-visuals(spec, colors)
    let above = if outer-spacing { metrics.above } else { 0pt }
    let below = if outer-spacing { metrics.below } else { 0pt }

    if spec.kind == "plain" {
        _plain-frame(
            spec,
            visuals,
            metrics,
            font-sizes,
            height: height,
            above: above,
            below: below,
            row-title-size: row-title-size,
        )
    } else {
        _top-frame(
            spec,
            visuals,
            metrics,
            font-sizes,
            height: height,
            above: above,
            below: below,
            row-title-size: row-title-size,
        )
    }
}

#let _box-figure(spec, body) = figure(
    kind: _box-figure-kind,
    caption: none,
    supplement: none,
    outlined: false,
)[#metadata(spec)<lemonade-box-spec>#body]

#let _figure-spec(it) = {
    let spec = none
    for child in it.body.fields().at("children", default: ()) {
        if spec == none and type(child) == content {
            let fields = child.fields()
            if child.func() == metadata and fields.at("label", default: none) == _box-spec-label {
                spec = fields.value
            }
        }
    }
    assert(spec != none, message: "box: missing internal metadata")
    spec
}

#let _with-body(spec, body) = {
    let copy = (:)
    for (key, value) in spec.pairs() { copy.insert(key, value) }
    copy.insert("body", body)
    copy
}

#let _parse-box-args(args, name) = {
    let pos = args.pos()
    let named = args.named()
    let allowed = ("title", "compact", "title-size", "title-inset")
    for key in named.keys() {
        assert(key in allowed, message: name + ": unknown option `" + key + "`")
    }
    assert(pos.len() <= 2, message: name + ": use #" + name + "[body] or #" + name + "([title])[body]")
    assert(not ("title" in named) or pos.len() <= 1, message: name + ": duplicate title")

    let title = named.at("title", default: none)
    let body = if pos.len() == 0 {
        []
    } else if pos.len() == 1 {
        pos.at(0)
    } else {
        title = pos.at(0)
        pos.at(1)
    }
    (body: body, title: title, named: named)
}

#let _make-box-helper(kind, style, name, ..args) = {
    let parsed = _parse-box-args(args, name)
    let spec = (
        kind: kind,
        style: style,
        title: parsed.title,
    )
    for key in ("compact", "title-size", "title-inset") {
        if key in parsed.named { spec.insert(key, parsed.named.at(key)) }
    }
    _box-figure(spec, parsed.body)
}

#let _make-plain(style, name, ..args) = _make-box-helper("plain", style, name, ..args)
#let _make-top(style, name, ..args) = _make-box-helper("top", style, name, ..args)

#let hbox(..args) = _make-plain("highlight", "hbox", ..args)
#let ibox(..args) = _make-plain("info", "ibox", ..args)
#let ebox(..args) = _make-plain("error", "ebox", ..args)
#let sbox(..args) = _make-plain("success", "sbox", ..args)
#let nbox(..args) = _make-plain("neutral", "nbox", ..args)
#let pbox(..args) = _make-plain("purple", "pbox", ..args)

#let vbox(..args) = _make-top(none, "vbox", ..args)
#let vhbox(..args) = _make-top("highlight", "vhbox", ..args)
#let vibox(..args) = _make-top("info", "vibox", ..args)
#let vebox(..args) = _make-top("error", "vebox", ..args)
#let vsbox(..args) = _make-top("success", "vsbox", ..args)
#let vnbox(..args) = _make-top("neutral", "vnbox", ..args)
#let vpbox(..args) = _make-top("purple", "vpbox", ..args)

#let apply-box-style(body) = {
    show figure.where(kind: _box-figure-kind): set align(left)
    show figure.where(kind: _box-figure-kind): it => _render-spec(_with-body(_figure-spec(it), it.body))
    body
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

#let _render-vboxs(
    specs,
    width: 100%,
    widths: auto,
    gap: vboxs-config.gap,
    after: none,
    after-gap: vboxs-config.after-gap,
    fill-height: vboxs-config.fill-height,
    fill-pad: vboxs-config.fill-pad,
    title-size: none,
) = {
    let count = specs.len()
    if count == 0 {
        []
    } else {
        let columns = if widths == auto {
            range(count).map(_ => 1fr)
        } else {
            assert(type(widths) == array, message: "vboxs: widths must be an array")
            assert(widths.len() == count, message: "vboxs: widths length must match item count")
            widths
        }

        let row = resolved-height => block(width: 100%, spacing: 0pt, above: 0pt, below: 0pt)[
            #grid(
                columns: columns,
                column-gutter: gap,
                rows: (resolved-height,),
                inset: 0pt,
                align: left + top,
                ..specs.map(spec => _render-spec(
                    spec,
                    height: if resolved-height == auto { auto } else { 100% },
                    outer-spacing: false,
                    row-title-size: title-size,
                )),
            )
        ]
        // Measure and render the same block so paragraph spacing cannot change its flow height.
        let after-block = if after == none {
            none
        } else {
            block(width: 100%, spacing: 0pt, above: 0pt, below: 0pt)[#after]
        }

        context {
            if fill-height {
                block(width: 100%, height: 1fr, spacing: 0pt, above: 0pt, below: 0pt)[
                    #layout(size => {
                        let footer-height = _footer-height()
                        let pad-height = measure(v(fill-pad)).height
                        let after-height = if after == none { 0pt } else {
                            measure(after-block, width: size.width).height
                        }
                        let gap-height = if after == none { 0pt } else { measure(v(after-gap)).height }
                        let available-height = calc.max(0pt, size.height - footer-height - pad-height)
                        let row-height = calc.max(0pt, available-height - after-height - gap-height)
                        block(width: 100%, height: available-height)[
                            #align(center)[#box(width: width)[#row(row-height)]]
                            #if after != none {
                                v(after-gap)
                                after-block
                            }
                        ]
                    })
                ]
            } else {
                block(width: 100%, spacing: 0pt, above: 0pt, below: 0pt)[
                    #align(center)[
                        #box(width: width)[
                            #layout(size => {
                                let natural-height = measure(row(auto), width: size.width).height
                                row(natural-height)
                            })
                        ]
                    ]
                    #if after != none {
                        v(after-gap)
                        after-block
                    }
                ]
            }
        }
    }
}

#let vboxs(
    ..items,
    width: 100%,
    widths: auto,
    gap: vboxs-config.gap,
    after: none,
    after-gap: vboxs-config.after-gap,
    fill-height: vboxs-config.fill-height,
    fill-pad: vboxs-config.fill-pad,
    title-size: none,
) = {
    let specs = items
        .pos()
        .map(item => {
            assert(
                type(item) == content and item.func() == figure and item.kind == _box-figure-kind,
                message: "vboxs: items must be Lemonade box helpers",
            )
            _with-body(_figure-spec(item), item.body)
        })
    _render-vboxs(
        specs,
        width: width,
        widths: widths,
        gap: gap,
        after: after,
        after-gap: after-gap,
        fill-height: fill-height,
        fill-pad: fill-pad,
        title-size: title-size,
    )
}

#let cbox(body, breakable: false) = context {
    let colors = cur-colors.get()
    block(
        breakable: breakable,
        fill: colors.code-bg,
        stroke: (paint: colors.code-border, thickness: code-box-config.border-width),
        inset: code-box-config.inset,
    )[
        #set text(fill: colors.code-fg)
        #body
    ]
}

#let tbox(
    body,
    size: none,
    weight: "bold",
    alignment: left,
    leading: 1em,
) = context {
    let font-sizes = cur-font-sizes.get()
    set par(leading: leading)
    align(alignment)[
        #text(size: if size == none { font-sizes.body-title } else { size }, weight: weight)[#body]
    ]
}
