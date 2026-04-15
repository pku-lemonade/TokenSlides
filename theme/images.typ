#import "base.typ": fonts, font-sizes, bleed, slide-layouts, cur-ar, cur-imgs-config
#import "footer.typ": footer-layouts

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
        #if caption != none {
            let imgs-config = cur-imgs-config.get()
            let resolved-cap-size = imgs-config.at("cap-size")
            let resolved-cap-weight = imgs-config.at("cap-weight")
            [
                #block(width: 100%)[
                    #set text(font: fonts.mono, size: resolved-cap-size, weight: resolved-cap-weight)
                    #show raw: set text(font: fonts.mono, size: resolved-cap-size, weight: resolved-cap-weight)
                    #caption
                ]
                #v(-0.8em)
            ]
        }
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
    fill-height: auto,
    fill-pad: auto,
    cap-size: auto,
    cap-weight: auto,
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

    let render-caption = caption => context {
        let imgs-config = cur-imgs-config.get()
        let resolved-cap-size = if cap-size == auto { imgs-config.at("cap-size") } else { cap-size }
        let resolved-cap-weight = if cap-weight == auto { imgs-config.at("cap-weight") } else { cap-weight }
        if cap-color == auto {
            block(width: 100%)[
                #set text(font: fonts.mono, size: resolved-cap-size, weight: resolved-cap-weight)
                // Keep inline code and wrapped lines on the same caption sizing path.
                #show raw: set text(font: fonts.mono, size: resolved-cap-size, weight: resolved-cap-weight)
                #caption
            ]
        } else {
            block(width: 100%)[
                #set text(font: fonts.mono, size: resolved-cap-size, weight: resolved-cap-weight, fill: cap-color)
                // Keep inline code and wrapped lines on the same caption sizing path.
                #show raw: set text(font: fonts.mono, size: resolved-cap-size, weight: resolved-cap-weight, fill: cap-color)
                #caption
            ]
        }
    }

    let single-image = resolved-height => {
        let item = parsed.at(0)
        let img = if resolved-height == auto {
            image(item.path, width: img-width)
        } else {
            image(item.path, width: 100%, height: resolved-height, fit: img-fit)
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
        block(width: 100%)[
            #align(center)[#cell]
        ]
    }

    let images-grid = resolved-height => block(width: 100%)[
        #if count == 1 {
            single-image(resolved-height)
        } else {
            grid(
                columns: cols,
                align: (center + valign,) * (count * 2 - 1),
                rows: (auto,),
                ..parsed.enumerate().map(((i, item)) => {
                    // Fit images to their grid cell width by default to avoid overflow across pages.
                    // (Slide decks prioritize predictable layout over intrinsic image sizing.)
                    let img = if resolved-height == auto {
                        image(item.path, width: img-width)
                    } else {
                        image(item.path, width: img-width, height: resolved-height, fit: img-fit)
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
        }
    ]

    let captions-body = if count == 1 {
            let item = parsed.at(0)
            if item.caption != none {
                align(center)[
                    #render-caption(item.caption)
                ]
            }
        } else {
            grid(
                columns: cols,
                align: (center,) * (count * 2 - 1),
                ..parsed.enumerate().map(((i, item)) => {
                    let cell = if item.caption != none {
                        render-caption(item.caption)
                    } else { [] }
                    if i < count - 1 { (cell, []) } else { (cell,) }
                }).flatten()
            )
        }

    let captions-grid = block(width: 100%)[#captions-body]

    let has-captions = parsed.any(it => it.caption != none)
    context {
        let imgs-config = cur-imgs-config.get()
        let resolved-fill-height = if fill-height == auto { imgs-config.at("fill-height") } else { fill-height }
        let resolved-fill-pad = if fill-pad == auto { imgs-config.at("fill-pad") } else { fill-pad }
        let slide-margins = slide-layouts.at(cur-ar.get())
        let resolved-left-margin = measure(h(slide-margins.left)).width
        let resolved-right-margin = measure(h(slide-margins.right)).width

        let wrap-image-body = (body, available-width) => {
            let full-slide-width = page.width - resolved-left-margin - resolved-right-margin
            let use-bleed = available-width >= full-slide-width - 1pt

            if use-bleed {
                bleed(align(center)[#body])
            } else {
                block(width: 100%)[
                    #align(center)[#body]
                ]
            }
        }

        if resolved-fill-height {
            layout(size => context {
                let pos = here().position()
                let top-margin = measure(v(slide-margins.top)).height
                let footer-layout = footer-layouts.at(cur-ar.get())
                let footer-height = measure({
                    set text(size: footer-layout.text-size)
                    v(footer-layout.height)
                }).height
                let caption-height = if has-captions {
                    measure(captions-body, width: size.width).height + measure(v(cap-gap)).height
                } else {
                    0pt
                }
                let pad-height = measure(v(resolved-fill-pad)).height
                let remaining-height = calc.max(0pt, size.height + top-margin - pos.y)
                let resolved-height = calc.max(0pt, remaining-height - caption-height - footer-height - pad-height)
                [
                    #place(left)[
                        #wrap-image-body(
                            box(width: width)[
                                #block(spacing: 0pt, below: cap-gap)[#images-grid(resolved-height)]
                                #if has-captions [
                                    #block(spacing: 0pt, above: 0pt)[#captions-grid]
                                ]
                            ],
                            size.width,
                        )
                    ]
                    #v(remaining-height, weak: true)
                ]
            })
        } else {
            layout(size => wrap-image-body(
                box(width: width)[
                    #block(spacing: 0pt, below: cap-gap)[#images-grid(img-height)]
                    #if has-captions [
                        #block(spacing: 0pt, above: 0pt)[#captions-grid]
                    ]
                ],
                size.width,
            ))
        }
    }
}
