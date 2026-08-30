// Table styling.

#import "base.typ": cur-ar, cur-colors, cur-font-sizes, font-config, layout-config
#import "boxes.typ": box-item
#import "emph.typ": apply-emph-style

// CONFIG
// Tables take the uniform `flow` rhythm around them (default block spacing);
// `vtable` keeps content (`columns`, `header`, and cells) at the call site,
// while every optional presentation-table default lives under `vtable`.
#let table-config = (
    text-size: auto,
    stroke-width: 1pt,
    vtable: (
        style: "banded",
        palette: "primary",
        fills: (:),
        center-cols: (),
        text-size: 20pt,
        header-text-size: 24pt,
        weight: "medium",
        header-weight: "bold",
        emphasis-weight: "black",
        leading: auto,
        header-leading: auto,
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
        header-inset: (left: 0em, right: 0em, top: 0.3em, bottom: 0.35em),
        header-repeat: true,
        align: left,
        header-align: center,
    ),
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

// Presentation table preset with Excel-style table options. Cells may use
// `table.cell(rowspan: n)`; Typst owns placement and the scoped cell rule styles
// the resolved coordinates without wrapping cells a second time.
#let _layout-vtable(
    item-height,
    outer-spacing,
    columns: auto,
    header: none,
    style: table-config.vtable.style,
    palette: table-config.vtable.palette,
    fills: table-config.vtable.fills,
    center-cols: table-config.vtable.center-cols,
    text-size: table-config.vtable.text-size,
    header-text-size: table-config.vtable.header-text-size,
    weight: table-config.vtable.weight,
    header-weight: table-config.vtable.header-weight,
    emphasis-weight: table-config.vtable.emphasis-weight,
    leading: table-config.vtable.leading,
    header-leading: table-config.vtable.header-leading,
    column-styles: table-config.vtable.column-styles,
    fill-height: table-config.vtable.fill-height,
    fill-pad: table-config.vtable.fill-pad,
    row-stretch: table-config.vtable.row-stretch,
    row-weights: table-config.vtable.row-weights,
    header-row: table-config.vtable.header-row,
    total-row: table-config.vtable.total-row,
    first-column: table-config.vtable.first-column,
    last-column: table-config.vtable.last-column,
    banded-rows: table-config.vtable.banded-rows,
    banded-columns: table-config.vtable.banded-columns,
    stroke: table-config.vtable.stroke,
    inset: table-config.vtable.inset,
    header-inset: table-config.vtable.header-inset,
    header-repeat: table-config.vtable.header-repeat,
    align: table-config.vtable.align,
    header-align: table-config.vtable.header-align,
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
    assert(column-count > 0, message: "vtable: `columns` cannot be empty")
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
    let cell-field = (cell, key, default) => if type(cell) == content and cell.func() == table.cell {
        cell.fields().at(key, default: default)
    } else {
        default
    }

    let check-cell = (cell, header: false) => {
        assert(cell-field(cell, "x", auto) == auto, message: "vtable: explicit cell `x` is not supported")
        assert(cell-field(cell, "y", auto) == auto, message: "vtable: explicit cell `y` is not supported")
        assert(cell-field(cell, "colspan", 1) == 1, message: "vtable: `colspan` is not supported")
        let rowspan = cell-field(cell, "rowspan", 1)
        assert(type(rowspan) == int and rowspan >= 1, message: "vtable: `rowspan` must be a positive integer")
        assert(not header or rowspan == 1, message: "vtable: header cells cannot span rows")
    }
    if header-row { for cell in header { check-cell(cell, header: true) } }
    for cell in body-cells { check-cell(cell) }

    // With vertical spans only, each column is one occupied prefix. Native
    // row-major placement therefore picks the shortest column, leftmost on a tie.
    let column-heights = (0,) * column-count
    let anchors = ()
    for cell in body-cells {
        let rowspan = cell-field(cell, "rowspan", 1)
        let y = calc.min(..column-heights)
        let x = column-heights.position(height => height == y)
        anchors.push((cell: cell, x: x, y: y, rowspan: rowspan))
        column-heights.at(x) += rowspan
    }

    let body-row-count = calc.max(..column-heights)
    assert(
        column-heights.all(height => height == body-row-count),
        message: "vtable: body cells and rowspans must fill complete rows",
    )

    let header-offset = if header-row { 1 } else { 0 }
    let row-count = body-row-count + header-offset
    let total-row-index = row-count - 1
    let has-rowspans = anchors.any(anchor => anchor.rowspan > 1)
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
        let default-align = if is-header {
            header-align
        } else if x in center-cols {
            center
        } else {
            align
        }
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

    let style-cell(cell, row-offset: 0) = {
        let col = cell.x
        let row = cell.y + row-offset
        let style = col-style(col)
        let is-header = header-row and row == 0
        let is-total = total-row and row == total-row-index
        let is-first-column = first-column and not is-header and col == 0
        let is-last-column = last-column and not is-header and col == column-count - 1
        let is-emphasis = is-header or is-total or is-first-column or is-last-column
        let default-size = if is-header { header-text-size } else { text-size }
        let default-weight = if is-header {
            header-weight
        } else if is-emphasis {
            emphasis-weight
        } else {
            weight
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
        let cell-leading = if is-header {
            style-value(style, "header-leading", header-leading)
        } else {
            style-value(style, "leading", leading)
        }
        set text(size: size, weight: weight, fill: fill)
        if cell-leading != auto { set par(leading: cell-leading) }
        show raw: set text(font: font-config.mono, size: size)
        show: apply-emph-style.with(emph-fill: fill, strong-fill: fill)
        cell
    }

    let table-cells = if header-row {
        (table.header(repeat: header-repeat, ..header),) + body-cells
    } else {
        body-cells
    }
    let render-table = (body, row-tracks: auto, row-offset: 0) => {
        show table.cell: style-cell.with(row-offset: row-offset)
        let options = (
            columns: columns,
            inset: (x, y) => cell-inset(x, y + row-offset),
            align: (x, y) => cell-align(x, y + row-offset),
            fill: (x, y) => cell-fill(x, y + row-offset),
            stroke: stroke,
        )
        if row-tracks == auto {
            table(..options, ..body)
        } else {
            table(rows: row-tracks, ..options, ..body)
        }
    }

    let render-measure-row = global-row => {
        let row-cells = if header-row and global-row == 0 {
            header
        } else {
            let body-row = global-row - header-offset
            body-cells.slice(body-row * column-count, (body-row + 1) * column-count)
        }
        render-table(row-cells, row-tracks: (auto,), row-offset: global-row)
    }

    let render-measure-cell = anchor => {
        let fields = if type(anchor.cell) == content and anchor.cell.func() == table.cell {
            anchor.cell.fields()
        } else {
            (body: anchor.cell,)
        }
        let body = fields.body
        let placed = if "inset" in fields {
            table.cell(x: anchor.x, y: 0, inset: fields.inset)[#body]
        } else {
            table.cell(x: anchor.x, y: 0)[#body]
        }
        render-table(
            (placed,),
            row-tracks: (auto,),
            row-offset: anchor.y + header-offset,
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
        let natural-table-height = measure-clean(render-table(table-cells), available-width)
        let header-height = if header-row {
            measure-clean(render-measure-row(0), available-width)
        } else {
            0pt
        }
        let body-heights = if has-rowspans {
            // Measure each cell at its real column width. A spanning cell's
            // minimum is shared by the rows it covers; per-row maxima then form
            // safe lower bounds without reimplementing Typst's table layout.
            let minima = (0pt,) * body-row-count
            for anchor in anchors {
                let share = measure-clean(render-measure-cell(anchor), available-width) / anchor.rowspan
                for dy in range(anchor.rowspan) {
                    let row = anchor.y + dy
                    minima.at(row) = calc.max(minima.at(row), share)
                }
            }
            minima
        } else {
            range(body-row-count).map(row => (
                measure-clean(render-measure-row(row + header-offset), available-width)
            ))
        }
        // One-cell proxies cannot reproduce an `auto` track sized from the whole table.
        let span-widths-unknown = has-rowspans and auto in columns
        if natural-table-height >= target-height or row-count == 0 or span-widths-unknown {
            auto
        } else {
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
                        calc.max(body-heights.at(i), body-target-height * (weight / weight-sum))
                    })
            }
            if header-row {
                (header-height,) + body-tracks
            } else {
                body-tracks
            }
        }
    }

    let outer = if outer-spacing { auto } else { 0pt }
    let natural = block(width: 100%, above: outer, below: outer, spacing: 0pt)[
        #show table: it => it
        #render-table(table-cells)
    ]
    let fitted = (target-height, available-width) => {
        let row-tracks = stretch-row-tracks(target-height, available-width)
        block(width: 100%, height: target-height, above: outer, below: outer, spacing: 0pt)[
            #show table: it => it
            #render-table(table-cells, row-tracks: row-tracks)
        ]
    }

    if item-height != auto {
        layout(size => fitted(item-height, size.width))
    } else if fill-height and outer-spacing {
        layout(size => context {
            let slide-margins = layout-config.at(cur-ar.get()).margins
            let top-margin = measure(v(slide-margins.top)).height
            let pos = here().position()
            let pad-height = measure(v(fill-pad)).height
            let remaining-height = calc.max(0pt, size.height + top-margin - pos.y)
            let target-height = calc.max(0pt, remaining-height - pad-height)
            fitted(target-height, size.width)
        })
    } else {
        natural
    }
}

// A `vtable` is also a `vboxs` row item. Rendering stays deferred so the row can
// hand it a definite height; a bare table uses the same row-item show rule as
// boxes, figures, and listings.
#let _render-vtable(spec, height: auto, outer-spacing: true) = _layout-vtable(
    height,
    outer-spacing,
    ..spec.args,
)

#let vtable(..args) = box-item(
    (kind: "vtable", render: _render-vtable, args: args),
    [],
)
