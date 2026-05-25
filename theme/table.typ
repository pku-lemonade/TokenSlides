// Table styling.

#import "base.typ": cur-ar, cur-colors, cur-font-sizes, cur-footer-style, fonts, slide-layouts
#import "footer.typ": footer-layouts

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

// Presentation table palette. Body fills are deterministic tints, and the
// accent color is reserved for higher-emphasis rows such as totals.
#let vtable-colors(base, accent) = (
    header-fill: base,
    header-text-fill: white,
    row-odd-fill: base.lighten(78%),
    row-even-fill: base.lighten(90%),
    column-odd-fill: base.lighten(82%),
    column-even-fill: base.lighten(94%),
    total-fill: accent.lighten(55%),
    total-text-fill: black,
)

// Presentation table preset with Excel-style table options.
#let vtable(
    columns: auto,
    header: none,
    style: "banded",
    palette: "red",
    center-cols: (),
    text-size: 24pt,
    header-text-size: 24pt,
    column-styles: (),
    fill-height: false,
    fill-pad: 0.3em,
    row-stretch: "content",
    row-weights: auto,
    header-row: true,
    total-row: false,
    first-column: false,
    last-column: false,
    banded-rows: auto,
    banded-columns: auto,
    header-fill: auto,
    header-text-fill: auto,
    row-odd-fill: auto,
    row-even-fill: auto,
    column-odd-fill: auto,
    column-even-fill: auto,
    total-fill: auto,
    total-text-fill: auto,
    stroke: auto,
    inset: (left: 0.25em, right: 0em, top: 0.3em, bottom: 0.3em),
    header-inset: (left: 0em, right: 0em, top: 0.25em, bottom: 0.3em),
    header-repeat: true,
    align: left,
    ..cells,
) = context {
    assert(columns != auto, message: "vtable: `columns` is required")
    assert(style in ("banded", "grid"), message: "vtable: `style` must be \"banded\" or \"grid\"")
    assert(header-row or header == none, message: "vtable: `header` requires `header-row: true`")
    assert(not header-row or header != none, message: "vtable: `header` is required when `header-row` is true")
    assert(row-stretch in ("content", "equal"), message: "vtable: `row-stretch` must be \"content\" or \"equal\"")

    let colors = cur-colors.get()
    let column-count = columns.len()
    assert(column-styles.len() <= column-count, message: "vtable: `column-styles` cannot be longer than `columns`")
    let palettes = (
        red: vtable-colors(colors.primary, colors.secondary),
        blue: vtable-colors(rgb("#003262"), rgb("#FDB515")),
    )
    assert(palette in palettes.keys(), message: "vtable: unknown palette `" + palette + "`")
    let palette-colors = palettes.at(palette)
    let is-grid-style = style == "grid"
    let banded-rows = if banded-rows == auto { not is-grid-style } else { banded-rows }
    let banded-columns = if banded-columns == auto { false } else { banded-columns }
    let default-stroke-paint = if is-grid-style { black } else { white }
    let stroke = if stroke == auto {
        1pt + default-stroke-paint
    } else if type(stroke) == length {
        stroke + default-stroke-paint
    } else {
        stroke
    }
    let has-palette-header-fill = header-fill == true or (header-fill == auto and not is-grid-style)
    let header-fill = if header-fill == auto {
        if is-grid-style { none } else { palette-colors.header-fill }
    } else if header-fill == true {
        palette-colors.header-fill
    } else if header-fill == false {
        none
    } else {
        header-fill
    }
    let header-text-fill = if header-text-fill == auto {
        if has-palette-header-fill { palette-colors.header-text-fill } else { colors.fg }
    } else if header-text-fill == true {
        palette-colors.header-text-fill
    } else if header-text-fill == false {
        colors.fg
    } else {
        header-text-fill
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
    let column-odd-fill = if column-odd-fill == auto {
        palette-colors.column-odd-fill
    } else {
        column-odd-fill
    }
    let column-even-fill = if column-even-fill == auto {
        palette-colors.column-even-fill
    } else {
        column-even-fill
    }
    let total-fill = if total-fill == auto {
        if is-grid-style { none } else { palette-colors.total-fill }
    } else {
        total-fill
    }
    let total-text-fill = if total-text-fill == auto {
        palette-colors.total-text-fill
    } else {
        total-text-fill
    }

    let body-cells = cells.pos()
    if header-row {
        assert(header.len() == column-count, message: "vtable: `header` length must match `columns`")
    }
    assert(
        calc.rem(body-cells.len(), column-count) == 0,
        message: "vtable: body cell count must be a multiple of `columns`",
    )

    let all-cells = if header-row { header + body-cells } else { body-cells }
    let row-count = calc.floor(all-cells.len() / column-count)
    let header-offset = if header-row { 1 } else { 0 }
    let body-row-count = row-count - header-offset
    let total-row-index = row-count - 1
    if row-weights != auto {
        assert(row-weights.len() == body-row-count, message: "vtable: `row-weights` length must match body row count")
    }
    let col-style = col => if col < column-styles.len() {
        column-styles.at(col)
    } else {
        (:)
    }
    let style-value = (style, key, default) => style.at(key, default: default)
    let cell-align = (x, y) => {
        let is-header = header-row and y == 0
        let style = col-style(x)
        let default-align = if is-header or x in center-cols { center } else { align }
        let horizontal = if is-header {
            style-value(style, "header-align", default-align)
        } else {
            style-value(style, "align", default-align)
        }
        horizontal + horizon
    }
    let cell-fill = (x, y) => {
        let is-header = header-row and y == 0
        let is-total = total-row and y == total-row-index
        let body-row = y - header-offset
        let style = col-style(x)
        let default-fill = if is-header {
            header-fill
        } else if is-total {
            total-fill
        } else if banded-rows {
            if calc.odd(body-row + 1) { row-odd-fill } else { row-even-fill }
        } else if banded-columns {
            if calc.odd(x + 1) { column-odd-fill } else { column-even-fill }
        } else {
            none
        }
        if is-header {
            style-value(style, "header-cell-fill", default-fill)
        } else {
            style-value(style, "cell-fill", default-fill)
        }
    }

    let cell-inset = (x, y) => {
        let style = col-style(x)
        if header-row and y == 0 {
            style-value(style, "header-inset", header-inset)
        } else {
            style-value(style, "inset", inset)
        }
    }

    let render-cell-at = (col, local-row, global-row, cell) => {
        let style = col-style(col)
        let is-header = header-row and global-row == 0
        let is-total = total-row and global-row == total-row-index
        let is-first-column = first-column and not is-header and col == 0
        let is-last-column = last-column and not is-header and col == column-count - 1
        let is-emphasis = is-header or is-total or is-first-column or is-last-column
        let default-size = if is-header { header-text-size } else { text-size }
        let default-weight = if is-emphasis { "black" } else { "medium" }
        let default-fill = if is-header {
            header-text-fill
        } else if is-total {
            total-text-fill
        } else {
            colors.fg
        }
        let size = if is-header {
            style-value(style, "header-text-size", default-size)
        } else {
            style-value(style, "text-size", default-size)
        }
        let weight = if is-header {
            style-value(style, "header-weight", default-weight)
        } else {
            style-value(style, "weight", default-weight)
        }
        let fill = if is-header {
            style-value(style, "header-text-fill", default-fill)
        } else {
            style-value(style, "text-fill", default-fill)
        }
        let leading = if is-header {
            style-value(style, "header-leading", auto)
        } else {
            style-value(style, "leading", auto)
        }
        table.cell(x: col, y: local-row)[
            #block(width: 100%)[
                #if leading != auto {
                    set par(leading: leading)
                }
                #show emph: it => text(weight: "black", fill: fill)[#it.body]
                #show strong: it => text(weight: "black", fill: fill)[#it.body]
                #text(size: size, weight: weight, fill: fill)[#cell]
            ]
        ]
    }

    let render-cell = ((i, cell)) => {
        let row = calc.floor(i / column-count)
        let col = calc.rem(i, column-count)
        render-cell-at(col, row, row, cell)
    }

    let rendered-cells = all-cells.enumerate().map(render-cell)
    let table-cells = if header-row {
        let header-cells = (table.header(repeat: header-repeat, ..rendered-cells.slice(0, column-count)),)
        header-cells + rendered-cells.slice(column-count)
    } else {
        rendered-cells
    }

    show table.cell: cell => {
        show raw: set text(
            font: fonts.mono,
            size: if header-row and cell.y == 0 { header-text-size } else { text-size },
        )
        cell
    }

    let render-table = row-tracks => {
        if row-tracks == auto {
            table(
                columns: columns,
                inset: cell-inset,
                align: cell-align,
                fill: cell-fill,
                stroke: stroke,
                ..table-cells,
            )
        } else {
            table(
                columns: columns,
                rows: row-tracks,
                inset: cell-inset,
                align: cell-align,
                fill: cell-fill,
                stroke: stroke,
                ..table-cells,
            )
        }
    }

    let render-measure-row = global-row => {
        let start = global-row * column-count
        let row-cells = all-cells.slice(start, start + column-count)
        let rendered-row-cells = row-cells.enumerate().map(((col, cell)) => {
            render-cell-at(col, 0, global-row, cell)
        })
        table(
            columns: columns,
            rows: (auto,),
            inset: (x, y) => cell-inset(x, global-row),
            align: (x, y) => cell-align(x, global-row),
            fill: (x, y) => cell-fill(x, global-row),
            stroke: stroke,
            ..rendered-row-cells,
        )
    }

    let measure-clean = (body, width) => measure({
        show table: it => it
        body
    }, width: width).height

    let stretch-row-tracks = (target-height, available-width) => {
        let natural-row-heights = range(row-count).map(row => measure-clean(render-measure-row(row), available-width))
        let natural-table-height = measure-clean(render-table(auto), available-width)
        if natural-table-height >= target-height or row-count == 0 {
            auto
        } else {
            let header-height = if header-row { natural-row-heights.at(0) } else { 0pt }
            let body-heights = natural-row-heights.slice(header-offset)
            let body-target-height = calc.max(0pt, target-height - header-height)
            let weights = if row-weights != auto {
                row-weights
            } else if row-stretch == "equal" {
                range(body-row-count).map(_ => 1)
            } else {
                let body-height-sum = body-heights.sum(default: 0pt)
                if body-height-sum == 0pt {
                    range(body-row-count).map(_ => 1)
                } else {
                    body-heights
                }
            }
            let weight-sum = weights.sum(default: 0)
            let body-tracks = if body-row-count == 0 {
                ()
            } else if weight-sum == 0 {
                let equal-height = body-target-height / body-row-count
                range(body-row-count).map(_ => equal-height)
            } else {
                weights.enumerate().map(((i, weight)) => {
                    let natural-height = body-heights.at(i, default: 0pt)
                    calc.max(natural-height, body-target-height * (weight / weight-sum))
                })
            }
            if header-row {
                (header-height,) + body-tracks
            } else {
                body-tracks
            }
        }
    }

    if fill-height {
        layout(size => context {
            let slide-margins = slide-layouts.at(cur-ar.get())
            let top-margin = measure(v(slide-margins.top)).height
            let pos = here().position()
            let footer-height = if cur-footer-style.get() == none {
                0pt
            } else {
                let footer-layout = footer-layouts.at(cur-ar.get())
                measure({
                    set text(size: footer-layout.text-size)
                    v(footer-layout.height)
                }).height
            }
            let pad-height = measure(v(fill-pad)).height
            let remaining-height = calc.max(0pt, size.height + top-margin - pos.y)
            let target-height = calc.max(0pt, remaining-height - footer-height - pad-height)
            let row-tracks = stretch-row-tracks(target-height, size.width)
            block(width: 100%, height: target-height)[
                #show table: it => it
                #render-table(row-tracks)
            ]
        })
    } else {
        render-table(auto)
    }
}
