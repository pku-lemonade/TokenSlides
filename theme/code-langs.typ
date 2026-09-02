// Language specs for `#code` listings: the `code-lang(...)` rule-list builder
// and the built-in Python spec. The bucket vocabulary lives here because both
// a spec rule and a palette row name a bucket; code.typ maps each bucket to
// the color Typst's built-in syntect theme paints it with.
#let code-buckets = ("comment", "keyword", "name", "decorator", "string", "number", "other", "plain")

#let _regex-specials = ("\\", ".", "+", "*", "?", "(", ")", "[", "]", "{", "}", "^", "$", "|", "/", "-")

#let regex-escape(s) = s.clusters().map(c => if c in _regex-specials { "\\" + c } else { c }).join("")

// LANGUAGE SPECS
//
// A spec is an ordered list of `(bucket, pattern)` rules that this module
// matches across a line itself, instead of handing the line to syntect. The
// first rule that matches at a position wins, and that ordering is the whole
// point: put `comment` and `string` first and a `def` inside either one stays
// comment or string ink — which is exactly what a pile of `show regex` rules
// cannot do, since those all match independently of one another.
//
// `bucket` is one of `code-buckets`, so a spec-highlighted listing wears the same
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
        pre + regex-escape(w) + post
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
            bucket in code-buckets,
            message: "code-lang: unknown bucket " + repr(bucket) + "; pick one of " + repr(code-buckets),
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

#let check-lang(lang) = {
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
