#import "base.typ": theme
#import "boxes.typ": box-item
#import "images.typ": caption-foot
#import "code-langs.typ": check-lang, code-buckets, code-lang, python-lang, regex-escape

// USER CONFIG
// - Frame geometry, typography and the listing font: `code-config` below.
// - Surface and syntax colors: `light-code-palette` / `dark-code-palette`.
// - Languages highlighted here rather than by syntect: `code-config.langs`,
//   built with `code-lang(...)` (code-langs.typ). A deck adds its own with
//   `lemonade-theme(code-langs: (mydsl: ...))`.
// - Base code font size per aspect ratio: `font-sizes.code` in base.typ;
//   `size` / `scale` here rescale a single listing.
// `font-config.mono` (base.typ) dresses footers, tables and inline `raw`;
// listings take `code-config.font`, so the two can differ.
//
// A listing is an ordinary raw fence; prose may sit beside it:
//
//     #code[
//       ```python
//       def axpy(x, y, alpha):
//           return fma(alpha, x, y)
//       ```
//       Both operands must share one logical time.
//     ]
//
// Emphasis (line numbers are 1-based; `range(2, 5)` works):
//   `hl: (2, 3)`      neutral band behind those lines
//   `focus: (2, 3)`   the band, plus every other line muted (overrides `dim:`)
//   `dim: (1,)`       mute these lines only
//   `mark: ("@ t",)`  accent the token wherever it appears
// A mark only matches inside one highlighter token; `lang: none` drops
// highlighting so a mark can span anything. A syntect listing turns its
// highlighting off as soon as a mark is set.
//
// The gutter is on by default (`numbers: false` per listing,
// `code-config.numbers` per deck). Long lines wrap with the continuation
// hanging under the code, not the gutter; a single over-wide token overflows
// visibly. `indent: 2` re-indents to buy width before reaching for `scale:`.
//
// `caption:` labels a listing below its frame in the shared row-item caption
// style (`img-config`). A bare `#code` is a `vboxs` row item whose frame
// fills the row height (`stretch: false` keeps it natural). Inside a box
// helper use `frame: false`.

// PALETTES
// How a listing reads, per mode. `bg` / `border` are the frame; `fg` is the ink
// for prose in the code body, for every token the palette does not repaint, and
// (transparentized) for `dim:`.
//
// A `syntax` row styles one bucket. `fill` defaults to the palette's `fg`, so a
// bare bucket is simply not colored; `weight` is set only where a row asks, so
// the bold from `hl:` survives elsewhere. Every bucket needs a row.
#let light-code-palette = (
    bg: rgb("#F5F5F5"),
    border: rgb("#D4D4D4"),
    fg: rgb("#1F2328"),
    syntax: (
        comment: (fill: rgb("#667085")),
        keyword: (fill: rgb("#A3194A"), weight: "bold"),
        decorator: (fill: rgb("#0759A6"), weight: "bold"),
        name: (fill: rgb("#006B76")),
        string: (fill: rgb("#2E7D32")),
        number: (fill: rgb("#A34B00")),
        other: (fill: rgb("#6D28D9")),
        plain: (:),
    ),
)

#let dark-code-palette = (
    bg: rgb("#0B1220"),
    border: rgb("#334155"),
    fg: rgb("#EDEDED"),
    syntax: (
        comment: (fill: rgb("#8B949E")),
        keyword: (fill: rgb("#E86A98"), weight: "bold"),
        decorator: (fill: rgb("#62A5EA"), weight: "bold"),
        name: (fill: rgb("#4FB8C2")),
        string: (fill: rgb("#69B972")),
        number: (fill: rgb("#DB8948")),
        other: (fill: rgb("#A987E8")),
        plain: (:),
    ),
)

#let code-config = (
    // Languages highlighted by this module, keyed by fence tag. Other tags go to syntect.
    langs: (python: python-lang),
    // Listing font, separate from `font-config.mono`.
    font: ("Inconsolata", "Source Han Sans SC"),
    // A ratio resolves against the listing's font size so the frame keeps its
    // proportions under `scale`; a length is used as given.
    inset: 40%,
    border-width: 1pt,
    radius: 0pt,
    // On, an over-tall listing splits across pages and stays visible; off, it is
    // pushed whole to the next region and silently dropped there.
    breakable: true,
    // `auto` = the aspect ratio's `code` font size; `scale` multiplies it,
    // which is how side-by-side listings are shrunk to fit one slide.
    size: auto,
    scale: 100%,
    // Whether a bare listing's visible surface stretches to the equal height its
    // `vboxs` row assigns. `false` keeps the row geometry (and caption baseline)
    // but draws the frame only at its natural height.
    stretch: true,
    leading: 0.5em,
    // Gap between the listing and any prose sharing the same `#code[...]`.
    gap: 0.9em,
    // Extra indent for a wrapped line's continuation rows, past its own code column.
    wrap-indent: 0pt,
    // Indent width in spaces. `auto` leaves the source alone; an integer re-indents
    // space-indented lines to that many per level and sets `tab-size` for tabs.
    indent: auto,
    // Palette per mode. A listing may pass its own with
    // `theme: (bg: .., border: .., fg: .., syntax: (..))` or switch highlighting
    // off with `theme: none`.
    palettes: (light: light-code-palette, dark: dark-code-palette),
    // `hl:` — a quiet neutral band behind emphasized lines, bled to the frame edge.
    hl-tint: 92%,
    hl-weight: "bold",
    // Band growth past the line box, so consecutive highlighted lines meet.
    hl-outset: 0.25em,
    // `dim:` / the muted half of `focus:`.
    dim-tint: 55%,
    // Line-number gutter. `number-digits` is the zero-padded width; a longer
    // listing widens on its own. The ink is `fg` pushed back by `number-tint`.
    numbers: true,
    number-digits: 2,
    number-gap: 0.8em,
    number-tint: 60%,
    // `mark:` token emphasis, over the accent; it outranks the highlighter's ink.
    mark-weight: "bold",
)

// SYNTECT REPAINT
//
// Typst highlights raw blocks with syntect, whose colors come from a TextMate
// theme. Instead of shipping a `.tmTheme`, we let Typst's built-in theme
// classify tokens and repaint each span by the color it was given (readable as
// `context text.fill`). `_classifier` is that observed color table. A Typst
// upgrade that changes the built-in theme makes every key miss and listings
// fall back to the built-in colors; re-derive it by rendering a snippet under
//
//     show raw: it => { show text: t => context metadata((txt: t.text, fill: text.fill.to-hex())); it }
//
// and querying the metadata.
#let _classifier = (
    comment: "#74747c", // `# note`
    keyword: "#d73948", // def class if return None True and the operators
    name: "#4b69c6", // function, type and class names
    decorator: "#301414", // `@deco`
    string: "#198810", // `"text"`
    number: "#b60157", // `1`, `1.5`
    other: "#8b41b1", // inherited class, f-string interpolation
    plain: "#000000", // everything else
)

// The observed table and the shared vocabulary must agree, or a bucket would
// have a palette row but never be produced (or the reverse).
#assert(
    _classifier.keys().sorted() == code-buckets.sorted(),
    message: "code: `_classifier` buckets must match `code-buckets` in code-langs.typ",
)

// Accept a bare line number or an array of them (`range(3, 7)` included).
#let _line-set(spec, name) = {
    if spec == none {
        ()
    } else if type(spec) == int {
        (spec,)
    } else if type(spec) == array {
        for n in spec {
            assert(type(n) == int, message: "code: `" + name + "` takes line numbers, got " + repr(n))
        }
        spec
    } else {
        panic("code: `" + name + "` must be an int or an array of ints, got " + repr(spec))
    }
}

#let _mark-list(mark) = {
    if mark == none {
        ()
    } else if type(mark) in (str, regex) {
        (mark,)
    } else if type(mark) == array {
        mark
    } else {
        panic("code: `mark` must be a string, a regex, or an array of them, got " + repr(mark))
    }
}

#let _leading-spaces(line) = {
    let n = 0
    for c in line.clusters() {
        if c == " " { n += 1 } else { break }
    }
    n
}

// Rescale leading spaces from the source's own indent unit (its smallest
// non-zero indent) to `width`, keeping continuation lines aligned.
#let _reindent-text(source, width) = {
    let lines = source.split("\n")
    let indents = lines.map(_leading-spaces).filter(n => n > 0)
    if indents.len() == 0 { return source }
    let unit = calc.min(..indents)
    if unit <= width { return source }
    lines
        .map(line => {
            let n = _leading-spaces(line)
            if n == 0 { line } else { " " * int(calc.round(n * width / unit)) + line.slice(n) }
        })
        .join("\n")
}

#let _reindent(node, width) = {
    if type(node) != content {
        node
    } else if node.func() == raw {
        let fields = node.fields()
        let _ = fields.remove("text")
        raw(_reindent-text(node.text, width), ..fields)
    } else if node.has("children") {
        node.children.map(child => _reindent(child, width)).join()
    } else {
        node
    }
}

#let _holds-raw(node) = {
    if type(node) != content {
        false
    } else if node.func() == raw {
        true
    } else if node.has("children") {
        node.children.any(_holds-raw)
    } else {
        false
    }
}

// The tag of the first block fence in the body: the listing's own language.
#let _first-lang(node) = {
    if type(node) != content {
        none
    } else if node.func() == raw {
        if node.at("block", default: false) { node.at("lang", default: none) } else { none }
    } else if node.has("children") {
        let found = none
        for child in node.children {
            if found == none { found = _first-lang(child) }
        }
        found
    } else {
        none
    }
}

// `auto` takes the fence's own tag and highlights the listing here if that tag
// is registered, otherwise leaves it to syntect. `none` always leaves it to
// syntect; a name or a `code-lang(...)` spec always takes it.
#let _resolve-lang(lang, fence, langs) = {
    if lang == none {
        none
    } else if type(lang) == dictionary {
        check-lang(lang)
    } else if type(lang) == str {
        assert(
            lang in langs,
            message: "code: no language spec named `" + lang + "`; registered: " + repr(langs.keys()),
        )
        assert(
            langs.at(lang) != none,
            message: "code: language spec `" + lang + "` is turned off by this deck's `code-langs`",
        )
        check-lang(langs.at(lang))
    } else if lang == auto {
        let found = if fence == none { none } else { langs.at(fence, default: none) }
        if found == none { none } else { check-lang(found) }
    } else {
        panic(
            "code: `lang` must be `auto`, `none`, a registered name, or a `code-lang(...)` spec, got " + repr(lang),
        )
    }
}

// Re-render a line as unhighlighted raw so a flat ink takes (syntax spans set
// their own fill). The rebuilt raw carries a sentinel `lang` the block rule
// skips, and a nested `raw.line` rule ends the recursion. Nothing is boxed, so
// long lines still wrap with their hanging indent.
#let _flat-lang = "lemonade-code-flat"

#let _flat-line(line, ink) = {
    show raw.line: inner => inner.body
    text(fill: ink, raw(line.text, lang: _flat-lang))
}

// Cut a line into `(bucket, text)` runs. Whatever the combined pattern does not
// claim is `plain`, so a spec only has to describe what it wants colored.
#let _tokenize(source, lang) = {
    let runs = ()
    let pos = 0
    for m in source.matches(lang.all) {
        if m.start > pos { runs.push((bucket: "plain", text: source.slice(pos, m.start))) }
        // A combined match does not say which alternative produced it, so the
        // token is re-tested rule by rule and the first hit wins — the same
        // order the alternation resolves in. Cheap: a token is a few clusters.
        let bucket = "plain"
        let cap = none
        for rule in lang.rules {
            let hit = m.text.match(rule.test)
            if hit != none {
                bucket = rule.bucket
                cap = hit.captures.find(c => c != none)
                break
            }
        }
        let at = if cap == none or cap == "" { none } else { m.text.position(cap) }
        if at == none {
            runs.push((bucket: bucket, text: m.text))
        } else {
            // A rule that captured buckets only what it captured. What it
            // matched around the capture goes back through the rules, so the
            // `def` a name rule keyed off still comes out a keyword. Both sides
            // are strictly shorter than the token, so this always bottoms out.
            if at > 0 { runs += _tokenize(m.text.slice(0, at), lang) }
            runs.push((bucket: bucket, text: cap))
            let tail = m.text.slice(at + cap.len())
            if tail != "" { runs += _tokenize(tail, lang) }
        }
        pos = m.end
    }
    if pos < source.len() { runs.push((bucket: "plain", text: source.slice(pos))) }
    runs
}

// Rebuild a line from its source as styled runs. A run with no `weight` row
// inherits the ambient one, which lets the bold from `hl:` through.
#let _spec-line(source, lang, palette) = {
    show raw.line: inner => inner.body
    for run in _tokenize(source, lang) {
        let row = palette.syntax.at(run.bucket)
        let body = raw(run.text, lang: _flat-lang)
        let fill = row.at("fill", default: palette.fg)
        let weight = row.at("weight", default: none)
        if weight == none { text(fill: fill, body) } else { text(fill: fill, weight: weight, body) }
    }
}

// Zero-padding aligns the gutter: the listing font is mono, so equal digit counts line up.
#let _pad-number(n, digits) = {
    let s = str(n)
    if s.len() < digits { "0" * (digits - s.len()) + s } else { s }
}

// Plain `text`, not `raw`, so the gutter stays clear of the raw show rules.
#let _gutter(number, digits, ink) = {
    text(fill: ink, _pad-number(number, digits))
    h(code-config.number-gap)
}

// Every line is its own paragraph so `hanging-indent` can indent its wraps;
// `spacing: 0pt` keeps the line rhythm at `leading`.
#let _line-rule(cfg) = it => {
    // A listing longer than `number-digits` allows widens its gutter.
    let digits = calc.max(code-config.number-digits, str(it.count).len())
    let gutter = if cfg.numbers { _gutter(it.number, digits, cfg.num-ink) }

    // A continuation row starts past the gutter and this line's own indent.
    let hang = (
        (if cfg.numbers { cfg.char-width * digits + code-config.number-gap } else { 0pt })
            + cfg.char-width * _leading-spaces(it.text)
            + code-config.wrap-indent
    )

    let ink = if it.number in cfg.dim-lines {
        _flat-line(it, cfg.dim-ink)
    } else if cfg.lang != none {
        _spec-line(it.text, cfg.lang, cfg.palette)
    } else {
        it.body
    }

    let banded = it.number in cfg.hl-lines
    // The band's weight lands on the code alone; the gutter reads as a ruler.
    let row = par(hanging-indent: hang, {
        gutter
        if banded {
            set text(weight: code-config.hl-weight)
            ink
        } else {
            ink
        }
    })

    if banded {
        // A block, so the band covers every row of a wrapped line.
        block(
            width: 100%,
            spacing: 0pt,
            fill: cfg.palette.fg.transparentize(code-config.hl-tint),
            outset: (x: cfg.pad, y: code-config.hl-outset),
            row,
        )
    } else {
        block(spacing: 0pt, row)
    }
}

// One show rule per regex (a `regex` value cannot be spliced into a larger
// pattern); literals merge into one alternation, longest first.
#let _fold-marks(body, patterns, ink) = {
    if patterns.len() == 0 {
        body
    } else {
        show patterns.last(): m => text(fill: ink, weight: code-config.mark-weight, m.text)
        _fold-marks(body, patterns.slice(0, -1), ink)
    }
}

#let _apply-marks(body, marks, ink) = {
    let literals = marks.filter(m => type(m) == str).sorted(key: m => -m.len())
    let patterns = marks.filter(m => type(m) == regex)
    if literals.len() > 0 {
        patterns.push(regex("(?:" + literals.map(regex-escape).join("|") + ")"))
    }
    _fold-marks(body, patterns, ink)
}

#let _check-palette(palette) = {
    assert(type(palette) == dictionary, message: "code: a code palette must be a dictionary, got " + repr(palette))
    for key in ("bg", "border", "fg", "syntax") {
        assert(key in palette, message: "code: code palette needs a `" + key + "` key, got " + repr(palette.keys()))
    }
    for bucket in code-buckets {
        assert(
            bucket in palette.syntax,
            message: "code: code palette has no `" + bucket + "` syntax row; every bucket in `_classifier` needs one",
        )
    }
    palette
}

// A `theme` dictionary is a palette in its own right, so it brings its own
// surface; every other form of `theme` leaves the surface to the mode.
#let _resolve-palette(theme, mode) = if type(theme) == dictionary {
    _check-palette(theme)
} else {
    assert(mode in code-config.palettes, message: "code: no palette for mode `" + mode + "`")
    _check-palette(code-config.palettes.at(mode))
}

// Who highlights a listing: `theme: none` — nobody, one flat ink; a spec — this
// module, with `mark:` on top; otherwise syntect, but only when there is no
// mark to honour, since syntect cuts every token apart and most marks would
// silently miss.
#let _resolve-highlighter(theme, marks, lang) = {
    if theme == none {
        (lang: none, syntect: false)
    } else if lang != none {
        (lang: lang, syntect: false)
    } else {
        (lang: none, syntect: marks.len() == 0)
    }
}

// Repaint the spans Typst's built-in theme produced, keyed by their color.
// `fill` always lands; `weight` only when the row asks. Spans whose fill is not
// in the table (dim ink, marks) are left alone.
#let _syntax-rule(palette) = {
    let rows = (:)
    for (bucket, key) in _classifier {
        let row = palette.syntax.at(bucket)
        rows.insert(
            key,
            (fill: row.at("fill", default: palette.fg), weight: row.at("weight", default: none)),
        )
    }
    it => context {
        let painted = text.fill
        let row = if type(painted) == color { rows.at(painted.to-hex(), default: none) } else { none }
        if row == none {
            it
        } else if row.weight == none {
            set text(fill: row.fill)
            it
        } else {
            set text(fill: row.fill, weight: row.weight)
            it
        }
    }
}

#let _render-code(spec, height: auto, outer-spacing: true) = context {
    let (colors, font-sizes, mode) = theme()
    let code-langs = theme().at("code-langs", default: code-config.langs)
    let accent = if spec.accent == auto { colors.primary } else { spec.accent }
    let resolved-size = (if spec.size == auto { font-sizes.code } else { spec.size }) * spec.scale
    let inset = if type(spec.inset) == ratio { spec.inset * resolved-size } else { spec.inset }
    let pad = if spec.frame { inset } else { 0pt }

    let marks = _mark-list(spec.mark)
    let palette = _resolve-palette(spec.theme, mode)
    // Settle who highlights this listing before `raw` is set up.
    let (lang, syntect) = _resolve-highlighter(
        spec.theme,
        marks,
        _resolve-lang(spec.lang, _first-lang(spec.body), code-langs),
    )
    // One mono character width sizes the gutter and every wrap indent.
    let char-width = measure(text(font: spec.font, size: resolved-size, "0")).width

    let focus-lines = _line-set(spec.focus, "focus")
    let hl-lines = _line-set(spec.hl, "hl") + focus-lines
    let dim-lines = _line-set(spec.dim, "dim")
    let dim-ink = palette.fg.transparentize(code-config.dim-tint)
    let num-ink = palette.fg.transparentize(code-config.number-tint)

    let inner = {
        set text(size: resolved-size, fill: palette.fg)
        set par(leading: spec.leading, spacing: spec.gap)
        // `auto` is Typst's built-in theme, whose tokens `_syntax-rule` repaints;
        // `none` leaves one ink, which is what a spec-highlighted listing wants.
        set raw(
            theme: if syntect { auto } else { none },
            tab-size: if spec.indent == auto { 2 } else { spec.indent },
        )
        show raw: set text(font: spec.font, size: resolved-size)
        show raw: set par(leading: spec.leading)
        show raw: it => if it.lang == _flat-lang { it } else {
            // `focus:` is `hl:` plus "mute everything else".
            let dims = if focus-lines.len() > 0 {
                range(1, it.lines.len() + 1).filter(n => n not in hl-lines)
            } else {
                dim-lines
            }
            // A gutter and a language belong to a listing, not to inline `raw` in the prose.
            show raw.line: _line-rule((
                hl-lines: hl-lines,
                dim-lines: dims,
                dim-ink: dim-ink,
                num-ink: num-ink,
                pad: pad,
                numbers: spec.numbers and it.block,
                lang: if it.block { lang } else { none },
                palette: palette,
                char-width: char-width,
            ))
            if syntect {
                show text: _syntax-rule(palette)
                it
            } else {
                it
            }
        }
        _apply-marks(spec.body, marks, accent)
    }

    // A listing on its own takes the flow rhythm; inside a row the row owns the spacing.
    let outer = if outer-spacing { auto } else { 0pt }
    // The visible listing at the height it is asked for.
    let surface = (target-height, above: 0pt, below: 0pt) => if spec.frame {
        block(
            width: 100%,
            height: target-height,
            above: above,
            below: below,
            breakable: spec.breakable,
            fill: palette.bg,
            stroke: (paint: palette.border, thickness: code-config.border-width),
            radius: code-config.radius,
            inset: inset,
        )[#inner]
    } else {
        block(width: 100%, height: target-height, above: above, below: below, breakable: spec.breakable)[#inner]
    }

    if spec.stretch or height == auto {
        surface(height, above: outer, below: outer)
    } else {
        // Keep the row's height so a caption stays on the shared band; only the surface stays natural.
        block(width: 100%, height: height, above: outer, below: outer, spacing: 0pt)[
            #surface(auto)
        ]
    }
}

// Code block with an optional caption. `frame: false` keeps the typography and
// every emphasis treatment but drops the surface, for a listing already sitting
// inside a box helper. The result is a `vboxs` row item, so a bare listing can be
// one column of an equal-height row; inside a row its frame stretches to the row
// height unless `stretch: false` holds it at its natural one.
#let code(
    body,
    caption: none,
    cap-size: auto,
    cap-weight: auto,
    cap-color: auto,
    cap-gap: auto,
    frame: true,
    hl: (),
    dim: (),
    focus: none,
    mark: (),
    numbers: code-config.numbers,
    // `auto` looks the fence's own tag up in the deck's language registry;
    // `none` sends the listing to syntect; a name or a `code-lang(...)` spec
    // highlights it here whatever the fence says.
    lang: auto,
    accent: auto,
    font: code-config.font,
    size: code-config.size,
    scale: code-config.scale,
    stretch: code-config.stretch,
    leading: code-config.leading,
    gap: code-config.gap,
    indent: code-config.indent,
    inset: code-config.inset,
    theme: auto,
    breakable: code-config.breakable,
) = {
    assert(
        theme == auto or theme == none or type(theme) == dictionary,
        message: "code: `theme` must be `auto`, `none`, or a palette dictionary, got " + repr(theme),
    )
    assert(type(numbers) == bool, message: "code: `numbers` must be a bool, got " + repr(numbers))
    if indent != auto {
        assert(
            type(indent) == int and indent > 0,
            message: "code: `indent` must be `auto` or a positive int, got " + repr(indent),
        )
        // Re-indenting rewrites raw elements, which only reaches fences sitting
        // directly in the code body. Fail here rather than silently leave a
        // wrapped listing at its source indent.
        assert(_holds-raw(body), message: "code: `indent` found no raw fence directly in the body")
        body = _reindent(body, indent)
    }
    let foot = caption-foot(
        caption,
        cap-size: cap-size,
        cap-weight: cap-weight,
        cap-color: cap-color,
        cap-gap: cap-gap,
    )
    box-item(
        (
            kind: "code",
            render: _render-code,
            foot: foot,
            frame: frame,
            hl: hl,
            dim: dim,
            focus: focus,
            mark: mark,
            numbers: numbers,
            lang: lang,
            accent: accent,
            font: font,
            size: size,
            scale: scale,
            stretch: stretch,
            leading: leading,
            gap: gap,
            indent: indent,
            inset: inset,
            theme: theme,
            breakable: breakable,
        ),
        body,
    )
}
