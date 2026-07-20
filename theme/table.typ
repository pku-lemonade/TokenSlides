// Table styling.

#import "base.typ": cur-ar, cur-colors, cur-font-sizes, font-config, layout-config
#import "emph.typ": apply-emph-style

// CONFIG
// Tables take the uniform `flow` rhythm around them (default block spacing);
// only in-table typography is configured here.
#let table-config = (
    text-size: auto,
    stroke-width: 1pt,
)

#let apply-table-style(colors, body) = {
    context {
        let font-sizes = cur-font-sizes.get()
        let table-text-size = if table-config.text-size == auto { font-sizes.table } else { table-config.text-size }
        set table(stroke: (paint: colors.table-stroke, thickness: table-config.stroke-width))
        show table.cell: set text(size: table-text-size)
        show table.cell: cell => {
            show raw: set text(font: font-config.mono, size: table-text-size)
            cell
        }
        body
    }
}

// Presentation table palette. Body fills are deterministic tints toward the
// page background (so they adapt to light and dark modes), and the accent
// color is reserved for higher-emphasis rows such as totals.
#let vtable-colors(base, accent, colors) = (
    header-fill: base,
    header-text-fill: colors.on-primary,
    row-odd-fill: color.mix((base, 12%), (colors.bg, 88%)),
    row-even-fill: color.mix((base, 5%), (colors.bg, 95%)),
    column-odd-fill: color.mix((base, 10%), (colors.bg, 90%)),
    column-even-fill: color.mix((base, 4%), (colors.bg, 96%)),
    total-fill: color.mix((accent, 22%), (colors.bg, 78%)),
    total-text-fill: colors.fg,
)

#let _vtable-palettes(colors) = (
    primary: vtable-colors(colors.primary, colors.secondary, colors),
    blue: vtable-colors(rgb("#2F6F9F"), rgb("#FDB515"), colors),
)

// Style presets: everything the banded/grid switch controls, as data.
// Color-dependent values are functions of the mode colors; `fills` overrides
// mask palette entries (grid keeps the page fill under the header and total).
#let vtable-styles = (
    // Banded: separators read as page-colored gaps between tinted rows.
    banded: (
        banded-rows: true,
        stroke-paint: colors => colors.bg,
        fills: colors => (:),
    ),
    // Grid: plain ruled table; rules take the text color.
    grid: (
        banded-rows: false,
        stroke-paint: colors => colors.fg,
        fills: colors => (header-fill: none, header-text-fill: colors.fg, total-fill: none),
    ),
)

// Presentation table preset with Excel-style table options.
// Cell colors resolve as palette < style preset < `fills:`; `fills` takes any
// `vtable-colors` key, and the string value "palette" restores the palette
// entry that a style preset masks (e.g. grid + palette header).
#let vtable(
    columns: auto,
    header: none,
    style: "banded",
    palette: "primary",
    fills: (:),
    center-cols: (),
    text-size: 20pt,
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
    banded-columns: false,
    stroke: auto,
    inset: (left: 0.25em, right: 0em, top: 0.3em, bottom: 0.3em),
    header-inset: (left: 0em, right: 0em, top: 0.25em, bottom: 0.3em),
    header-repeat: true,
    align: left,
    ..cells,
) = context {
    // Named arguments that match no parameter would silently land in the
    // `..cells` sink; reject them so typos and removed options fail loudly.
    assert(
        cells.named().len() == 0,
        message: "vtable: unknown options " + cells.named().keys().join(", "),
    )
    assert(columns != auto, message: "vtable: `columns` is required")
    assert(style in vtable-styles, message: "vtable: `style` must be \"banded\" or \"grid\"")
    assert(header-row or header == none, message: "vtable: `header` requires `header-row: true`")
    assert(not header-row or header != none, message: "vtable: `header` is required when `header-row` is true")
    assert(row-stretch in ("content", "equal"), message: "vtable: `row-stretch` must be \"content\" or \"equal\"")

    let colors = cur-colors.get()
    let column-count = columns.len()
    assert(column-styles.len() <= column-count, message: "vtable: `column-styles` cannot be longer than `columns`")
    let palettes = _vtable-palettes(colors)
    // `red` is a historical alias from when the primary accent was red.
    let palette = if palette == "red" { "primary" } else { palette }
    let palette-colors = if type(palette) == str {
        assert(palette in palettes, message: "vtable: unknown palette `" + palette + "`")
        palettes.at(palette)
    } else {
        assert(type(palette) == dictionary, message: "vtable: palette must be a name or a fill dictionary")
        for key in palette.keys() {
            assert(key in palettes.primary, message: "vtable: unknown palette key `" + key + "`")
        }
        palettes.primary + palette
    }
    let style-preset = vtable-styles.at(style)
    for key in fills.keys() {
        assert(key in palettes.primary, message: "vtable: unknown fills key `" + key + "`")
    }
    let fill-of = palette-colors + (style-preset.fills)(colors) + fills
    let fill-of = fill-of
        .pairs()
        .map(((key, value)) => (key, if value == "palette" { palette-colors.at(key) } else { value }))
        .to-dict()
    let banded-rows = if banded-rows == auto { style-preset.banded-rows } else { banded-rows }
    let stroke = if stroke == auto {
        1pt + (style-preset.stroke-paint)(colors)
    } else if type(stroke) == length {
        stroke + (style-preset.stroke-paint)(colors)
    } else {
        stroke
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
            fill-of.header-fill
        } else if is-total {
            fill-of.total-fill
        } else if banded-rows {
            if calc.odd(body-row + 1) { fill-of.row-odd-fill } else { fill-of.row-even-fill }
        } else if banded-columns {
            if calc.odd(x + 1) { fill-of.column-odd-fill } else { fill-of.column-even-fill }
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
        let default-weight = if is-header {
            "bold"
        } else if is-emphasis {
            "black"
        } else {
            "medium"
        }
        let default-fill = if is-header {
            fill-of.header-text-fill
        } else if is-total {
            fill-of.total-text-fill
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
                #set par(leading: leading) if leading != auto
                #show: apply-emph-style.with(emph-fill: fill, strong-fill: fill)
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
            font: font-config.mono,
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
        let rendered-row-cells = row-cells
            .enumerate()
            .map(((col, cell)) => {
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

    let measure-clean = (body, width) => {
        measure(
            {
                show table: it => it
                body
            },
            width: width,
        ).height
    }

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
                weights
                    .enumerate()
                    .map(((i, weight)) => {
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
            let slide-margins = layout-config.at(cur-ar.get()).margins
            let top-margin = measure(v(slide-margins.top)).height
            let pos = here().position()
            let pad-height = measure(v(fill-pad)).height
            let remaining-height = calc.max(0pt, size.height + top-margin - pos.y)
            let target-height = calc.max(0pt, remaining-height - pad-height)
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
