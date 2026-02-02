#import "base.typ": font-sizes, cur-colors, cur-box

// CONFIG
#let box-config = (
    normal: (
        inset-left: 0.5em,
        inset-right: 0em,
        inset-top: 0.75em,
        inset-bottom: 0.75em,
        box-spacing-above: 0.5em,
        box-spacing-below: 0em,
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

#let code-box-config = (
    inset: 10pt,
    radius: 0pt,
    border-width: 0.8pt,
)

#let make-box(
    style-name,
    body,
    compact: false,
    breakable: false,
) = {
    context {
        let style = cur-box.get().at(style-name)
        let spacing-config = if compact { box-config.compact } else { box-config.normal }
        let border-width = box-config.border-width
        let use-border = box-config.left-border
        let inset-left = if use-border { spacing-config.inset-left + border-width } else { spacing-config.inset-left }
        let stroke = if use-border {
            (left: border-width + style.border)
        } else { none }

        block(
            breakable: breakable,
            fill: style.fill,
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

#let hbox(body, compact: false, breakable: false) = make-box("highlight", body, compact: compact, breakable: breakable)
#let ibox(body, compact: false, breakable: false) = make-box("info", body, compact: compact, breakable: breakable)
#let ebox(body, compact: false, breakable: false) = make-box("error", body, compact: compact, breakable: breakable)
#let sbox(body, compact: false, breakable: false) = make-box("success", body, compact: compact, breakable: breakable)
#let nbox(body, compact: false, breakable: false) = make-box("neutral", body, compact: compact, breakable: breakable)
#let pbox(body, compact: false, breakable: false) = make-box("purple", body, compact: compact, breakable: breakable)

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
