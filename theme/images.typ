#import "base.typ": fonts, font-sizes, bleed

// CONFIG
#let assets = (
    logo: "../assets/logo.png",
    qr-code: "../assets/qr.png",
)

#let place-image(
    path,
    caption: none,
    width: 25%,
    height: auto,
    fit: "contain",
    position: top + right,
    dx: 0.5em,
    dy: 1em
) = place(position, dx: dx, dy: dy)[
    #align(center)[
        #if caption != none [
            #text(font: fonts.mono, size: font-sizes.body, weight: "medium")[#caption]
            #v(-0.8em)
        ]
        #if height == auto {
            image(path, width: width)
        } else {
            image(path, width: width, height: height, fit: fit)
        }
    ]
]

#let place-logo(..args) = place-image(assets.logo, dx: -0.5em,dy: -1em, position: top + right, ..args)
#let place-bottom-right(path, caption: none, ..args) = place-image(path, caption: caption, width: 20%, dx: -1.5em, dy: 0em, position: bottom + right, ..args)
#let place-bottom-left(path, caption: none, ..args) = place-image(path, caption: caption, width: 20%, dx: 1.5em, dy: 0em, position: bottom + left, ..args)

#let imgs(
    ..images,
    width: 60%,
    widths: auto,
    gap: 0em,
    valign: horizon,
    img-width: 100%,
    img-height: auto,
    img-fit: "contain",
    show-captions: false,
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
            // Fit images to their grid cell width by default to avoid overflow across pages.
            // (Slide decks prioritize predictable layout over intrinsic image sizing.)
            let img = if img-height == auto {
                image(item.path, width: img-width)
            } else {
                image(item.path, width: img-width, height: img-height, fit: img-fit)
            }
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

    bleed(align(center)[
        #box(width: width)[
            #block(spacing: 0pt, below: cap-gap)[#images-grid]
            #if show-captions and parsed.any(it => it.caption != none) [
                #block(spacing: 0pt, above: 0pt)[#captions-grid]
            ]
        ]
    ])
}
