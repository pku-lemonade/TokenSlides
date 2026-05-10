// Table styling.

#import "base.typ": cur-font-sizes, fonts

// CONFIG
#let table-config = (
    text-size: auto,
    stroke-width: 1pt,
    spacing-above: 0em,
    spacing-below: 0.3em,
)

#let apply-table-style(colors, body) = {
    context {
        let font-sizes = cur-font-sizes.get()
        let table-text-size = if table-config.text-size == auto { font-sizes.table } else { table-config.text-size }
        set table(stroke: (paint: colors.table-stroke, thickness: table-config.stroke-width))
        show table.cell: set text(size: table-text-size)
        show table.cell: cell => {
            show raw: set text(font: fonts.mono, size: table-text-size)
            cell
        }
        show table: it => [
            #v(table-config.spacing-above)
            #it
            #v(table-config.spacing-below)
        ]
        body
    }
}
