// Table styling.

// CONFIG
#let table-config = (
    stroke-width: 0.6pt,
    spacing-above: 0.2em,
    spacing-below: 0em,
)

#let apply-table-style(colors) = {
    show table: it => block(
        above: table-config.spacing-above,
        below: table-config.spacing-below,
    )[
        #set table(stroke: (paint: colors.table-stroke, thickness: table-config.stroke-width))
        #it
    ]
}
