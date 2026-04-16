// Table styling.

#import "base.typ": fonts

// CONFIG
#let table-config = (
    text-size: 20pt,
    stroke-width: 1pt,
    spacing-above: 0em,
    spacing-below: 0.3em,
)

#let apply-table-style(colors, body) = {
    set table(stroke: (paint: colors.table-stroke, thickness: table-config.stroke-width))
    show table.cell: set text(size: table-config.text-size)
    show table.cell: cell => {
        show raw: set text(font: fonts.mono, size: table-config.text-size)
        cell
    }
    show table: it => [
        #v(table-config.spacing-above)
        #it
        #v(table-config.spacing-below)
    ]
    body
}
