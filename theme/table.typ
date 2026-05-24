// Table styling.

#import "base.typ": cur-colors, cur-font-sizes, fonts

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

// Derive table colors from one accent. The row fills are deterministic tints:
// `lighten(78%)` keeps the accent visible, while `lighten(90%)` gives the
// alternating row a quieter companion tint.
#let banded-table-colors(base) = (
    header-fill: base,
    row-odd-fill: base.lighten(78%),
    row-even-fill: base.lighten(90%),
)

// Presentation table preset with a colored header and banded body rows.
#let banded-table(
    columns: auto,
    header: none,
    palette: "primary",
    center-cols: (),
    text-size: 24pt,
    header-text-size: 24pt,
    header-fill: auto,
    header-text-fill: white,
    row-odd-fill: auto,
    row-even-fill: auto,
    stroke: 1pt + white,
    inset: (left: 0.25em, right: 0em, top: 0.3em, bottom: 0.3em),
    header-inset: (left: 0em, right: 0em, top: 0.25em, bottom: 0.3em),
    header-repeat: true,
    align: left,
    ..cells,
) = context {
    assert(columns != auto, message: "banded-table: `columns` is required")
    assert(header != none, message: "banded-table: `header` is required")

    let colors = cur-colors.get()
    let column-count = columns.len()
    let palettes = (
        primary: banded-table-colors(colors.primary),
        blue: banded-table-colors(rgb("#536fb8")),
    )
    assert(palette in palettes.keys(), message: "banded-table: unknown palette `" + palette + "`")
    let palette-colors = palettes.at(palette)
    let header-fill = if header-fill == auto {
        palette-colors.header-fill
    } else {
        header-fill
    }
    let row-odd-fill = if row-odd-fill == auto {
        palette-colors.row-odd-fill
    } else {
        row-odd-fill
    }
    let row-even-fill = if row-even-fill == auto {
        palette-colors.row-even-fill
    } else {
        row-even-fill
    }
    let cell-align = (x, y) => {
        let horizontal = if y == 0 or x in center-cols { center } else { align }
        horizontal + horizon
    }
    let cell-fill = (x, y) => {
        if y == 0 {
            header-fill
        } else if calc.odd(y) {
            row-odd-fill
        } else {
            row-even-fill
        }
    }

    let render-cell = ((i, cell)) => {
        let row = calc.floor(i / column-count)
        let col = calc.rem(i, column-count)
        let is-header = row == 0
        table.cell(x: col, y: row)[
            #text(
                size: if is-header { header-text-size } else { text-size },
                weight: if is-header { "black" } else { "medium" },
                fill: if is-header {
                    header-text-fill
                } else {
                    colors.fg
                },
            )[#cell]
        ]
    }

    let all-cells = header + cells.pos()
    let rendered-cells = all-cells.enumerate().map(render-cell)

    show table.cell: cell => {
        show raw: set text(
            font: fonts.mono,
            size: if cell.y == 0 { header-text-size } else { text-size },
        )
        cell
    }

    table(
        columns: columns,
        inset: (x, y) => if y == 0 { header-inset } else { inset },
        align: cell-align,
        fill: cell-fill,
        stroke: stroke,
        table.header(repeat: header-repeat, ..rendered-cells.slice(0, column-count)),
        ..rendered-cells.slice(column-count),
    )
}
