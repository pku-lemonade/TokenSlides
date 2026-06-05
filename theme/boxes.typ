#import "@preview/shadowed:0.3.0": shadow as draw-shadow

#import "base.typ": cur-box, cur-box-compact, cur-box-fill, cur-colors, cur-font-sizes

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
