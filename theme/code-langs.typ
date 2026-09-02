// Language specs for `#code` listings: the `code-lang(...)` rule-list builder
// and the built-in Python spec. The bucket vocabulary lives here because both
// a spec rule and a palette row name a bucket; code.typ maps each bucket to
// the color Typst's built-in syntect theme paints it with.
#let code-buckets = ("comment", "keyword", "name", "decorator", "string", "number", "other", "plain")

#let _regex-specials = ("\\", ".", "+", "*", "?", "(", ")", "[", "]", "{", "}", "^", "$", "|", "/", "-")

#let regex-escape(s) = s.clusters().map(c => if c in _regex-specials { "\\" + c } else { c }).join("")

// LANGUAGE SPECS
//
// A spec is an ordered list of `(bucket, pattern)` rules matched across each
// line by this module instead of syntect. The first rule matching at a
// position wins, so put `comment` and `string` first and a `def` inside either
// keeps that ink.
//
// `bucket` is one of `code-buckets`. `pattern` is a regex source string or an
// array of literal words (never a `regex` value; no anchors; no look-around).
// Capture what the rule should color when it must match more to find it:
// `("name", "\\bdef\\s+([A-Za-z_]\\w*)")` colors the name and hands `def`
// back to the other rules. Only the first capture group is read.
//
//     #let tm-lang = code-lang(
//       ("comment", "#.*"),
//       ("keyword", ("kernel", "tile", "at", "yield")),
//       ("number", "\\b[0-9]+\\b"),
//     )
//
// Register it deck-wide with `lemonade-theme(code-langs: (tdsl: tm-lang))`, or
// hand it to one listing as `lang:`.
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

// Built-in Python: edit the word lists, drop a rule, or replace the whole spec
// from a deck with `code-langs: (python: ...)`; `(python: none)` hands Python
// back to syntect. Anything no rule claims is `plain`.
#let python-lang = code-lang(
    ("comment", "#.*"),
    // Prefixed and plain strings, single or double quoted, backslash aware. Rules
    // match within one line, so a triple-quoted string is highlighted row by row.
    (
        "string",
        "(?:[fFrRbBuU]|[rR][bB]|[bB][rR]|[fF][rR]|[rR][fF])?"
            + "(?:\"\"\"(?:.*?\"\"\"|.*)"
            + "|'''(?:.*?'''|.*)"
            + "|\"(?:[^\"\\\\\\n]|\\\\.)*\"?"
            + "|'(?:[^'\\\\\\n]|\\\\.)*'?)",
    ),
    ("decorator", "@[A-Za-z_][A-Za-z0-9_.]*"),
    // The defined name; the `def` / `class` it keys off goes back through the rules.
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
