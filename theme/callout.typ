#import "@preview/shadowed:0.3.0": shadow as draw-shadow

#import "base.typ": bleed as bleed-block, cur-colors, cur-font-sizes
#import "emph.typ": apply-emph-style

// CONFIG
// Defaults for every callout knob; override per call with a partial dict:
// `#callout(config: (shadow-blur: 8pt, width: 80%))[...]`. Unknown keys fail.
#let callout-config = (
    width: 100%,
    // `auto` = the aspect ratio's `callout` font size.
    size: auto,
    inset: (left: 0em, right: 0em, top: 0.5em, bottom: 0.5em),
    // `auto` = the uniform `flow` gap (paragraph spacing).
    above: auto,
    below: auto,
    radius: 0pt,
    // `auto` = `stroke-width` in the color style's `stroke-fill`.
    stroke: auto,
    stroke-width: 1pt,
    alignment: center,
    weight: "bold",
    leading: 0em,
    tracking: 0.05em,
    shadow: true,
    // `auto` resolves to the mode's `colors.shadow` (dark mode uses a light glow).
    shadow-fill: auto,
    shadow-blur: 4pt,
    shadow-spread: 1pt,
    shadow-dx: 0pt,
    shadow-dy: 0pt,
    bleed: true,
    breakable: false,
)

#let callout-colors(colors) = (
    // "white" is the mode's brightest surface: white in light mode, a light
    // banner on dark pages.
    white: (
        fill: colors.neutral-lightest,
        text-fill: colors.neutral-darkest,
        emph-fill: colors.primary,
        stroke-fill: colors.neutral-lightest,
    ),
    // Fixed Berkeley brand banner; deliberately mode-independent.
    blue: (
        fill: rgb("#003262"),
        text-fill: white,
        emph-fill: rgb("#FDB515"),
        stroke-fill: rgb("#003262"),
    ),
    primary: (
        fill: colors.primary,
        text-fill: colors.on-primary,
        emph-fill: colors.secondary,
        stroke-fill: colors.primary,
    ),
)

// High-emphasis banner/callout.
// Inside the box, `_emph_` and `*strong*` text use the emphasis color.
// `color` is a name from `callout-colors` or a partial style dict merged over
// the "white" style, e.g. `color: (fill: ..., emph-fill: ...)`.
#let callout(body, color: "white", config: (:)) = context {
    for key in config.keys() {
        assert(key in callout-config, message: "callout: unknown config key `" + key + "`")
    }
    let cfg = callout-config + config

    let colors = cur-colors.get()
    let font-sizes = cur-font-sizes.get()
    let color-styles = callout-colors(colors)
    // `red` is a historical alias from when the primary accent was red.
    let color = if color == "red" { "primary" } else { color }
    let style = if type(color) == str {
        assert(color in color-styles, message: "callout: unknown color `" + color + "`")
        color-styles.at(color)
    } else {
        assert(type(color) == dictionary, message: "callout: color must be a name or a style dictionary")
        for key in color.keys() {
            assert(key in color-styles.white, message: "callout: unknown color key `" + key + "`")
        }
        color-styles.white + color
    }
    let size = if cfg.size == auto { font-sizes.callout } else { cfg.size }
    let stroke = if cfg.stroke == auto { cfg.stroke-width + style.stroke-fill } else { cfg.stroke }
    let shadow-fill = if cfg.shadow-fill == auto { colors.shadow } else { cfg.shadow-fill }

    let body-block = block(
        breakable: cfg.breakable,
        width: 100%,
        fill: style.fill,
        stroke: stroke,
        radius: cfg.radius,
        inset: cfg.inset,
    )[
        #show: apply-emph-style.with(
            emph-fill: style.emph-fill,
            strong-fill: style.emph-fill,
            weight: cfg.weight,
            tracking: cfg.tracking,
        )
        #set par(leading: cfg.leading)
        #align(cfg.alignment)[
            #text(fill: style.text-fill, size: size, weight: cfg.weight, tracking: cfg.tracking)[#body]
        ]
    ]

    let out = block(width: cfg.width, breakable: false)[
        #if cfg.shadow != none and cfg.shadow != false {
            draw-shadow(
                dx: cfg.shadow-dx,
                dy: cfg.shadow-dy,
                blur: cfg.shadow-blur,
                spread: cfg.shadow-spread,
                fill: shadow-fill,
                radius: cfg.radius,
            )[#body-block]
        } else {
            body-block
        }
    ]

    // `above`/`below` must sit on the outermost block: spacing on a block
    // nested inside the bleed wrapper never reaches the outer flow.
    block(above: cfg.above, below: cfg.below, breakable: false)[
        #if cfg.bleed { bleed-block(out) } else { out }
    ]
}

#let bluecallout(body, config: (:)) = callout(body, color: "blue", config: config)
// Fills with the theme primary accent; the `red*` names are historical aliases.
#let primarycallout(body, config: (:)) = callout(body, color: "primary", config: config)
#let redcallout = primarycallout
#let bcallout = bluecallout
#let rcallout = redcallout
