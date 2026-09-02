#import "base.typ": font-config, theme
#import "assets.typ": asset-path, lemonade-qr
#import "boxes.typ": box-item

// CONFIG
// Default image options plus the caption style shared by every row item;
// deck-level overrides merge in via `lemonade-theme(img-config: ...)`.
// `cap-size: auto` resolves to the current aspect ratio's `small` font size.
//
// How a figure is PLACED is not here: `img` is a `vboxs` row item, so the row
// owns width, direction, gaps, bleed, and whether it fills the slide — see
// `vboxs-config` in boxes.typ.
#let img-config = (
    cap-size: auto,
    cap-weight: "bold",
    // `auto` = a hairline in the mode's table-stroke color; `none` = no frame.
    border: auto,
    border-radius: 0pt,
    inset: 0pt,
    fit: "contain",
    // Gap between a figure and its caption.
    cap-gap: 0.2em,
)

// The deck's `img` defaults: `lemonade-theme(img-config: ...)` merged over `img-config`.
#let _img-config() = theme().at("img", default: img-config)

// Shared caption styling for `place-image` and `img`. `auto` values resolve
// from the deck's `img` config; `cap-color: auto` keeps the surrounding text color.
#let _caption-block(caption, cap-size: auto, cap-weight: auto, cap-color: auto) = context {
    let font-sizes = theme().font-sizes
    let img-config = _img-config()
    let resolved-cap-size = if cap-size != auto {
        cap-size
    } else if img-config.cap-size != auto {
        img-config.cap-size
    } else {
        font-sizes.small
    }
    let cap-text-args = (
        font: font-config.mono,
        size: resolved-cap-size,
        weight: if cap-weight == auto { img-config.cap-weight } else { cap-weight },
    )
    if cap-color != auto { cap-text-args.insert("fill", cap-color) }
    block(width: 100%)[
        #set text(..cap-text-args)
        // Keep inline code and wrapped lines on the same caption sizing path.
        #show raw: set text(..cap-text-args)
        #caption
    ]
}

// Shared row-item caption. The row measures this `foot` across every item and
// reserves one band for the tallest, keeping media bottoms and caption baselines
// aligned. `img`, `code`, and foreign row items all use this one path.
#let caption-foot(
    caption,
    cap-size: auto,
    cap-weight: auto,
    cap-color: auto,
    cap-gap: auto,
) = if caption == none { none } else {
    context {
        v(if cap-gap == auto { _img-config().cap-gap } else { cap-gap })
        block(width: 100%, spacing: 0pt)[
            #align(center)[
                #_caption-block(
                    caption,
                    cap-size: cap-size,
                    cap-weight: cap-weight,
                    cap-color: cap-color,
                )
            ]
        ]
    }
}

// Floating figure anchored to a slide corner. `source` is an image path or a
// per-mode variant dict from `theme/assets.typ` (e.g. `pku-logo`).
#let place-image(
    source,
    caption: none,
    width: 25%,
    height: auto,
    fit: "contain",
    position: top + right,
    dx: 0em,
    dy: 0em,
    cap-gap: 0.4em,
) = place(position, dx: dx, dy: dy)[
    #align(center)[
        #if caption != none [
            #block(width: width, spacing: 0pt, below: cap-gap)[#_caption-block(caption)]
        ]
        #context {
            let path = asset-path(source)
            if height == auto {
                image(path, width: width)
            } else {
                image(path, width: width, height: height, fit: fit)
            }
        }
    ]
]

// Presets over `place-image` — identical API, tuned defaults.
#let place-logo(source, width: 10%, ..args) = place-image(
    source,
    width: width,
    dx: -0.5em,
    dy: -1em,
    position: top + right,
    ..args,
)
// The source defaults to the repo QR: `#place-qr()`,
// `#place-qr(caption: "pku-lemonade")`, `#place-qr("/path/to/other-qr.png")`.
#let place-qr(..args) = {
    assert(args.pos().len() <= 1, message: "place-qr takes at most one source")
    place-image(
        args.pos().at(0, default: lemonade-qr),
        width: 20%,
        position: bottom + right,
        ..args.named(),
    )
}

// One figure, as a `vboxs` row item. The row decides how much height this gets
// (`height`), and lays the caption out itself from the spec's `foot` — see
// `box-item` in boxes.typ. `height` is a definite length inside a row, `auto`
// standing alone or when the row is not filling.
//
// A definite height is handed straight to the image with `fit`, so `contain`
// letterboxes a figure whose aspect ratio does not match its slot rather than
// distorting it, and the figure sits centered in what it was given.
#let _render-img(spec, height: auto, outer-spacing: true) = context {
    let colors = theme().colors
    let cfg = _img-config()
    let pick = (value, key) => if value == auto { cfg.at(key) } else { value }
    let stroke = {
        let border = pick(spec.border, "border")
        // The config's own `auto` is the mode-dependent hairline; only a
        // resolved color or `none` gets past here.
        if border == auto { 1pt + colors.table-stroke } else { border }
    }
    let target = if height != auto { height } else { spec.height }

    // A `set` rule sizes the image whether the caller passed a path or ready-made
    // `image(...)` content, and leaves an explicit `image(width: ...)` alone.
    let figure-body = block(width: spec.width)[
        #if target == auto [
            #set image(width: 100%)
            #spec.body
        ] else [
            #set image(width: 100%, height: target, fit: pick(spec.fit, "fit"))
            #spec.body
        ]
    ]
    let framed = if stroke == none {
        figure-body
    } else {
        box(
            stroke: stroke,
            radius: pick(spec.border-radius, "border-radius"),
            clip: true,
            inset: pick(spec.inset, "inset"),
            figure-body,
        )
    }

    block(
        width: 100%,
        height: target,
        above: if outer-spacing { auto } else { 0pt },
        below: if outer-spacing { auto } else { 0pt },
        spacing: 0pt,
    )[
        #align(center + horizon)[#framed]
    ]
}

// `#img(source)` or `#img(source, [caption])`, where `source` is a path or
// ready-made `image(...)` content. (The per-mode `(light:, dark:)` variant dicts
// that `place-xx` resolves are for logos, and are not accepted here.)
//
// The result is a `vboxs` row item, which is the only image layout in this
// theme: `#vboxs(img(a), img(b))` puts two figures side by side at one height,
// `dir: ttb` stacks them, and `after:` hangs content under the row. A bare
// `#img(...)` renders on its own at its natural size, the same way a bare
// `#code[...]` does.
#let img(
    ..args,
    width: 100%,
    height: auto,
    fit: auto,
    border: auto,
    border-radius: auto,
    inset: auto,
    cap-size: auto,
    cap-weight: auto,
    cap-color: auto,
    cap-gap: auto,
) = {
    let pos = args.pos()
    assert(
        pos.len() == 1 or pos.len() == 2,
        message: "img: use #img(source) or #img(source, [caption])",
    )
    // The sink is here only to take one or two positionals; every option this
    // figure has is a named parameter above. Without this an unknown named
    // argument would land in the sink and be silently dropped.
    let unknown = args.named().keys()
    if unknown.len() > 0 {
        // Revealing belongs to the row, not to one figure in it (see `vboxs`).
        let hint = if "step" in unknown { " — `step` belongs on the row: `vboxs(img(..), .., step: ..)`" } else { "" }
        panic("img: unknown option `" + unknown.first() + "`" + hint)
    }
    // A ratio has nothing to resolve against here: in a filling row the row
    // hands down a length and this is ignored, and in a non-filling one the row
    // measures the figure at its natural size first, where `50%` of an
    // as-yet-unknown height measures as nothing and the figure silently
    // vanishes. Filling a container is the row's job.
    assert(
        height == auto or type(height) == length,
        message: "img: `height` takes a length; for a figure that fills its container, "
            + "let the row do it — `vboxs(img(..), fill-height: true)`",
    )
    let source = pos.at(0)
    let caption = pos.at(1, default: none)
    let body = if type(source) == str or type(source) == bytes { image(source) } else { source }
    // The caption travels as the item's `foot`, so the ROW can measure every
    // caption in it together and give the figures above them one shared height.
    let foot = caption-foot(
        caption,
        cap-size: cap-size,
        cap-weight: cap-weight,
        cap-color: cap-color,
        cap-gap: cap-gap,
    )
    box-item(
        (
            kind: "img",
            render: _render-img,
            foot: foot,
            width: width,
            height: height,
            fit: fit,
            border: border,
            border-radius: border-radius,
            inset: inset,
        ),
        body,
    )
}
