#import "base.typ": cur-colors

// One shared silhouette for short process arrows, plus one shared CeTZ style
// for relationship connectors. Diagram geometry and semantic colors remain the
// caller's responsibility.
#let arrow-config = (
    solid: (
        length: 26pt,
        thickness: 18pt,
        head-start: 60%,
        shaft-inset: 28%,
    ),
    connector: (
        thickness: 1.05pt,
        head-scale: 0.72,
    ),
)

// A short, filled process arrow for placement between boxes or stages.
// `length` follows `dir`; `thickness` is the cross-axis size.
#let solid-arrow(
    fill: auto,
    dir: ltr,
    length: auto,
    thickness: auto,
) = context {
    assert(
        dir in (ltr, rtl, ttb, btt),
        message: "solid-arrow: dir must be ltr, rtl, ttb, or btt",
    )

    let cfg = arrow-config.solid
    let resolved-fill = if fill == auto { cur-colors.get().primary } else { fill }
    let resolved-length = if length == auto { cfg.length } else { length }
    let resolved-thickness = if thickness == auto { cfg.thickness } else { thickness }
    let points = (
        (0%, cfg.shaft-inset),
        (cfg.head-start, cfg.shaft-inset),
        (cfg.head-start, 0%),
        (100%, 50%),
        (cfg.head-start, 100%),
        (cfg.head-start, 100% - cfg.shaft-inset),
        (0%, 100% - cfg.shaft-inset),
    )
    let orient = point => {
        let x = point.at(0)
        let y = point.at(1)
        if dir == ltr {
            (x, y)
        } else if dir == rtl {
            (100% - x, y)
        } else if dir == ttb {
            (y, x)
        } else {
            (y, 100% - x)
        }
    }
    let width = if dir in (ltr, rtl) { resolved-length } else { resolved-thickness }
    let height = if dir in (ltr, rtl) { resolved-thickness } else { resolved-length }

    align(center + horizon)[
        #box(width: width, height: height)[
            #polygon(
                fill: resolved-fill,
                stroke: none,
                ..points.map(orient),
            )
        ]
    ]
}

// CeTZ line/bezier style for a thin semantic connector. The returned
// dictionary is spread directly into a draw call: `line(a, b, ..style)`.
#let connector-arrow(
    color,
    thickness: auto,
    head-scale: auto,
    dash: none,
) = {
    let cfg = arrow-config.connector
    let resolved-thickness = if thickness == auto { cfg.thickness } else { thickness }
    let resolved-head-scale = if head-scale == auto { cfg.head-scale } else { head-scale }
    let stroke = (paint: color, thickness: resolved-thickness)
    if dash != none {
        stroke.insert("dash", dash)
    }
    (
        stroke: stroke,
        mark: (end: "stealth", fill: color, scale: resolved-head-scale),
    )
}
