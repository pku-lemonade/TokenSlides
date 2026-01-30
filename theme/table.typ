// Table styling.

// CONFIG
#let table-config = (
    stroke-width: 0.6pt,
)

#let apply-table-style(colors) = {
    show table: set table(stroke: (paint: colors.table-stroke, thickness: table-config.stroke-width))
}

