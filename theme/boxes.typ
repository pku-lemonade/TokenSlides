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

// One item at a given height. A spec with `render:` belongs to another module
// (img, code, vtable, vstack) and is drawn by that function; anything else is a
// box. The row's `title-size` rides along in the spec so nested rows see it.
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

// Row-item constructor: wraps a spec and body so `vboxs` can lay the item out.
// A spec with `render:` is drawn by that function as
// `render(spec, height: ..., outer-spacing: ...)`, reading its body from
// `spec.body`. A spec may carry `foot:` (a caption): the row measures every
// foot together and reserves one band for the tallest, so items end on the
// same line and captions align.
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

// Everything in a row is a `box-item`; plain content or a raw `vboxs` is
// rejected here rather than measured into a baffling layout.
#let _assert-row-items(name, items) = {
    for item in items {
        assert(
            type(item) == content and item.func() == figure and item.kind == _box-figure-kind,
            message: name + ": items must be Lemonade row items — a box helper, `img`, `code`, `vtable`, or `vstack`",
        )
    }
}

// One cell: the item above its `foot`. `foot-height` is the row's shared band,
// so the item is drawn that much shorter; without a foot it takes the whole cell.
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
    // Revealing is the row's job (`vboxs(.., step: ..)`); a lone box reveals with `#pause`.
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
    // Typst silently drops an unbreakable figure that does not fit its region.
    // Breakable, an over-tall box spills onto the next page instead, which is
    // wrong where it shows. A block passing `breakable:` itself still wins.
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

// The theme's one row layout. Side by side, every item gets the same height so
// columns line up. Stacked (`ttb` / `btt`), items get their own heights in
// proportion to what they measure, scaled to fill the row when filling;
// `heights:` names those proportions (`(1fr,) * n` for an even split).
//
// `step` reveals the row one subslide at a time and is the only way to do so
// (`#pause` inside a row is an error):
//
//   step: true          one item per subslide, `after` on the one past the last
//   step: 2             the same, but the row starts on subslide 2
//   step: (1, 1, 2)     an index per item — the first two together, then the third
//
// Indices are absolute subslide numbers, as in Touying's `uncover("2-")`, and
// attach to items in the order written. An item not yet revealed is covered,
// not dropped, so the row's geometry is identical on every subslide.
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

    // Steps attach before `rtl` / `btt` reverse the items, so they follow the order written.
    let steps = _resolve-steps(step, count)
    if steps != none {
        specs = specs.zip(steps).map(((spec, at)) => spec + (step: at))
    }
    // `after` gets its own subslide, one past the last item.
    let last-step = if steps == none { 1 } else { calc.max(..steps) }
    let after-step = if steps == none or after == none { none } else { last-step + 1 }
    let max-step = if after-step == none { last-step } else { after-step }

    // `rtl` / `btt` reverse the items, so `widths` names tracks in the order drawn.
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

    // `heights` mirrors `widths` on the stacked axis: weights, normalized and
    // resolved to lengths before layout, since a scale-to-fit item needs a real height.
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

    // Rendered once per subslide with Touying's `self`; a non-stepping row is called once with `self: none`.
    let render(self: none) = context {
        // Not yet revealed: covered by the deck's cover method, never dropped, so the cell keeps its size.
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

        // The band every foot in this row shares: the tallest, measured at its cell width.
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

        // One height per item: the same for every column of a side-by-side row, each
        // its own in a stack. Resolved lengths, since a `1fr` track is unknown until layout.
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

        // Each cell's natural height: the body plus the row's shared band for captioned
        // items (not the item's own foot, which the render pass subtracts as the band).
        let naturals = (band, w) => ordered.map(spec => {
            let body = measure(
                _render-spec(spec, outer-spacing: false, row-title-size: title-size),
                width: w,
            ).height
            if _item-foot(spec) == none { body } else { body + band }
        })

        // The weight each item carries when a stack divides its height: `heights` if
        // given, else what the content measures. Normalized to floats summing to 1.
        let weights = (band, w) => if tall-tracks == auto {
            let hs = naturals(band, w)
            let sum = hs.fold(0pt, (a, b) => a + b)
            // Nothing to go on — an empty or zero-height stack divides evenly.
            if sum == 0pt { (1.0 / count,) * count } else { hs.map(h => h / sum) }
        } else {
            let sum = tall-tracks.fold(0fr, (a, b) => a + b)
            tall-tracks.map(h => h / sum)
        }

        // Item heights and the foot band both depend on the width the row really gets,
        // so both are settled inside one `layout`. `bleed` widens the box through the side margins.
        let laid-out = height-for => {
            let placed = box(width: width)[
                #layout(size => {
                    let band = foot-band(size.width)
                    row(height-for(band, size.width), band)
                })
            ]
            if bleed { bleed-block(align(center)[#placed]) } else { align(center)[#placed] }
        }
        // The gap is never covered, so the row above keeps its height before the trailer arrives.
        let trailer = if after != none { v(after-gap) + veil(after-step, after-block) }

        if fill-height {
            // A stack splits its height between items in proportion to what they measure,
            // so two figures scale by the same factor; a side-by-side row gives every item all of it.
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
            // Not filling: a stack gives every item its measured height (`heights:` still
            // reweights them); a side-by-side row takes the tallest and hands it to every column.
            let natural = (band, w) => if is-vertical {
                let hs = naturals(band, w)
                if tall-tracks == auto {
                    hs
                } else {
                    let total = hs.fold(0pt, (a, b) => a + b)
                    weights(band, w).map(f => total * f)
                }
            } else {
                // Measure each body at its track width, then reserve the shared band under
                // captioned bodies, rather than measuring whole cells and over-subtracting.
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

    // Touying resolves `#pause` before layout and cannot see into a `context`.
    // `touying-fn-wrapper` is a mark it resolves by calling `render` with `self`.
    if max-step > 1 {
        touying-fn-wrapper(render, last-subslide: max-step)
    } else {
        render()
    }
}

// A STACK IN ONE CELL
// -----------------------------------------------------------------------------

// A row item that draws nothing of its own, so one cell of a row can hold a
// second row. Everything is forwarded to the nested `vboxs`.
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
            // A stack of figures needs `fill-height: true` to scale into its cell;
            // boxes and listings would only stretch their frames. A bare `#vstack`
            // outside a row has nothing to fill.
            fill-height: spec.fill-height and height != auto,
            // The outer row already reserved `fill-pad`.
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
// `dir` is the nested row's own, so a `ttb` outer row can hold a side-by-side
// cell. Stacks nest. Use `fill-height: true` for a stack of figures.
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
    // The sink takes positionals only; a stray named argument must not vanish.
    let unknown = items.named().keys()
    if unknown.len() > 0 {
        let key = unknown.first()
        let hint = if key in ("step", "bleed") {
            // Revealing and bleeding are the outer row's job; a cell can do neither.
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
