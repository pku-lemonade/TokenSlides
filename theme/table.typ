// Table styling.

// CONFIG
#let table-config = (
    text-size: 20pt,
    stroke-width: 1pt,
    spacing-above: 0em,
    spacing-below: 0.3em,
)

#let apply-table-style(colors) = {
    show table: it => [
        #v(table-config.spacing-above)
        #set text(size: table-config.text-size)
        #set table(stroke: (paint: colors.table-stroke, thickness: table-config.stroke-width))
        #it
        #v(table-config.spacing-below)
    ]
}
