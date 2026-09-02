#import "base.typ": theme
#import "boxes.typ": box-item
#import "images.typ": caption-foot

// USER CONFIG
// - Frame geometry, typography, and the listing font: edit `code-config` below.
// - Surface and syntax styling: edit `light-code-palette` / `dark-code-palette`
//   below. They are ordinary Typst dicts; nothing here reads or writes a
//   `.tmTheme` file.
// - Which languages this module highlights itself: `code-config.langs`, whose
//   entries are `code-lang(...)` rule lists (`python-lang` ships below). A deck
//   adds its own with `lemonade-theme(code-langs: (mydsl: ...))`.
// - Base code font size per aspect ratio: `font-sizes.code` in `layout-config`
//   (base.typ), where it stays in proportion to the body sizes it shares a
//   slide with; `size` / `scale` here rescale a single listing.
//
// One knob stays outside this module on purpose: `font-config.mono` (base.typ)
// is the shared mono family for footers, outlines, tables, page numbers, and
// inline `raw` in prose. Listings take `code-config.font` instead, so the two
// can differ — if you change one deliberately, look at the other.
//
// Snippets are ordinary Typst raw fences, so the source stays readable and any
// markup may sit beside the listing:
//
//     #code[
//       ```python
//       def axpy(x, y, alpha):
//           return fma(alpha, x, y)
//       ```
//       Both operands must share one logical time.
//     ]
//
// Emphasis inside a listing:
//   `hl: (2, 3)`      neutral band behind those lines
//   `focus: (2, 3)`   the band, plus every other line muted to one flat ink
//   `dim: (1,)`       mute these lines, leave the rest alone
//   `mark: ("@ t",)`  accent the token wherever it appears
// Line numbers are 1-based; `range(2, 5)` works as the argument. `focus:` and
// `dim:` are alternatives, not a pair — with `focus:` set, `dim:` is ignored,
// because focusing already decides what every other line looks like.
//
// A mark and the highlighter share the line, and a mark lands wherever it falls
// inside one piece of what the highlighter cut up — which is most places, since a
// spec only cuts out what it describes. A mark that crosses a boundary
// (`while q < Q`, where `while` is a keyword) silently does not match; put
// `lang: none` on that listing to drop highlighting and mark everything. Syntect
// cuts at every token, so marks turn it off outright (`_resolve-highlighter`).
//
// The gutter is on by default, two digits wide, so `hl: (2, 3)` points at
// something the audience can see. `numbers: false` drops it for one listing,
// `code-config.numbers` for the deck.
//
// A line too long for the frame wraps, and its continuation hangs under its own
// first code column rather than under the gutter, so a wrapped line still reads
// as one line (`code-config.wrap-indent` pushes continuations deeper). A single
// token wider than the frame has no break opportunity inside it and overflows
// visibly — that is deliberate. Shorten it, or buy width with `indent:` first
// and `scale:` second.
//
// A listing's width is the text column; the space to its right is the slide's
// own `layout-config.margins.right` (base.typ), which moves prose and tables
// with it. `code-config.inset` is the code-local part of that gap.
//
// `caption:` labels a listing below its frame in the shared row-item caption
// style (`img-config`, images.typ); a `vboxs` row aligns every caption in it on
// one reserved band. A bare `#code` is a row item, so an unlabelled listing can
// be a column of an equal-height row directly, and its frame fills the height
// the row hands down — `stretch: false` leaves the visible frame at its natural
// height while the cell still holds the row's, which keeps the captions aligned.
// A listing inside a box helper is handed no row height at all: pass
// `frame: false` there and the box's own surface is the listing's.

// How a listing reads, per mode. `bg` / `border` are the frame; `fg` is the ink
// for prose in the code body, for every token the palette does not repaint, and
// (transparentized) for `dim:`.
//
// Typst highlights raw blocks with `syntect`, and syntect's only input for
// colors is a TextMate theme. Rather than hand `raw` a theme of our own — which
// would mean generating plist XML, since that is the only format it takes — we
// let Typst's built-in theme do the classifying and remap what it produced:
// the color it painted a span with is readable back out of the span with
// `context text.fill`. That is the whole reason no `.tmTheme` file, and no code
// that writes one, exists in this repo.
//
// The catch is that the built-in theme's colors are an implementation detail of
// Typst rather than a documented API. `_classifier` below is the observed table,
// and a Typst upgrade that changes the default theme would make every key miss
// — listings would fall back to the built-in colors, which are tuned for a white
// page and go unreadable on a dark `bg`. To re-derive it, render a snippet under
//
//     show raw: it => { show text: t => context metadata((txt: t.text, fill: text.fill.to-hex())); it }
//
// and `query(metadata)` the result. (`t.fill` is not readable as a field; only
// the contextual `text.fill` is.)
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

// The bucket vocabulary, shared by both highlighters: syntect spans reach it by
// color through `_classifier`, and a `code-lang` rule names it outright. One
// palette row therefore styles a token the same way whichever highlighter
// produced it, and a deck that swaps a listing's language keeps its look.
#let _buckets = _classifier.keys()

// A `syntax` row styles one classifier bucket. `fill` defaults to the palette's
// `fg`, so a bucket left bare is simply not colored — that is what keeps a
// listing quiet. `weight` is left unset unless a row asks for one, so the bold
// that `hl:` puts on a banded line survives on the tokens the palette does not
// weight itself. Every bucket needs a row; adding one to `_classifier` without
// one here fails at render.
//
// The default uses a restrained semantic palette: comments recede, declarations
// and names stay cool, literals stay distinct, and keywords carry the strongest
// warm accent. The light and dark rows keep the same roles at suitable contrast.
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

#let _regex-specials = ("\\", ".", "+", "*", "?", "(", ")", "[", "]", "{", "}", "^", "$", "|", "/", "-")

#let _regex-escape(s) = s.clusters().map(c => if c in _regex-specials { "\\" + c } else { c }).join("")

// LANGUAGE SPECS
//
// A spec is an ordered list of `(bucket, pattern)` rules that this module
// matches across a line itself, instead of handing the line to syntect. The
// first rule that matches at a position wins, and that ordering is the whole
// point: put `comment` and `string` first and a `def` inside either one stays
// comment or string ink — which is exactly what a pile of `show regex` rules
// cannot do, since those all match independently of one another.
//
// `bucket` is one of `_buckets`, so a spec-highlighted listing wears the same
// palette rows as a syntect-highlighted one.
//
// `pattern` is a regex SOURCE STRING, or an array of literal words. Never a
// `regex` value: it cannot be spliced into the combined alternation this
// builds, because its `repr` re-escapes backslashes. Leave anchors out — every
// rule is matched inside a line, never against the whole of one. There is no
// look-around either; Typst's regex engine has none.
//
// Capture what the rule should actually color when it has to match more than
// that to find it. `("name", "\\bdef\\s+([A-Za-z_]\\w*)")` colors the name and
// hands `def ` back to the other rules, which is how a name is picked out
// without look-behind. Only the first capture group is read.
//
//     #let tm-lang = code-lang(
//       ("comment", "#.*"),
//       ("keyword", ("kernel", "tile", "at", "yield")),
//       ("number", "\\b[0-9]+\\b"),
//     )
//
// Register it deck-wide with `lemonade-theme(code-langs: (tdsl: tm-lang))` and
// every ```tdsl fence picks it up, or hand it to one listing as `lang:`.
#let _word-char(c) = c.match(regex("^\\w$")) != none

// `\b` is worth adding only where the word actually has a word boundary: an
// operator like `->` has none, and `\b->\b` would never match.
#let _words-pattern(words, bucket) = {
    assert(words.len() > 0, message: "code-lang: bucket `" + bucket + "` got an empty word list")
    let atom(w) = {
        assert(
            type(w) == str and w.len() > 0,
            message: "code-lang: bucket `" + bucket + "` takes non-empty strings, got " + repr(w),
        )
        let pre = if _word-char(w.first()) { "\\b" } else { "" }
        let post = if _word-char(w.last()) { "\\b" } else { "" }
        pre + _regex-escape(w) + post
    }
    // Longest first, so no word is shadowed by another that is a prefix of it.
    "(?:" + words.sorted(key: w => -w.len()).map(atom).join("|") + ")"
}

#let code-lang(..rules) = {
    assert(
        rules.named().len() == 0,
        message: "code-lang: takes positional `(bucket, pattern)` rules, got named " + repr(rules.named().keys()),
    )
    assert(rules.pos().len() > 0, message: "code-lang: needs at least one rule")
    let out = ()
    for rule in rules.pos() {
        assert(
            type(rule) == array and rule.len() == 2,
            message: "code-lang: a rule is a `(bucket, pattern)` pair, got " + repr(rule),
        )
        let (bucket, pattern) = rule
        assert(
            bucket in _buckets,
            message: "code-lang: unknown bucket " + repr(bucket) + "; pick one of " + repr(_buckets),
        )
        let source = if type(pattern) == array {
            _words-pattern(pattern, bucket)
        } else if type(pattern) == str {
            "(?:" + pattern + ")"
        } else {
            panic(
                "code-lang: bucket `"
                    + bucket
                    + "` takes a pattern string or an array of literal words, got "
                    + repr(pattern),
            )
        }
        // `test` re-identifies a token once the combined pattern has cut it out
        // (see `_tokenize`), which is why each rule keeps its own anchored copy.
        out.push((bucket: bucket, source: source, test: regex("^(?:" + source + ")$")))
    }
    (rules: out, all: regex(out.map(r => r.source).join("|")))
}

#let _check-lang(lang) = {
    assert(
        type(lang) == dictionary and "rules" in lang and "all" in lang,
        message: "code: a language spec must come from `code-lang(...)`, got " + repr(lang),
    )
    lang
}

// Built-in Python. Ordinary config: edit the word lists, drop a rule, or
// replace the whole spec from a deck with `code-langs: (python: ...)`.
// `code-langs: (python: none)` hands Python back to syntect.
//
// Only what earns a bucket is listed. Everything a rule does not claim is
// `plain`, so identifiers, operators and punctuation stay body ink.
#let python-lang = code-lang(
    ("comment", "#.*"),
    // Prefixed and plain strings, single or double quoted, backslash aware.
    // Every rule matches within one line, so a triple-quoted docstring is
    // highlighted row by row: the opening row runs to its end, and a row that
    // closes one is matched by the lazy alternative. An unterminated quote also
    // runs to the end of its row rather than dropping the whole rule, which is
    // what keeps a half-typed line from flickering back to plain ink.
    (
        "string",
        "(?:[fFrRbBuU]|[rR][bB]|[bB][rR]|[fF][rR]|[rR][fF])?"
            + "(?:\"\"\"(?:.*?\"\"\"|.*)"
            + "|'''(?:.*?'''|.*)"
            + "|\"(?:[^\"\\\\\\n]|\\\\.)*\"?"
            + "|'(?:[^'\\\\\\n]|\\\\.)*'?)",
    ),
    ("decorator", "@[A-Za-z_][A-Za-z0-9_.]*"),
    // The name being defined, before the keyword rule can claim the `def` or
    // `class` this keys off — the capture is what gets the bucket, and the
    // keyword goes back through the rules.
    ("name", "\\b(?:def|class)\\s+([A-Za-z_][A-Za-z0-9_]*)"),
    (
        "keyword",
        (
            "def",
            "class",
            "lambda",
            "return",
            "yield",
            "await",
            "async",
            "if",
            "elif",
            "else",
            "for",
            "while",
            "break",
            "continue",
            "pass",
            "try",
            "except",
            "finally",
            "raise",
            "with",
            "as",
            "import",
            "from",
            "global",
            "nonlocal",
            "assert",
            "del",
            "in",
            "is",
            "not",
            "and",
            "or",
            "match",
            "case",
            "True",
            "False",
            "None",
            "self",
            "cls",
        ),
    ),
    (
        "name",
        (
            "abs",
            "all",
            "any",
            "bool",
            "bytes",
            "dict",
            "enumerate",
            "filter",
            "float",
            "frozenset",
            "getattr",
            "hasattr",
            "int",
            "isinstance",
            "issubclass",
            "iter",
            "len",
            "list",
            "map",
            "max",
            "min",
            "next",
            "object",
            "open",
            "print",
            "range",
            "repr",
            "reversed",
            "round",
            "set",
            "setattr",
            "sorted",
            "str",
            "sum",
            "super",
            "tuple",
            "type",
            "zip",
        ),
    ),
    // Ints, floats, exponents, hex/oct/bin, and `1_000_000`.
    (
        "number",
        "\\b(?:0[xX][0-9a-fA-F_]+|0[oO][0-7_]+|0[bB][01_]+|[0-9][0-9_]*(?:\\.[0-9_]*)?(?:[eE][-+]?[0-9]+)?j?)\\b",
    ),
)

#let code-config = (
    // Languages this module highlights itself, keyed by the fence tag they
    // answer to. A fence whose tag is not here goes to syntect, so a deck only
    // describes what it wants exact control over. Deck-level additions merge in
    // through `lemonade-theme(code-langs: ...)`.
    langs: (python: python-lang),
    // Listing font. Deliberately its own knob rather than `font-config.mono`,
    // which also dresses footers, outlines, tables, and inline `raw` in prose.
    font: ("Inconsolata", "Source Han Sans SC"),
    // A ratio is resolved against the listing's own font size, so the frame
    // keeps its proportions when `scale` shrinks the code; a length is used
    // as given. This is the only part of a listing's right-hand gap that is
    // code-local — the rest is the slide margin (see the header comment).
    inset: 40%,
    border-width: 1pt,
    radius: 0pt,
    // On, so a listing that outgrows its slide splits and stays visible. Off,
    // the frame is pushed to the next region whole and — being inside the
    // figure `box-item` wraps every row item in — is dropped there without a
    // warning (see `apply-box-style` in boxes.typ). A listing that fits is laid
    // out identically either way.
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
    // Extra indent for the continuation rows of a wrapped line, past the
    // line's own code column. `0pt` aligns a continuation with the code it
    // belongs to; a couple of characters' worth makes the wrap more obvious.
    wrap-indent: 0pt,
    // Indent width, in spaces. `auto` leaves the source alone. An integer
    // re-indents space-indented lines to that many spaces per level (the
    // source's own unit is its smallest non-zero indent) and sets `tab-size`
    // for tab-indented ones. Slides are short on width: `indent: 2` is often
    // what buys a listing a larger font.
    indent: auto,
    // Palette per mode, picked by the deck's `mode`. A listing may override the
    // whole palette with `theme: (bg: ..., border: ..., fg: ..., syntax: (...))`
    // or switch highlighting off with `theme: none` (one flat `fg` ink). A
    // `.tmTheme` path is not accepted: the palette styles the buckets in
    // `_classifier`, which only the built-in theme produces.
    palettes: (light: light-code-palette, dark: dark-code-palette),
    // `hl:` — a quiet neutral band behind emphasized lines, bled to the frame
    // edge. The accent remains reserved for `mark:` tokens.
    hl-tint: 92%,
    hl-weight: "bold",
    // Vertical growth of the band past the line box, so consecutive
    // highlighted lines read as one continuous band.
    hl-outset: 0.25em,
    // `dim:` / the muted half of `focus:`.
    dim-tint: 55%,
    // Line-number gutter. `numbers` is the deck-wide default, overridable per
    // listing with `numbers:`. `number-digits` is the width the number is
    // zero-padded to — two digits is enough for any slide-sized listing, and a
    // longer one widens on its own rather than spilling into the code. The ink
    // is `fg` pushed back by `number-tint`, so it follows any palette,
    // `theme: none` included, without a palette key of its own.
    numbers: true,
    number-digits: 2,
    number-gap: 0.8em,
    number-tint: 60%,
    // `mark:` token emphasis, over the accent. A marked token outranks whatever
    // the highlighter would have made of it, comment and string ink included:
    // marking says "look here", and it is the only thing on the slide that does.
    mark-weight: "bold",
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

// Rescale leading spaces from the source's own indent unit to `width`. The unit
// is the smallest non-zero indent in the snippet, which is right for ordinary
// code and predictable when it is not: a hanging indent finer than one level
// makes every deeper line scale from that finer unit. Lines are rescaled rather
// than de-levelled so continuation lines keep their relative alignment.
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

// The tag of the first block fence in the body, which is the listing's own
// language: a `#code` body holds one listing, and any other raw in it is inline
// `raw` in the prose beside it, which is not a listing and is not highlighted.
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
        _check-lang(lang)
    } else if type(lang) == str {
        assert(
            lang in langs,
            message: "code: no language spec named `" + lang + "`; registered: " + repr(langs.keys()),
        )
        assert(
            langs.at(lang) != none,
            message: "code: language spec `" + lang + "` is turned off by this deck's `code-langs`",
        )
        _check-lang(langs.at(lang))
    } else if lang == auto {
        let found = if fence == none { none } else { langs.at(fence, default: none) }
        if found == none { none } else { _check-lang(found) }
    } else {
        panic(
            "code: `lang` must be `auto`, `none`, a registered name, or a `code-lang(...)` spec, got " + repr(lang),
        )
    }
}

// Re-render a line as unhighlighted raw so a flat ink actually takes: syntax
// spans set `fill` on their own text, which an outer `set text(fill: ...)`
// cannot override. Rebuilding raw would re-enter both rules below, so the
// rebuilt line carries a sentinel `lang` the block rule skips, and a nested
// `raw.line` rule (defined last, so it wins) ends the line recursion.
//
// Nothing here is boxed. A `box` lays its content out as one unbreakable line,
// which would take a long line's wrap out of the hands of the paragraph that
// `_line-rule` puts every line in — and with it the hanging indent.
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

// Rebuild a line from its source as styled runs, by the same route as
// `_flat-line`: raw carrying the sentinel `lang` keeps each run's spaces exactly
// as written. A run with no `weight` row inherits the ambient one, which is what
// lets the bold from `hl:` through, exactly as in `_syntax-rule`.
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

// Zero-padding, rather than a fixed box width, is what aligns the gutter: every
// number is the same number of characters and the listing font is mono, so the
// code starts at one column without measuring anything.
#let _pad-number(n, digits) = {
    let s = str(n)
    if s.len() < digits { "0" * (digits - s.len()) + s } else { s }
}

// Plain `text`, not `raw`: the gutter is emitted from inside the raw element, so
// it already wears the listing font, and staying out of `raw` keeps it clear of
// both show rules below. Its ink is ours, so `_syntax-rule` leaves it alone.
#let _gutter(number, digits, ink) = {
    text(fill: ink, _pad-number(number, digits))
    h(code-config.number-gap)
}

// Every line is its own block holding its own paragraph, rather than all of
// them sharing the one paragraph a raw block would lay them out in. That is
// what buys the hanging indent: `par(hanging-indent:)` set on the whole listing
// does nothing, because there is only ever one paragraph and its second line is
// the listing's second line, not a wrap. `spacing: 0pt` keeps the rhythm the
// shared paragraph had — the gap between lines stays `leading`, as before.
#let _line-rule(cfg) = it => {
    // `it.count` is the listing's own line count, so a listing longer than
    // `number-digits` allows widens its gutter instead of pushing the code over
    // on that one line.
    let digits = calc.max(code-config.number-digits, str(it.count).len())
    let gutter = if cfg.numbers { _gutter(it.number, digits, cfg.num-ink) }

    // Where a continuation row starts: past the gutter, then past this line's
    // own indent, so a wrap hangs under the code it belongs to rather than
    // under the line number. The listing font is mono, so one measured
    // character width sizes both.
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
    // The band's weight lands on the code alone: the gutter holds one face down
    // the whole listing, so it reads as a ruler rather than joining in the
    // emphasis.
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
        // A `block`, so the band covers every row of a wrapped line and not
        // just its first. The `y` outset makes consecutive banded lines meet.
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

// One show rule per pattern rather than one merged alternation, because a
// `regex` value cannot be spliced back into a larger pattern (its `repr`
// re-escapes backslashes). Literals do merge into a single alternation,
// longest first, so a longer mark wins over a prefix of it.
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
        patterns.push(regex("(?:" + literals.map(_regex-escape).join("|") + ")"))
    }
    _fold-marks(body, patterns, ink)
}

#let _check-palette(palette) = {
    assert(type(palette) == dictionary, message: "code: a code palette must be a dictionary, got " + repr(palette))
    for key in ("bg", "border", "fg", "syntax") {
        assert(key in palette, message: "code: code palette needs a `" + key + "` key, got " + repr(palette.keys()))
    }
    for bucket in _classifier.keys() {
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

// Who highlights a listing. Three rules, in order:
//
//   `theme: none`  one flat ink, nothing highlights.
//   a spec         this module highlights. `mark:` still applies on top, from
//                  the show rules `_apply-marks` installs.
//   otherwise      syntect, but only if there is no mark to honour.
//
// The asymmetry is about how finely each highlighter cuts the line up, because a
// mark can only match inside one piece. Syntect makes a piece per token, so most
// marks would silently fail — not worth the colour, hence no highlighting there.
// A spec only cuts out what its own rules describe, so a mark usually has a big
// plain run to land in. One that crosses a run boundary (`while q < Q`, where
// `while` is a keyword) still fails silently: `lang: none` on that listing.
#let _resolve-highlighter(theme, marks, lang) = {
    if theme == none {
        (lang: none, syntect: false)
    } else if lang != none {
        (lang: lang, syntect: false)
    } else {
        (lang: none, syntect: marks.len() == 0)
    }
}

// Repaint the spans Typst's built-in theme produced, keyed by the color it gave
// them. `fill` always lands, so a bucket the palette leaves bare reverts to body
// ink rather than keeping the built-in hue; `weight` only lands when the row
// asks, which is what lets the bold from `hl:` through on everything else.
//
// Anything whose fill is not in the table is left alone. That covers the `dim:`
// ink and `mark:` accents, which are ours and already correct — and it is also
// where a Typst upgrade that moved the built-in theme would show up, as listings
// suddenly wearing the built-in colors.
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
    let (colors, font-sizes, mode, code-langs) = theme()
    let accent = if spec.accent == auto { colors.primary } else { spec.accent }
    let resolved-size = (if spec.size == auto { font-sizes.code } else { spec.size }) * spec.scale
    let inset = if type(spec.inset) == ratio { spec.inset * resolved-size } else { spec.inset }
    let pad = if spec.frame { inset } else { 0pt }

    let marks = _mark-list(spec.mark)
    let palette = _resolve-palette(spec.theme, mode)
    // The fence's own tag is read from the body rather than per fence, so who
    // highlights this listing is settled before `raw` is set up.
    let (lang, syntect) = _resolve-highlighter(
        spec.theme,
        marks,
        _resolve-lang(spec.lang, _first-lang(spec.body), code-langs),
    )
    // One character, once: the listing font is mono, so this sizes the gutter
    // and every wrap indent in it.
    let char-width = measure(text(font: spec.font, size: resolved-size, "0")).width

    let focus-lines = _line-set(spec.focus, "focus")
    let hl-lines = _line-set(spec.hl, "hl") + focus-lines
    let dim-lines = _line-set(spec.dim, "dim")
    let dim-ink = palette.fg.transparentize(code-config.dim-tint)
    let num-ink = palette.fg.transparentize(code-config.number-tint)

    let inner = {
        set text(size: resolved-size, fill: palette.fg)
        set par(leading: spec.leading, spacing: spec.gap)
        // `auto` is Typst's built-in theme, which classifies the tokens that
        // `_syntax-rule` then repaints; `none` leaves every token on one ink,
        // which is also what a spec-highlighted listing wants — `_spec-line`
        // rebuilds those lines from their source and never reads what syntect
        // made of them. Typst's own `tab-size` default is 2.
        set raw(
            theme: if syntect { auto } else { none },
            tab-size: if spec.indent == auto { 2 } else { spec.indent },
        )
        show raw: set text(font: spec.font, size: resolved-size)
        show raw: set par(leading: spec.leading)
        show raw: it => if it.lang == _flat-lang { it } else {
            // `focus:` is `hl:` plus "mute everything else"; the line count is
            // only known once the raw element itself is in hand.
            let dims = if focus-lines.len() > 0 {
                range(1, it.lines.len() + 1).filter(n => n not in hl-lines)
            } else {
                dim-lines
            }
            // A gutter, and a language, belong to a listing — not to inline
            // `raw` sitting in the prose beside it, which this rule also reaches.
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

    // A listing on its own takes the uniform flow rhythm; inside a row the row
    // owns the spacing, so the item adds none of its own.
    let outer = if outer-spacing { auto } else { 0pt }
    // The visible listing, at whatever height it is asked for. Spacing is the
    // caller's, since a natural-height surface is wrapped in the block that
    // carries it.
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
        // Keep consuming the row's assigned height so a following caption stays
        // on the shared foot band; only the visible code surface stays natural.
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
