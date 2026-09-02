#import "base.typ": bleed as bleed-block, theme, touying-fn-wrapper
#import "emph.typ": apply-emph-style, on-primary

// USER CONFIG
// - Geometry and title typography: edit `box-config` below.
// - Equal-row layout defaults: edit `vboxs-config` below.
// - Accent palettes: edit `light-box-styles` / `dark-box-styles` in base.typ.
// - Body and title font sizes: edit `body` / `body-title` in base.typ.
// - Soft body fills are enabled with `lemonade-theme(box-fill: true)`.
//
// Per-box `compact`, `body-align`, `body-inset`, `title-size`, and
// `title-inset` override these defaults. A dictionary `body-inset` is merged
// over the selected normal or compact inset, so
// `body-inset: (right: 0pt)` changes only that side.
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
    body-align: left + top,
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
    let styles = theme().box-styles
    let style = if spec.style == none {
        none
    } else {
        assert(spec.style in styles.keys(), message: "box: unknown style `" + spec.style + "`")
        styles.at(spec.style)
    }
    let accent = if style == none { colors.primary } else { style.border }
    let fill = if style != none and theme().box-fill { style.fill } else { none }
    let frame-paint = if fill == none { colors.table-stroke } else { accent.transparentize(box-config.frame-tint) }
    (
        accent: accent,
        fill: fill,
        title-ink: if style == none or style.title-text-fill == auto { box-config.title-text-fill } else { style.title-text-fill },
        title-emph: if style == none or style.title-emph-fill == auto { none } else { style.title-emph-fill },
        frame: _frame-stroke(frame-paint),
        frame-no-left: _frame-stroke(frame-paint, left: false),
    )
}

#let _title-content(spec, visuals, font-sizes, row-title-size: none) = {
    let default-size = if row-title-size == none { font-sizes.body-title } else { row-title-size }
    // A style may pin emphasis to its title ink when the usual on-primary
    // accent would lose contrast. Otherwise white ink gets the shared
    // on-primary emphasis, while a style-supplied dark ink keeps that ink.
    let title = if visuals.title-emph != none {
        apply-emph-style(spec.title, emph-fill: visuals.title-emph, strong-fill: visuals.title-emph)
    } else if visuals.title-ink == box-config.title-text-fill {
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

// The body at its box's alignment. A horizontal component re-aligns every
// paragraph line inside, since alignment is inherited; `left + horizon` is
// the usual way to centre a short body in an equal-height row.
#let _body-content(spec, font-sizes) = align(spec.at("body-align", default: box-config.body-align))[
    #block(width: 100%)[
        #set text(size: font-sizes.body)
        #spec.body
    ]
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
//
// The row's `title-size` rides along IN THE SPEC rather than as an argument, so
// no renderer has to declare a parameter it does not care about — an extra dict
// key is invisible to one that reads only the keys it knows. `vstack` is what
// reads it back: it hands the size to the row nested in its cell, so a row-level
// `title-size` reaches boxes at any depth instead of stopping at the stack.
#let _render-spec(spec, height: auto, outer-spacing: true, row-title-size: none) = if "render" in spec {
    (spec.render)(spec + (row-title-size: row-title-size), height: height, outer-spacing: outer-spacing)
} else {
    context {
        let resolved = theme()
        let visuals = _box-visuals(spec, resolved.colors)
        let compact = spec.at("compact", default: resolved.box-compact)
        let inner = if spec.kind == "plain" { _plain-grid } else { _top-grid }
        // A box on its own takes the uniform flow rhythm; inside a row the row
        // owns the spacing, so the item adds none of its own.
        let outer = if outer-spacing { auto } else { 0pt }
        block(width: 100%, height: height, above: outer, below: outer, spacing: 0pt)[
            #inner(
                spec,
                visuals,
                if compact { box-config.compact } else { box-config.normal },
                resolved.font-sizes,
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

// Everything in a row is a `box-item`; a bare `[...]`, a `table`, or a raw
// `vboxs` is rejected here rather than measured into a baffling layout. `name`
// is the caller, so a `vstack` reports itself at its own call site instead of
// failing later as the `vboxs` it forwards to.
#let _assert-row-items(name, items) = {
    for item in items {
        assert(
            type(item) == content and item.func() == figure and item.kind == _box-figure-kind,
            message: name + ": items must be Lemonade row items — a box helper, `img`, `code`, `vtable`, or `vstack`",
        )
    }
}

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
    let options = ("compact", "body-align", "body-inset", "title-size", "title-inset")
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
    if "body-align" in spec {
        assert(
            type(spec.body-align) == alignment,
            message: name + ": `body-align` takes an alignment such as `left + horizon`, got " + repr(spec.body-align),
        )
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

// The theme's one row layout. Side by side, every item gets the SAME height,
// whatever it is — that is what makes columns line up. Stacked (`ttb` / `btt`)
// they get their OWN heights instead, in proportion to what each one measures:
// filling, those proportions are scaled up to the height the row was given; not
// filling, each item is simply its natural height. `heights:` replaces the
// measured proportions with named ones, and `heights: (1fr,) * n` is how a stack
// asks for the even split that measuring would not have produced.
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
    heights: auto,
    gap: auto,
    after: none,
    after-gap: auto,
    fill-height: auto,
    fill-pad: auto,
    bleed: false,
    title-size: none,
    step: none,
) = {
    let unknown = items.named().keys()
    if unknown.len() > 0 {
        panic("vboxs: unknown option `" + unknown.first() + "`")
    }
    let given = items.pos()
    _assert-row-items("vboxs", given)
    let specs = given.map(item => _with-body(_figure-spec(item), item.body))
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

    // `heights` is the vertical counterpart of `widths`, and mirrors it: named
    // in the order tracks are DRAWN, rejected on the axis that has only one
    // track. Left `auto`, a stack takes its proportions from what its items
    // measure. The values are weights rather than grid tracks — they are
    // normalized against each other and resolved to lengths before layout,
    // because an item that scales itself to fit needs a real height, not a `1fr`
    // that the grid alone would know how to divide.
    let tall-tracks = if heights == auto {
        auto
    } else {
        assert(type(heights) == array, message: "vboxs: heights must be an array")
        assert(
            is-vertical,
            message: "vboxs: `heights` names stacked tracks; a side-by-side row has one row — "
                + "sizing its items apart is `widths`",
        )
        assert(heights.len() == count, message: "vboxs: heights length must match item count")
        for h in heights {
            assert(
                type(h) == fraction and h > 0fr,
                message: "vboxs: every `heights` entry must be a positive fraction such as `2fr`, got " + repr(h),
            )
        }
        heights
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
        let cfg = theme().at("vboxs", default: vboxs-config)
        let gap = if gap == auto { cfg.gap } else { gap }
        let fill-height = if fill-height == auto { cfg.fill-height } else { fill-height }
        let fill-pad = if fill-pad == auto { cfg.fill-pad } else { fill-pad }
        let after-gap = {
            let resolved = if after-gap == auto { cfg.after-gap } else { after-gap }
            if resolved == auto { theme().spacing.flow } else { resolved }
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

        // `item-heights` is one height PER ITEM. A side-by-side row passes the
        // same value throughout — equal height is the point there, since the
        // columns have to line up — while a stack passes each item its own, so
        // a short figure above a tall one no longer has to pretend to match it.
        // The value is handed to the grid track AND to the renderer, which is
        // why it must be a resolved length: a `1fr` track is not known until
        // layout, and an item that scales itself to fit needs a number now.
        let row = (item-heights, band) => block(width: 100%, spacing: 0pt)[
            #grid(
                columns: if is-vertical { (1fr,) } else { tracks },
                rows: if is-vertical { item-heights } else { (item-heights.first(),) },
                column-gutter: if is-vertical { 0pt } else { gap },
                row-gutter: if is-vertical { gap } else { 0pt },
                inset: 0pt,
                align: left + top,
                ..ordered
                    .zip(item-heights)
                    .map(((spec, item-height)) => veil(
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

        // Every cell at its own natural height, measured at the width the row
        // really got. A stack's proportions come from these, so they are
        // measured once and used whole rather than folded to a maximum.
        //
        // A cell's natural height is its BODY plus the band the row reserves —
        // not the item's own foot. Measuring the whole cell would count that
        // foot instead, and the render pass subtracts the full band from
        // whatever height it is handed: a one-line caption in a row whose band
        // is two lines would come back one line short, and the body would be
        // squeezed by the difference (a caption drawn over the last code line).
        // A footless item is handed the height whole, so it takes no band.
        let naturals = (band, w) => ordered.map(spec => {
            let body = measure(
                _render-spec(spec, outer-spacing: false, row-title-size: title-size),
                width: w,
            ).height
            if _item-foot(spec) == none { body } else { body + band }
        })

        // The weight each item carries when a stack divides its height:
        // `heights` if the deck named them, else what the content measures.
        // Normalized here so both paths are plain floats summing to 1.
        let weights = (band, w) => if tall-tracks == auto {
            let hs = naturals(band, w)
            let sum = hs.fold(0pt, (a, b) => a + b)
            // Nothing to go on — an empty or zero-height stack divides evenly.
            if sum == 0pt { (1.0 / count,) * count } else { hs.map(h => h / sum) }
        } else {
            let sum = tall-tracks.fold(0fr, (a, b) => a + b)
            tall-tracks.map(h => h / sum)
        }

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
            // A stack splits the height it is given between its items, in
            // proportion to what each one measures — so two figures scale by the
            // SAME factor and keep their relative sizes while together filling
            // the column. An even split would blow the short one up to match the
            // tall one; `heights:` is how a deck overrides the proportions.
            // A side-by-side row gives every item all of the height instead.
            let share = (total, band, w) => if is-vertical {
                let inner = calc.max(0pt, total - measure(v(gap)).height * (count - 1))
                weights(band, w).map(f => inner * f)
            } else { (total,) * count }

            block(width: 100%, height: 1fr)[
                #layout(size => {
                    let trailer-height = if after == none { 0pt } else {
                        measure(after-block, width: size.width).height + measure(v(after-gap)).height
                    }
                    let available = calc.max(0pt, size.height - measure(v(fill-pad)).height)
                    let row-height = calc.max(0pt, available - trailer-height)
                    block(width: 100%, height: available)[
                        #laid-out((band, w) => share(row-height, band, w))
                        #trailer
                    ]
                })
            ]
        } else {
            // Nothing to fill: a stack simply gives every item the height it
            // measures, which is the closest this row comes to plain stacking.
            // Named `heights:` still take over, sized against the total those
            // naturals add up to. A side-by-side row still equalizes — it takes
            // the whole grid's natural height, which is already the tallest
            // item's, and hands it to every column.
            let natural = (band, w) => if is-vertical {
                let hs = naturals(band, w)
                if tall-tracks == auto {
                    hs
                } else {
                    let total = hs.fold(0pt, (a, b) => a + b)
                    weights(band, w).map(f => total * f)
                }
            } else {
                // Measure each BODY at its actual track width, then reserve the
                // shared band under every captioned body. Measuring `_render-cell`
                // here would count each caption's own height, then the render pass
                // would subtract the tallest band from all of them — shrinking a
                // valid body whenever another caption wrapped taller.
                let cells = ordered.map(spec => block(width: 100%, spacing: 0pt)[
                    #_render-spec(spec, outer-spacing: false, row-title-size: title-size)
                    #if _item-foot(spec) != none { block(height: band) }
                ])
                let row-height = measure(
                    grid(columns: tracks, column-gutter: gap, inset: 0pt, ..cells),
                    width: w,
                ).height
                (row-height,) * count
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

// A STACK IN ONE CELL
// -----------------------------------------------------------------------------

// A row item that draws NOTHING of its own — no frame, no title, no fill, no
// caption. It exists so one cell of a row can hold a second row, which is
// otherwise impossible: every `vboxs` item must be a `box-item`, so neither
// plain content nor a nested `vboxs` can go in a cell directly.
//
// Everything below is a forward to that nested row, so all four directions,
// `widths`, foot bands, and equal heights are `vboxs`'s doing, not a second
// implementation of them. Defined after `vboxs` because it closes over it.
#let _render-vstack(spec, height: auto, outer-spacing: true) = {
    let outer = if outer-spacing { auto } else { 0pt }
    block(width: 100%, height: height, above: outer, below: outer, spacing: 0pt)[
        #vboxs(
            ..spec.items,
            dir: spec.dir,
            width: spec.width,
            widths: spec.widths,
            heights: spec.heights,
            gap: spec.gap,
            after: spec.after,
            after-gap: spec.after-gap,
            // ON, a stack splits the cell the row gave it BETWEEN its items,
            // in proportion to what each one measures — which is what lets a
            // figure that scales to its slot (`img`, and any foreign renderer
            // that fits itself to the height handed down) actually use the
            // column. OFF, every item is exactly its own natural height and
            // whatever the cell has left over stays empty. OFF is the default:
            // most stacks hold boxes, prose, or listings, which have nothing to
            // scale into extra height and only stretch their frames when they
            // are given it. A stack of FIGURES is what asks for
            // `fill-height: true` — without it a scale-to-fit item renders at
            // roughly 1× in a column with room to spare. `height == auto` — a
            // bare `#vstack` outside any row — has nothing to fill either way.
            fill-height: spec.fill-height and height != auto,
            // `fill-pad` keeps a filling row clear of the footer, and the outer
            // row already reserved it. Padding again would only shrink the cell
            // this stack was handed.
            fill-pad: 0pt,
            title-size: spec.at("row-title-size", default: none),
        )
    ]
}

// `#vstack(img(a), img(b))` — a column of items inside one cell of a row:
//
//   #vboxs(
//       code(caption: [Source], indent: 2)[...],
//       vstack(img(a, [Target A]), img(b, [Target B]), fill-height: true),
//   )
//
// `dir` is the nested row's, not the outer one's, so a `ttb` outer row can hold
// a cell of items side by side. A `vstack` is itself a row item, so stacks nest.
//
// `fill-height: true` for a stack of figures, which need a real height to scale
// into; the default is off, since filling a stack of boxes, prose, or listings
// only stretches their frames.
#let vstack(
    ..items,
    dir: ttb,
    width: 100%,
    widths: auto,
    heights: auto,
    gap: auto,
    after: none,
    after-gap: auto,
    fill-height: false,
) = {
    // The sink takes positionals only; every option is a named parameter above.
    // Without this check a stray named argument would land in the sink and be
    // silently dropped — the same trap `img` guards against.
    let unknown = items.named().keys()
    if unknown.len() > 0 {
        let key = unknown.first()
        let hint = if key in ("step", "bleed") {
            // A nested row is rendered inside a `context`, and a Touying mark
            // emitted there is never resolved — so revealing belongs to the
            // outer row, which covers this whole cell as one item. Bleed reaches
            // through the slide's side margins, which a cell cannot do either.
            " — `" + key + "` belongs on the outer row: `vboxs(vstack(..), .., " + key + ": ..)`"
        } else if key == "fill-pad" {
            " — how big the cell is stays the outer row's call; `fill-height` only says whether to fill it"
        } else { "" }
        panic("vstack: unknown option `" + key + "`" + hint)
    }
    let stacked = items.pos()
    assert(stacked.len() > 0, message: "vstack: expected at least one row item")
    _assert-row-items("vstack", stacked)
    box-item(
        (
            kind: "vstack",
            render: _render-vstack,
            items: stacked,
            dir: dir,
            width: width,
            widths: widths,
            heights: heights,
            gap: gap,
            after: after,
            after-gap: after-gap,
            fill-height: fill-height,
        ),
        [],
    )
}
