#import "state.typ": cur-colors, cur-box

// CONFIG
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

#let code-box-config = (
    inset: 10pt,
    radius: 0pt,
    border-width: 0.8pt,
)

#let _auto(v, d) = if v == auto { d } else { v }

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
        let style = cur-box.get().at(style-name)

        let use-border = _auto(left-border, box-config.left-border)
        let spacing-config = if compact { box-config.compact } else { box-config.normal }

        let inset-left = if inset == auto { spacing-config.inset-left } else { inset }
        let inset-right = if inset == auto { spacing-config.inset-right } else { inset }
        let inset-top = if inset == auto { spacing-config.inset-top } else { inset }
        let inset-bottom = if inset == auto { spacing-config.inset-bottom } else { inset }
        let inset-left-final = if use-border { inset-left + 4pt } else { inset-left }

        let fill-final = _auto(fill, style.fill)
        let radius-final = _auto(radius, box-config.radius)
        let above-final = _auto(above, spacing-config.box-spacing-above)
        let below-final = _auto(below, spacing-config.box-spacing-below)

        let stroke = if use-border {
            let bw = _auto(border-width, box-config.border-width)
            let bc = _auto(border-color, style.border)
            (left: bw + bc)
        } else { none }

        block(
            fill: fill-final,
            breakable: breakable,
            inset: (left: inset-left-final, right: inset-right, top: inset-top, bottom: inset-bottom),
            radius: radius-final,
            width: width,
            height: height,
            above: above-final,
            below: below-final,
            stroke: stroke,
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
        let colors = cur-colors.get()
        block(
            fill: colors.code-bg,
            radius: code-box-config.radius,
            stroke: (paint: colors.code-border, thickness: code-box-config.border-width),
            inset: code-box-config.inset,
            ..args,
        )[
            #set text(fill: colors.code-fg)
            #body
        ]
    }
}

