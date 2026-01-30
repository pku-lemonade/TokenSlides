#import "base.typ": fonts, font-sizes
#import "state.typ": cur-layout

// CONFIG
#let assets = (
    logo: "assets/logo.png",
    qr-code: "assets/qr.png",
)

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
#let place-bottom-right(path, caption: none, ..args) = place-image(path, caption: caption, width: 20%, dx: -1.5em, dy: 0em, position: bottom + right, ..args)
#let place-bottom-left(path, caption: none, ..args) = place-image(path, caption: caption, width: 20%, dx: 1.5em, dy: 0em, position: bottom + left, ..args)

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
        let layout = cur-layout.get()
        let dx = (layout.slide-right-margin - layout.slide-left-margin) / 2
        align(center, move(dx: dx, box(width: width, {
            block(spacing: 0pt, below: cap-gap)[#images-grid]
            block(spacing: 0pt, above: 0pt)[#captions-grid]
        })))
    }
}

