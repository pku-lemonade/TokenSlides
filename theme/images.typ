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
        #if caption != none [
            #context {
                let imgs-config = cur-imgs-config.get()
                let resolved-cap-size = imgs-config.at("cap-size")
                let resolved-cap-weight = imgs-config.at("cap-weight")
                [
                    #block(width: width)[
                        #set text(font: fonts.mono, size: resolved-cap-size, weight: resolved-cap-weight)
                        #show raw: set text(font: fonts.mono, size: resolved-cap-size, weight: resolved-cap-weight)
                        #caption
                    ]
                    #v(-0.8em)
                ]
            }
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
    dir: ltr,
    width: 100%,
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
    if count == 0 {
        []
    } else {
        let parsed = items.map(item => {
            if type(item) == array {
                (source: item.at(0), caption: item.at(1, default: none))
            } else {
                (source: item, caption: none)
            }
        })
        let is-vertical = dir == ttb or dir == btt
        let ordered = if dir == rtl or dir == btt { parsed.rev() } else { parsed }

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

        let render-image = (source, resolved-width, resolved-height) => {
            if type(source) == str or type(source) == bytes {
                if resolved-height == auto {
                    image(source, width: resolved-width)
                } else {
                    image(source, width: resolved-width, height: resolved-height, fit: img-fit)
                }
            } else {
                block(width: resolved-width)[
                    #if resolved-height == auto [
                        #set image(width: 100%)
                        #source
                    ] else [
                        #set image(width: 100%, height: resolved-height, fit: img-fit)
                        #source
                    ]
                ]
            }
        }

        let render-cell = (source, resolved-width, resolved-height) => {
            let img = render-image(source, resolved-width, resolved-height)
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

        let has-captions = ordered.any(it => it.caption != none)

        context {
            let imgs-config = cur-imgs-config.get()
            let resolved-fill-height = if fill-height == auto { imgs-config.at("fill-height") } else { fill-height }
            let resolved-fill-pad = if fill-pad == auto { imgs-config.at("fill-pad") } else { fill-pad }
            let slide-margins = slide-layouts.at(cur-ar.get())
            let resolved-left-margin = measure(h(slide-margins.left)).width
            let resolved-right-margin = measure(h(slide-margins.right)).width

            let wrap-body = (body, available-width) => {
                let full-slide-width = page.width - resolved-left-margin - resolved-right-margin
                let use-bleed = available-width >= full-slide-width

                if use-bleed {
                    bleed(align(center)[#body])
                } else {
                    block(width: 100%)[
                        #align(center)[#body]
                    ]
                }
            }

            if is-vertical {
                let vertical-item = (item, resolved-height, available-width: auto) => {
                    let target-height = if resolved-height == auto { img-height } else { resolved-height }
                    let resolved-item = render-cell(item.source, if target-height == auto { img-width } else { 100% }, target-height)
                    if resolved-height != auto and available-width != auto {
                        let natural-item-height = measure(
                            box(width: width)[#render-cell(item.source, img-width, auto)],
                            width: available-width,
                        ).height
                        if natural-item-height < target-height {
                            block(width: 100%, height: target-height)[
                                #align(bottom + center)[#render-cell(item.source, img-width, auto)]
                            ]
                        } else {
                            resolved-item
                        }
                    } else {
                        resolved-item
                    }
                }

                let vertical-stack = (resolved-height, available-width: auto) => block(width: 100%)[
                    #for ((index, item)) in ordered.enumerate() [
                        #block(
                            spacing: 0pt,
                            below: if item.caption != none { cap-gap } else { 0pt },
                        )[
                            #vertical-item(item, resolved-height, available-width: available-width)
                        ]
                        #if item.caption != none [
                            #align(center)[
                                #render-caption(item.caption)
                            ]
                        ]
                        #if index < count - 1 [
                            #v(gap)
                        ]
                    ]
                ]

                if resolved-fill-height {
                    layout(size => context {
                        let pos = here().position()
                        let top-margin = measure(v(slide-margins.top)).height
                        let footer-layout = footer-layouts.at(cur-ar.get())
                        let footer-height = measure({
                            set text(size: footer-layout.text-size)
                            v(footer-layout.height)
                        }).height
                        let caption-height = ordered.map(item => {
                            if item.caption == none {
                                0pt
                            } else {
                                measure(render-caption(item.caption), width: size.width).height + measure(v(cap-gap)).height
                            }
                        }).sum(default: 0pt)
                        let stack-gap-height = if count > 1 {
                            measure(v(gap)).height * (count - 1)
                        } else {
                            0pt
                        }
                        let pad-height = measure(v(resolved-fill-pad)).height
                        let remaining-height = calc.max(0pt, size.height + top-margin - pos.y)
                        let resolved-height = calc.max(
                            0pt,
                            remaining-height - footer-height - pad-height - caption-height - stack-gap-height,
                        ) / count
                        [
                            #place(left)[
                                #wrap-body(
                                    box(width: width)[
                                        #vertical-stack(resolved-height, available-width: size.width)
                                    ],
                                    size.width,
                                )
                            ]
                            #v(remaining-height, weak: true)
                        ]
                    })
                } else {
                    layout(size => wrap-body(
                        box(width: width)[
                            #vertical-stack(auto)
                        ],
                        size.width,
                    ))
                }
            } else {
                let col-widths = if widths == auto {
                    range(count).map(_ => 1fr)
                } else { widths }

                let cols = ()
                for (i, w) in col-widths.enumerate() {
                    cols.push(w)
                    if i < count - 1 { cols.push(gap) }
                }

                let single-image = resolved-height => {
                    let item = ordered.at(0)
                    let resolved-width = if resolved-height == auto { img-width } else { 100% }
                    render-cell(item.source, resolved-width, resolved-height)
                }

                let images-grid = resolved-height => block(width: 100%)[
                    #if count == 1 {
                        single-image(resolved-height)
                    } else {
                        grid(
                            columns: cols,
                            align: (center + valign,) * (count * 2 - 1),
                            rows: (auto,),
                            ..ordered.enumerate().map(((i, item)) => {
                                // Fit images to their grid cell width by default to avoid overflow across pages.
                                // (Slide decks prioritize predictable layout over intrinsic image sizing.)
                                let cell = render-cell(item.source, img-width, resolved-height)
                                if i < count - 1 { (cell, []) } else { (cell,) }
                            }).flatten()
                        )
                    }
                ]

                let captions-body = if count == 1 {
                    let item = ordered.at(0)
                    if item.caption != none {
                        align(center)[
                            #render-caption(item.caption)
                        ]
                    } else {
                        []
                    }
                } else {
                    grid(
                        columns: cols,
                        align: (center,) * (count * 2 - 1),
                        ..ordered.enumerate().map(((i, item)) => {
                            let cell = if item.caption != none {
                                render-caption(item.caption)
                            } else { [] }
                            if i < count - 1 { (cell, []) } else { (cell,) }
                        }).flatten()
                    )
                }

                let captions-grid = block(width: 100%)[#captions-body]

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
                        let natural-grid-height = if has-captions {
                            measure(
                                box(width: width)[#images-grid(auto)],
                                width: size.width,
                            ).height
                        } else {
                            none
                        }
                        let resolved-images-body = if has-captions and natural-grid-height != none and natural-grid-height < resolved-height {
                            block(width: 100%, height: resolved-height)[
                                #align(bottom + center)[#images-grid(auto)]
                            ]
                        } else {
                            images-grid(resolved-height)
                        }
                        [
                            #place(left)[
                                #wrap-body(
                                    box(width: width)[
                                        #block(spacing: 0pt, below: cap-gap)[#resolved-images-body]
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
                    layout(size => wrap-body(
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
    }
}
