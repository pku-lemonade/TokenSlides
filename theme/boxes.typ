#import "base.typ": (
    bleed as bleed-block, cur-box, cur-box-compact, cur-box-fill, cur-colors, cur-font-sizes, cur-spacing,
    touying-fn-wrapper,
)
#import "emph.typ": apply-emph-style, on-primary

// USER CONFIG
// - Geometry and title typography: edit `box-config` below.
// - Equal-row layout defaults: edit `vboxs-config` below.
// - Accent palettes: edit `light-box-styles` / `dark-box-styles` in base.typ.
// - Body and title font sizes: edit `body` / `body-title` in base.typ.
// - Soft body fills are enabled with `lemonade-theme(box-fill: true)`.
//
// Per-box `compact`, `body-inset`, `title-size`, and `title-inset` override
// these defaults. A dictionary `body-inset` is merged over the selected normal
// or compact inset, so `body-inset: (right: 0pt)` changes only that side.
// A vboxs `title-size` applies to the row unless a box sets its own title size.
// Outer box spacing is not configured here: boxes take the uniform `flow`
// rhythm (see `layout-config` in base.typ) via `auto` block spacing.
#let box-config = (
    normal: (
        body-inset: (left: 0.5em, right: 0.5em, top: 0.75em, bottom: 0.75em),
    ),
    compact: (
        body-inset: (left: 10pt, right: 10pt, top: 0.5em, bottom: 0.5em),
    ),
    accent-width: 5pt,
    title-inset: (left: 0.1em, right: 0.1em, top: 0.5em, bottom: 0.5em),
    title-weight: "bold",
    // Default ink on the accent bar; a box style whose accent is too light
    // for white overrides it per style (`title-text-fill` in base.typ).
    title-text-fill: white,
    title-align: center,
    frame-width: 1pt,
    // With body fills on, hairlines take the box accent at this transparency
    // instead of the neutral table stroke — the tinted edge on a near-white
    // pane is what makes the box read as glass. Lower = stronger edge.
    frame-tint: 70%,
)

// Defaults for `vboxs`, the theme's one row layout — it carries figures (`img`)
// and listings (`code`) as well as boxes, so these are the deck-wide defaults
// for every equal-height row. Deck-level overrides merge in via
// `lemonade-theme(vboxs-config: ...)`; a `vboxs` argument left `auto` takes the
// value from here.
#let vboxs-config = (
    gap: 0.4em,
    // `auto` = the uniform `flow` gap, so `after:` content sits exactly like
    // inline content following the row.
    after-gap: auto,
    fill-height: true,
    fill-pad: 0.3em,
)

// Internal runtime state (set by `lemonade-theme`).
#let cur-vboxs-config = state("lec-vboxs-config", vboxs-config)

#let _box-figure-kind = "lemonade-box"
#let _box-spec-label = <lemonade-box-spec>

// ONE BOX
// -----------------------------------------------------------------------------

// All four sides, or all but the left, where a colored accent column already
// draws that edge and a hairline over it would double it.
#let _frame-stroke(paint, left: true) = {
    let rule = box-config.frame-width + paint
    if left { rule } else { (top: rule, right: rule, bottom: rule) }
}

#let _box-visuals(spec, colors) = {
    let styles = cur-box.get()
    let style = if spec.style == none {
        none
    } else {
        assert(spec.style in styles.keys(), message: "box: unknown style `" + spec.style + "`")
        styles.at(spec.style)
    }
    let accent = if style == none { colors.primary } else { style.border }
    let fill = if style != none and cur-box-fill.get() { style.at("fill", default: none) } else { none }
    let frame-paint = if fill == none { colors.table-stroke } else { accent.transparentize(box-config.frame-tint) }
    (
        accent: accent,
        fill: fill,
        title-ink: if style == none {
            box-config.title-text-fill
        } else {
            style.at("title-text-fill", default: box-config.title-text-fill)
        },
        frame: _frame-stroke(frame-paint),
        frame-no-left: _frame-stroke(frame-paint, left: false),
    )
}

#let _title-content(spec, visuals, font-sizes, row-title-size: none) = {
    let default-size = if row-title-size == none { font-sizes.body-title } else { row-title-size }
    // White ink gets the usual on-primary emphasis (secondary accent); a
    // style-supplied dark ink keeps emphasis in the ink — the secondary
    // yellow would vanish on the light accent that forced the dark ink.
    let title = if visuals.title-ink == box-config.title-text-fill {
        on-primary(spec.title)
    } else {
        apply-emph-style(spec.title, emph-fill: visuals.title-ink, strong-fill: visuals.title-ink)
    }
    text(
        size: spec.at("title-size", default: default-size),
        weight: box-config.title-weight,
        fill: visuals.title-ink,
    )[#title]
}

#let _body-content(spec, font-sizes) = block(width: 100%)[
    #set text(size: font-sizes.body)
    #spec.body
]

#let _body-inset(spec, metrics) = {
    let override = spec.at("body-inset", default: none)
    if override == none {
        metrics.body-inset
    } else if type(override) == dictionary and type(metrics.body-inset) == dictionary {
        metrics.body-inset + override
    } else {
        override
    }
}

// Plain boxes use a separate accent/title column. Keeping it separate from the
// body frame avoids diagonal joins between thick colored and thin neutral rules.
#let _plain-grid(spec, visuals, metrics, font-sizes, height: auto, row-title-size: none) = {
    let has-title = spec.title != none
    let title-inset = spec.at("title-inset", default: box-config.title-inset)
    let body-inset = _body-inset(spec, metrics)
    grid(
        columns: if has-title { (auto, 1fr) } else { (box-config.accent-width, 1fr) },
        rows: if height == auto { (auto,) } else { (1fr,) },
        column-gutter: 0pt,
        inset: (x, y) => if x == 0 { if has-title { title-inset } else { 0pt } } else { body-inset },
        fill: (x, y) => if x == 0 { visuals.accent } else { visuals.fill },
        stroke: (x, y) => if x == 0 { none } else { visuals.frame-no-left },
        align: (x, y) => if x == 0 { box-config.title-align + horizon } else { left + top },
        if has-title { _title-content(spec, visuals, font-sizes, row-title-size: row-title-size) } else { [] },
        _body-content(spec, font-sizes),
    )
}

#let _title-bar(spec, visuals, font-sizes, row-title-size: none) = block(
    width: 100%,
    fill: visuals.accent,
    inset: spec.at("title-inset", default: box-config.title-inset),
    outset: (left: box-config.frame-width / 2, right: box-config.frame-width / 2),
)[
    #align(box-config.title-align)[#_title-content(spec, visuals, font-sizes, row-title-size: row-title-size)]
]

// Titleless top boxes wear a bare accent strip where the title bar would be.
#let _top-accent(visuals) = block(
    width: 100%,
    height: box-config.accent-width,
    fill: visuals.accent,
    outset: (left: box-config.frame-width / 2, right: box-config.frame-width / 2),
)

#let _top-grid(spec, visuals, metrics, font-sizes, height: auto, row-title-size: none) = {
    let body-inset = _body-inset(spec, metrics)
    grid(
        columns: (1fr,),
        rows: if height == auto { (auto, auto) } else { (auto, 1fr) },
        row-gutter: 0pt,
        inset: 0pt,
        if spec.title == none {
            _top-accent(visuals)
        } else {
            _title-bar(spec, visuals, font-sizes, row-title-size: row-title-size)
        },
        block(
            width: 100%,
            height: if height == auto { auto } else { 100% },
            fill: visuals.fill,
            inset: body-inset,
            stroke: visuals.frame,
        )[#_body-content(spec, font-sizes)],
    )
}

// One item at a given height. A spec carrying `render:` belongs to another
// module and is rendered by that function; everything else is a box, and its
// two shapes differ only in which grid goes inside the same outer block.
#let _render-spec(spec, height: auto, outer-spacing: true, row-title-size: none) = if "render" in spec {
    (spec.render)(spec, height: height, outer-spacing: outer-spacing)
} else {
    context {
        let visuals = _box-visuals(spec, cur-colors.get())
        let compact = spec.at("compact", default: cur-box-compact.get())
        let inner = if spec.kind == "plain" { _plain-grid } else { _top-grid }
        // A box on its own takes the uniform flow rhythm; inside a row the row
        // owns the spacing, so the item adds none of its own.
        let outer = if outer-spacing { auto } else { 0pt }
        block(width: 100%, height: height, above: outer, below: outer, spacing: 0pt)[
            #inner(
                spec,
                visuals,
                if compact { box-config.compact } else { box-config.normal },
                cur-font-sizes.get(),
                height: height,
                row-title-size: row-title-size,
            )
        ]
    }
}

// ROW ITEMS
// -----------------------------------------------------------------------------

// Row-item constructor. A box helper — or any other theme module that wants its
// output to compose with `vboxs` — wraps its spec and body with this. A spec
// carrying a `render:` function is rendered by that function instead of by the
// box frames above, which is how `theme/code.typ` joins an equal-height row
// without boxes.typ knowing anything about code listings. The renderer is
// called as `render(spec, height: ..., outer-spacing: ...)` and reads its body
// from `spec.body`; `height` is the item's share of a stretched row, else `auto`.
//
// A spec may also carry `foot:` — content pinned below the item, which the ROW
// lays out rather than the renderer (`_render-cell`). Every foot in a row is
// measured together and the tallest sets one band, so the items above them all
// end at the same line: that is what keeps image captions of different lengths
// from pushing their figures to different heights. A renderer never sees the
// band; it is simply handed a smaller `height`. `theme/images.typ` uses this for
// captions, and an item without a foot (a box, a listing) takes the full height.
#let box-item(spec, body) = figure(
    kind: _box-figure-kind,
    caption: none,
    supplement: none,
    outlined: false,
)[#metadata(spec)<lemonade-box-spec>#body]

#let _item-foot(spec) = spec.at("foot", default: none)

#let _figure-spec(it) = {
    let holder = it.body.fields().at("children", default: ()).find(child => (
        type(child) == content
            and child.func() == metadata
            and child.fields().at("label", default: none) == _box-spec-label
    ))
    assert(holder != none, message: "box: missing internal metadata")
    holder.value
}

#let _with-body(spec, body) = spec + (body: body)

// One cell: the item, and its `foot` under it. `height` is the cell's total and
// `foot-height` the band the row reserved for the tallest foot in it, so the
// item is rendered that much shorter and every foot in the row starts on the
// same line. With no foot the item takes the whole cell, which is what lets a
// captionless box share a row with a captioned figure and still reach the
// bottom. `height: auto` stacks the two at their natural sizes.
#let _render-cell(spec, height: auto, foot-height: 0pt, outer-spacing: true, row-title-size: none) = {
    let foot = _item-foot(spec)
    if foot == none {
        _render-spec(spec, height: height, outer-spacing: outer-spacing, row-title-size: row-title-size)
    } else {
        let outer = if outer-spacing { auto } else { 0pt }
        block(width: 100%, height: height, above: outer, below: outer)[
            #_render-spec(
                spec,
                height: if height == auto { auto } else { calc.max(0pt, height - foot-height) },
                outer-spacing: false,
                row-title-size: row-title-size,
            )
            #foot
        ]
    }
}

// BOX HELPERS
// -----------------------------------------------------------------------------

// `#name[body]`, `#name([title])[body]`, or `#name(title: ...)[body]`.
#let _make-box(kind, style, name, ..args) = {
    let pos = args.pos()
    let named = args.named()
    let options = ("compact", "body-inset", "title-size", "title-inset")
    // Revealing is the ROW's job, never an item's: a stepped row is emitted as a
    // Touying mark that only survives outside a `context` (see `vboxs`), and a box
    // standing on its own is drawn by a show rule, long after Touying parsed the marks.
    assert(
        "step" not in named,
        message: name + ": `step` belongs on the row — `vboxs(.., step: ..)`; "
            + "a box on its own reveals with `#pause`",
    )
    for key in named.keys() {
        assert(key in ("title",) + options, message: name + ": unknown option `" + key + "`")
    }
    assert(pos.len() <= 2, message: name + ": use #" + name + "[body] or #" + name + "([title])[body]")
    assert(not ("title" in named) or pos.len() <= 1, message: name + ": duplicate title")

    let titled = pos.len() == 2
    let spec = (
        kind: kind,
        style: style,
        title: if titled { pos.at(0) } else { named.at("title", default: none) },
    )
    for key in options {
        if key in named { spec.insert(key, named.at(key)) }
    }
    box-item(spec, pos.at(if titled { 1 } else { 0 }, default: []))
}

#let _plain-box = _make-box.with("plain")
#let _top-box = _make-box.with("top")

#let hbox(..args) = _plain-box("highlight", "hbox", ..args)
#let ibox(..args) = _plain-box("info", "ibox", ..args)
#let ebox(..args) = _plain-box("error", "ebox", ..args)
#let sbox(..args) = _plain-box("success", "sbox", ..args)
#let nbox(..args) = _plain-box("neutral", "nbox", ..args)
#let pbox(..args) = _plain-box("purple", "pbox", ..args)

#let vbox(..args) = _top-box(none, "vbox", ..args)
#let vhbox(..args) = _top-box("highlight", "vhbox", ..args)
#let vibox(..args) = _top-box("info", "vibox", ..args)
#let vebox(..args) = _top-box("error", "vebox", ..args)
#let vsbox(..args) = _top-box("success", "vsbox", ..args)
#let vnbox(..args) = _top-box("neutral", "vnbox", ..args)
#let vpbox(..args) = _top-box("purple", "vpbox", ..args)

#let apply-box-style(body) = {
    show figure.where(kind: _box-figure-kind): set align(left)
    // A figure is placed as one unbreakable unit, and Typst DROPS one that does
    // not fit its region: no warning, no partial render, the slide simply comes
    // out empty. Box items are figures only so a spec can ride along with the
    // body (`box-item`), so that placement rule buys this theme nothing and
    // costs it silent content loss. Breakable, an over-tall box spills onto the
    // next page instead — still wrong for a slide, but wrong where it shows.
    //
    // This reaches the blocks inside a box as well, so a frame splits rather
    // than being pushed along whole. A block that passes `breakable:` itself
    // still wins, which is why `code-config.breakable` is on.
    show figure.where(kind: _box-figure-kind): set block(breakable: true)
    // Outside a row an item is simply its own cell: natural height, and its
    // `foot` (a figure caption) still rendered under it.
    show figure.where(kind: _box-figure-kind): it => _render-cell(_with-body(_figure-spec(it), it.body))
    body
}

// THE ROW
// -----------------------------------------------------------------------------

// One subslide index per item, or `none` for a row that does not step at all
// (`step: none` / `step: false`). See `vboxs` below for what an index means.
#let _resolve-steps(step, count) = {
    if step == none or step == false { return none }
    if step == true { return range(1, count + 1) }
    if type(step) == int {
        assert(step >= 1, message: "vboxs: `step` must be 1 or more, got " + repr(step))
        return range(step, step + count)
    }
    assert(
        type(step) == array,
        message: "vboxs: `step` takes `true`, a starting subslide, or one index per item, got " + repr(step),
    )
    assert(
        step.len() == count,
        message: "vboxs: `step` length must match item count (" + str(step.len()) + " vs " + str(count) + ")",
    )
    for at in step {
        assert(
            type(at) == int and at >= 1,
            message: "vboxs: every `step` index must be 1 or more, got " + repr(at),
        )
    }
    step
}

// The theme's one row layout: every item gets the same height, whatever it is.
//
// `step` reveals the row a subslide at a time, and is the ONLY way to do it —
// `#pause` inside a row is a hard error, not an oversight (see `_resolve-steps`
// and the `touying-fn-wrapper` at the end of this function).
//
//   step: true          one item per subslide, `after` on the one past the last
//   step: 2             the same, but the row starts on subslide 2
//   step: (1, 1, 2)     an index per item — the first two together, then the third
//
// Indices are absolute subslide numbers, the way Touying's own `uncover("2-")`
// counts, and a row spends none of its own: a `#pause` before it has already
// taken subslide 1, so the row starts at `step: 2`, and a `#pause` after it goes
// on counting the pauses alone. They attach to items in the order WRITTEN,
// unlike `widths`, which names tracks in the order drawn. An item that has not
// arrived yet is covered, not dropped, so the row's geometry is identical on
// every subslide.
#let vboxs(
    ..items,
    dir: ltr,
    width: 100%,
    widths: auto,
    gap: auto,
    after: none,
    after-gap: auto,
    fill-height: auto,
    fill-pad: auto,
    bleed: false,
    title-size: none,
    step: none,
) = {
    let specs = items
        .pos()
        .map(item => {
            assert(
                type(item) == content and item.func() == figure and item.kind == _box-figure-kind,
                message: "vboxs: items must be Lemonade row items — a box helper, `img`, or `code`",
            )
            _with-body(_figure-spec(item), item.body)
        })
    let count = specs.len()
    if count == 0 { return [] }

    assert(dir in (ltr, rtl, ttb, btt), message: "vboxs: `dir` must be one of ltr, rtl, ttb, btt")
    let is-vertical = dir == ttb or dir == btt

    // Indices are folded in BEFORE `ordered` reverses an `rtl` / `btt` row, which
    // is what makes them follow the order the items were written.
    let steps = _resolve-steps(step, count)
    if steps != none {
        specs = specs.zip(steps).map(((spec, at)) => spec + (step: at))
    }
    // The row's `after` lands on its own subslide once the row steps at all: one
    // past the last item. There is no separate knob — `step` owns the whole row's
    // timing, so a reader counts subslides in one place.
    let last-step = if steps == none { 1 } else { calc.max(..steps) }
    let after-step = if steps == none or after == none { none } else { last-step + 1 }
    let max-step = if after-step == none { last-step } else { after-step }

    // `rtl` / `btt` reverse the items themselves, so `widths` keeps naming the
    // tracks in the order they are drawn rather than the order written.
    let ordered = if dir == rtl or dir == btt { specs.rev() } else { specs }

    let tracks = if widths == auto {
        (1fr,) * count
    } else {
        assert(type(widths) == array, message: "vboxs: widths must be an array")
        assert(
            not is-vertical,
            message: "vboxs: `widths` names side-by-side tracks; a `ttb` / `btt` stack has one column",
        )
        assert(widths.len() == count, message: "vboxs: widths length must match item count")
        widths
    }

    let feet = ordered.map(_item-foot)
    // Measure and render the same block so paragraph spacing cannot change its flow height.
    let after-block = if after != none { block(width: 100%, spacing: 0pt)[#after] }

    // A stepped row is rendered once per subslide, so everything below is a
    // function of Touying's `self`. A row that does not step is called once with
    // `self: none` and never touches it.
    let render(self: none) = context {
        // Not yet revealed: covered, never dropped. Cover is the deck's own method
        // (`hide` unless a deck configured otherwise), so the cell keeps its exact
        // size and no track, foot band, or caption baseline moves between
        // subslides — the whole point of revealing inside an equal-height row.
        let veil(at, cont) = if at == none or self == none or self.subslide >= at {
            cont
        } else {
            (self.methods.cover)(self: self, cont)
        }

        // An argument left `auto` defers to the deck's `vboxs-config`; that
        // dict's own `after-gap: auto` in turn means the uniform flow gap.
        let cfg = cur-vboxs-config.get()
        let gap = if gap == auto { cfg.gap } else { gap }
        let fill-height = if fill-height == auto { cfg.fill-height } else { fill-height }
        let fill-pad = if fill-pad == auto { cfg.fill-pad } else { fill-pad }
        let after-gap = {
            let resolved = if after-gap == auto { cfg.after-gap } else { after-gap }
            if resolved == auto { cur-spacing().flow } else { resolved }
        }

        // The band every foot in this row shares: the tallest one, measured at
        // the width its own cell will have. A side-by-side row measures its feet
        // as one grid, so each wraps at its column width and the grid's own row
        // height is already the maximum; a stack's feet all have the row width,
        // so those are measured apart and maxed here.
        let foot-band = available-width => if feet.all(f => f == none) {
            0pt
        } else if is-vertical {
            feet
                .map(f => if f == none { 0pt } else { measure(f, width: available-width).height })
                .fold(0pt, calc.max)
        } else {
            measure(
                grid(
                    columns: tracks,
                    column-gutter: gap,
                    inset: 0pt,
                    ..feet.map(f => if f == none { [] } else { f }),
                ),
                width: available-width,
            ).height
        }

        let row = (item-height, band) => block(width: 100%, spacing: 0pt)[
            #grid(
                columns: if is-vertical { (1fr,) } else { tracks },
                rows: if is-vertical { (item-height,) * count } else { (item-height,) },
                column-gutter: if is-vertical { 0pt } else { gap },
                row-gutter: if is-vertical { gap } else { 0pt },
                inset: 0pt,
                align: left + top,
                ..ordered.map(spec => veil(
                    spec.at("step", default: none),
                    _render-cell(
                        spec,
                        height: item-height,
                        foot-height: band,
                        outer-spacing: false,
                        row-title-size: title-size,
                    ),
                )),
            )
        ]

        // The item height and the foot band both depend on the width the row
        // really gets, so both are settled inside one `layout` over the box.
        // `bleed` widens that box through the slide's side margins; the box is
        // still `width` of whatever it sits in, so `width: 100%` is what makes a
        // bled row actually reach both page edges.
        let laid-out = height-for => {
            let placed = box(width: width)[
                #layout(size => {
                    let band = foot-band(size.width)
                    row(height-for(band, size.width), band)
                })
            ]
            if bleed { bleed-block(align(center)[#placed]) } else { align(center)[#placed] }
        }
        // The gap is never covered: reserving it keeps the row above at the same
        // height whether or not the trailer has arrived yet.
        let trailer = if after != none { v(after-gap) + veil(after-step, after-block) }

        if fill-height {
            // A stack splits the height it is given between its items; a
            // side-by-side row gives every item all of it.
            let share = total => if is-vertical {
                calc.max(0pt, total - measure(v(gap)).height * (count - 1)) / count
            } else { total }

            block(width: 100%, height: 1fr)[
                #layout(size => {
                    let trailer-height = if after == none { 0pt } else {
                        measure(after-block, width: size.width).height + measure(v(after-gap)).height
                    }
                    let available = calc.max(0pt, size.height - measure(v(fill-pad)).height)
                    let row-height = calc.max(0pt, available - trailer-height)
                    block(width: 100%, height: available)[
                        #laid-out((band, w) => share(row-height))
                        #trailer
                    ]
                })
            ]
        } else {
            // Equal heights with no height to fill: the tallest item at its
            // natural size sets the others. A stack measures its cells one by
            // one, since a single-column grid would report their sum instead of
            // the largest.
            let natural = (band, w) => if is-vertical {
                ordered
                    .map(spec => measure(
                        _render-cell(spec, foot-height: band, outer-spacing: false, row-title-size: title-size),
                        width: w,
                    ).height)
                    .fold(0pt, calc.max)
            } else {
                measure(row(auto, band), width: w).height
            }

            block(width: 100%)[
                #laid-out(natural)
                #trailer
            ]
        }
    }

    // Touying resolves `#pause` by walking the content tree BEFORE layout, and it
    // cannot see into a `context` — which is every part of this row, since equal
    // heights need `measure` and `layout`. `touying-fn-wrapper` is the way in: it
    // is a mark Touying resolves by CALLING `render` with the current `self`, so
    // the mark sits outside the `context` and `self` arrives inside it.
    // `last-subslide` is what tells the slide how many subslides to repeat for.
    if max-step > 1 {
        touying-fn-wrapper(render, last-subslide: max-step)
    } else {
        render()
    }
}

#let tbox(
    body,
    size: none,
    weight: "bold",
    alignment: left,
    leading: 1em,
) = context {
    let font-sizes = cur-font-sizes.get()
    set par(leading: leading)
    align(alignment)[
        #text(size: if size == none { font-sizes.body-title } else { size }, weight: weight)[#body]
    ]
}
