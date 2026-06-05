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

#let make-box(
    style-name,
    body,
    compact: auto,
    breakable: false,
) = {
    context {
        // `compact: auto` inherits the file-level default from `lemonade-theme(box-compact: ...)`.
        let compact = if compact == auto { cur-box-compact.get() } else { compact }
        let style = cur-box.get().at(style-name)
        let colors = cur-colors.get()
        let spacing-config = if compact { box-config.compact } else { box-config.normal }
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

        block(
            breakable: breakable,
            fill: fill,
            width: 100%,
            inset: (
                left: inset-left,
                right: spacing-config.inset-right,
                top: spacing-config.inset-top,
                bottom: spacing-config.inset-bottom,
            ),
            radius: box-config.radius,
            above: spacing-config.box-spacing-above,
            below: spacing-config.box-spacing-below,
            stroke: stroke,
        )[#body]
    }
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
    let compact = if compact == auto { cur-box-compact.get() } else { compact }
    let colors = cur-colors.get()
    let font-sizes = cur-font-sizes.get()
    let spacing-config = if compact { box-config.compact } else { box-config.normal }
    let frame-width = box-config.frame-width
    let title-size = if title-size == auto { font-sizes.body-title } else { title-size }
    let body-size = if body-size == auto { font-sizes.body } else { body-size }
    let title-gap = if title-gap == auto { topbar-box-config.title-gap } else { title-gap }
    let above = if above == auto { spacing-config.box-spacing-above } else { above }
    let below = if below == auto { spacing-config.box-spacing-below } else { below }
    let content = [
        #if title != none [
            #align(center)[
                #text(size: title-size, weight: "bold", fill: colors.primary)[#title]
            ]
            #v(title-gap)
        ]
        #set text(size: body-size)
        #body
    ]

    block(
        breakable: breakable,
        fill: none,
        width: 100%,
        height: height,
        inset: (
            left: spacing-config.inset-left,
            right: spacing-config.inset-right,
            top: spacing-config.inset-top,
            bottom: spacing-config.inset-bottom,
        ),
        radius: box-config.radius,
        above: above,
        below: below,
        stroke: (
            top: topbar-box-config.top-bar-width + colors.primary,
            left: frame-width + colors.table-stroke,
            right: frame-width + colors.table-stroke,
            bottom: frame-width + colors.table-stroke,
        ),
    )[
        #if height == auto {
            content
        } else {
            align(left + valign)[#content]
        }
    ]
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

    mbox(
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
    )[#body]
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
        let cols = ()
        for (i, w) in col-widths.enumerate() {
            cols.push(w)
            if i < count - 1 { cols.push(gap) }
        }

        let parse-item = item => {
            if type(item) == dictionary {
                item
            } else if type(item) == array {
                let parsed = (
                    title: item.at(0, default: none),
                    body: item.at(1, default: []),
                )
                if item.len() > 2 and type(item.at(2)) == dictionary {
                    for (key, value) in item.at(2).pairs() {
                        parsed.insert(key, value)
                    }
                }
                parsed
            } else {
                (title: none, body: item)
            }
        }

        let render-item = (item, resolved-height) => {
            let parsed = parse-item(item)
            vbox(
                title: parsed.at("title", default: none),
                compact: parsed.at("compact", default: compact),
                breakable: parsed.at("breakable", default: breakable),
                title-size: parsed.at("title-size", default: title-size),
                body-size: parsed.at("body-size", default: body-size),
                title-gap: parsed.at("title-gap", default: title-gap),
                height: resolved-height,
                above: 0pt,
                below: 0pt,
                valign: parsed.at("valign", default: valign),
            )[#parsed.at("body", default: [])]
        }

        let row = resolved-height => block(width: 100%, spacing: 0pt, above: 0pt, below: 0pt)[
            #grid(
                columns: cols,
                align: (center + valign,) * (count * 2 - 1),
                rows: (auto,),
                ..ordered
                    .enumerate()
                    .map(((i, item)) => {
                        let cell = render-item(item, resolved-height)
                        if i < count - 1 { (cell, []) } else { (cell,) }
                    })
                    .flatten()
            )
        ]

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
