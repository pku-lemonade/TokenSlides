#import "/lemonade.typ": *

// A DSL of one's own, declared once at the top of the deck and registered
// under the fence tag it answers to. Rules are tried in order, so `comment`
// and `string` first is what keeps a keyword inside either one quiet.
#let tdsl = code-lang(
    ("comment", "#.*"),
    ("string", "\"(?:[^\"\\\\]|\\\\.)*\""),
    // The capture is what gets the bucket; `kernel` goes back through the
    // rules and comes out a keyword, which is how a name is picked out with
    // no look-behind to reach for.
    ("name", "\\bkernel\\s+([A-Za-z_][A-Za-z0-9_]*)"),
    ("keyword", ("kernel", "tile", "at", "time", "yield", "->")),
    ("number", "\\b[0-9]+\\b"),
)

#show: lemonade-theme.with(
    aspect-ratio: "16-9",
    box-compact: true,
    title: [code block check],
    author: [Lemonade],
    institution: [Theme QA],
    code-langs: (tdsl: tdsl),
)

= Code Blocks

== Plain listing

Snippets are ordinary raw fences, so the source stays readable and markup may
sit beside the listing.

#code[
    ```python
    @tm.func
    def axpy[t: Time](x: Tile @ t, y: Tile @ t, alpha: f32) -> Tile @ (t + 1):
        return tm.fma(alpha, x, y)
    ```
    Both operands must arrive at the same logical time.
]

== Line numbers

The gutter is on by default, two digits wide, so the line numbers `hl:` and
`focus:` take are ones the audience can see. `numbers: false` drops it.

#vboxs(
    code(scale: 90%)[
        ```python
        def axpy(x, y, alpha):
            return tm.fma(alpha, x, y)
        ```
    ],
    code(scale: 90%, numbers: false)[
        ```python
        def axpy(x, y, alpha):
            return tm.fma(alpha, x, y)
        ```
    ],
    after: hbox[Same snippet with the gutter on and off.],
)

== Captions

`caption:` uses the same foot band as `img`, so listings end on one line even
when one caption wraps.

#vboxs(
    code(caption: [Short caption], scale: 90%)[
        ```python
        x = load(X)
        y = compute(x)
        ```
    ],
    code(
        caption: [A longer caption that wraps while both code frames stay aligned],
        scale: 90%,
    )[
        ```python
        x = load(X)
        y = compute(x)
        ```
    ],
)

== Natural-height frames

A listing's frame fills the height its row hands down, so side-by-side frames
match whatever their snippets do. `stretch: false` draws the frame at its
natural height instead; the cell still holds the row's, so a caption under it
stays on the shared band.

#vboxs(
    code(stretch: false, scale: 90%)[
        ```python
        x = load(X)
        y = compute(x)
        ```
    ],
    code(stretch: false, scale: 90%)[
        ```python
        x = load(X)
        y = compute(x)
        z = activate(y)
        store(Z, z)
        ```
    ],
    after: hbox[The visible frames stay natural; the row geometry does not move.],
)

== Wrapped lines

A line too long for the frame wraps, and its continuation hangs under its own
first code column — so a wrap reads as one line, and the highlight band covers
every row of it.

#code(hl: (2,))[
    ```python
    acc = tm.zeros((BM, BN))
    scores = tm.matmul(q, k.transpose(-2, -1)) * scale + bias_for_the_current_block + tail
    for q in tm.domain(K // BK):
        acc = tm.mma(a, b, acc, argument_three, argument_four, argument_five, arg_six)
    ```
]

A single token wider than the frame has nowhere to break and overflows on
purpose. Buy width with `indent:` first and `scale:` second.

== Highlighted lines

`hl:` bands the given 1-based line numbers; `range(...)` works as the argument.

#code(hl: range(2, 4))[
    ```python
    acc = tm.zeros((BM, BN))
    for q in tm.domain(K // BK):
        tq = t0 + q * II
    tm.store(C, acc)
    ```
]

== Focused lines

`focus:` bands the same lines and mutes every other one, so the accent is the
only color left on the slide.

#code(focus: (3, 4))[
    ```python
    def fir3(X, Y, c):
        for i in range(N):
            x1 = tm.load(X[i - 1]).at(ti - II)
            x2 = tm.load(X[i - 2]).at(ti - 2*II)
            tm.store(Y[i], tm.dot(c, taps))
    ```
]

== Marked tokens

`mark:` accents a token wherever it appears, over the highlighting rather than
instead of it — a marked token inside a comment or a string stays marked.

#code(mark: ("@ t", "@ (t + 1)", "tm.load"))[
    ```python
    @tm.func
    def axpy[t: Time](x: Tile @ t, y: Tile @ t) -> Tile @ (t + 1):
        return tm.fma(alpha, x, y)

    x = tm.load(X[i]).at(ti)
    ```
]

Pass a `regex` for a pattern rather than a literal.

#code(mark: (regex("tm\\.\\w+"),), accent: rgb("#7652ac"))[
    ```python
    a = tm.load(A[:, q]).at(tq)
    acc = tm.mma(a, b, acc)
    tm.store(C, acc)
    ```
]

== When a mark misses

A mark only lands inside one run of what the highlighter cut the line into.
`@ t` and `tm.load` are plain text to `python-lang`, so they land; `@ (t + 1)`
does not, because the `1` is a number run and the mark crosses it.

#vboxs(
    code(scale: 90%, mark: ("@ (t + 1)",))[
        ```python
        def axpy(x) -> Tile @ (t + 1):
            return x
        ```
    ],
    code(scale: 90%, lang: none, mark: ("@ (t + 1)",))[
        ```python
        def axpy(x) -> Tile @ (t + 1):
            return x
        ```
    ],
    after: hbox[Left: the mark misses. Right: `lang: none` marks it.],
)

== Code inside boxes

The box takes the row slot; the listing inside keeps its natural height and
still draws its own caption. Left: no surface twice — the box's is the
listing's. Right: a framed listing, with a partial `body-inset` trimming the
box padding its frame reaches past.

#vboxs(
    ebox[
        #code(caption: [Operational sync], frame: false, scale: 80%, mark: ("wait_ready",))[
            ```python
            x = async_load(X[i])
            y = async_load(Y[i])
            wait_ready(x)
            wait_ready(y)
            z = axpy(x, y, alpha)
            ```
        ]
    ],
    pbox(body-inset: (right: 0pt))[
        #code(caption: [Declarative timing], scale: 80%, mark: ("@ t",))[
            ```python
            def axpy[t: Time](
                x: Tile @ t,
                y: Tile @ t,
            ):
                return tm.fma(alpha, x, y)
            ```
        ]
    ],
    after: hbox[`t + 1` is a logical budget, not one physical cycle.],
)

== Narrower indent

A bare `#code` is a `vboxs` row item, so two unlabelled listings compare
directly. `indent: 2` re-indents the source's own indent unit — usually what
buys a slide listing a larger font.

#vboxs(
    code(scale: 90%)[
        ```python
        def dp_row_major(H):
            for i in range(1, M):
                for j in range(1, N):
                    H[i, j] = cell(
                        H[i - 1, j],
                        H[i, j - 1],
                    )
        ```
    ],
    code(scale: 90%, indent: 2)[
        ```python
        def dp_row_major(H):
            for i in range(1, M):
                for j in range(1, N):
                    H[i, j] = cell(
                        H[i - 1, j],
                        H[i, j - 1],
                    )
        ```
    ],
    after: hbox[Same snippet at `indent: auto` and `indent: 2`.],
)

== Palette and font

The default palette assigns restrained semantic colors while retaining the
current mode's surface. A `theme:` dict can still replace the whole palette;
`theme: none` drops highlighting entirely.

#vboxs(
    code(scale: 90%, indent: 2)[
        ```python
        # two taps, one logical time
        def axpy(x, y, alpha=1.0):
            return tm.fma(alpha, x, y)
        ```
    ],
    code(scale: 90%, indent: 2, theme: none, font: ("Menlo", "Source Han Sans SC"))[
        ```python
        # two taps, one logical time
        def axpy(x, y, alpha=1.0):
            return tm.fma(alpha, x, y)
        ```
    ],
    after: hbox[Left: the shared semantic palette. Right: `theme: none` in Menlo.],
)

== A language of one's own

`code-lang(...)` is an ordered list of `(bucket, pattern)` rules this theme
matches itself. Register it with `lemonade-theme(code-langs: (tdsl: ...))` at
the top of the deck and every ```` ```tdsl ```` fence picks it up — see the head
of this file.

#code(hl: (2,))[
    ```tdsl
    # rules are tried in order, so a "kernel at 3" here stays a comment
    kernel axpy at time 3 -> tile 128
        yield tile 64
    ```
]

== Two highlighters

Python ships as a spec (`python-lang`), so the theme owns every token in it. A
fence whose tag is not registered goes to syntect instead, and `lang: none`
sends a registered one back there — coarser buckets, but every language Typst
knows.

#vboxs(
    code(scale: 90%, indent: 2)[
        ```python
        # theme rules
        def axpy(x, y, alpha=1.0):
            return tm.fma(alpha, x, y)
        ```
    ],
    code(scale: 90%, indent: 2, lang: none)[
        ```python
        # syntect
        def axpy(x, y, alpha=1.0):
            return tm.fma(alpha, x, y)
        ```
    ],
    after: hbox[Same snippet, `lang: auto` and `lang: none`.],
)

== Sizing and plain text

`size:` overrides the aspect ratio's code size outright; a fence with no
language is left unhighlighted, which suits compiler output — and output has no
line numbers to point at, so the gutter comes off.

#code(size: 16pt, numbers: false)[
    ```
    error: axpy timing contract unsatisfied
      required: x @ t, y @ t
      actual:   x @ ti, y @ (ti + 1)
    ```
]
