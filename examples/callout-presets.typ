#import "/lemonade.typ": *

#show: lemonade-theme.with(
    aspect-ratio: "16-9",
    footer: none,
    config-info(
        title: [Callout and Table Presets],
        author: [Lemonade],
        date: none,
    ),
)

#let options-table = vtable.with(
    columns: (1.05fr, 0.65fr, 0.65fr),
    header: ([Metric], [Before], [After]),
    palette: "blue",
    center-cols: (1, 2),
    text-size: 18pt,
    header-text-size: 18pt,
    inset: (left: 0.22em, right: 0.12em, top: 0.22em, bottom: 0.22em),
    first-column: true,
    last-column: true,
    total-row: true,
)

#let column-table = vtable.with(
    columns: (1fr, 1fr, 1fr, 1fr),
    header: ([Q1], [Q2], [Q3], [Q4]),
    palette: "red",
    center-cols: (0, 1, 2, 3),
    text-size: 16pt,
    header-text-size: 16pt,
    inset: (x: 0.12em, y: 0.18em),
    banded-rows: false,
    banded-columns: true,
)

#let fill-table = vtable.with(
    columns: (0.8fr, 1.3fr, 0.7fr),
    header: ([Option], [Notes], [Score]),
    palette: "blue",
    center-cols: (2,),
    text-size: 16pt,
    header-text-size: 16pt,
    fill-height: true,
    row-stretch: "content",
    inset: (x: 0.16em, y: 0.18em),
    column-styles: (
        (weight: "black", leading: 0.75em),
        (leading: 0.72em),
        (align: center),
    ),
)

#let weighted-fill-table = fill-table.with(
    palette: "red",
    row-weights: (1, 2, 1),
)

#title-slide()

== Callout colors

#callout[*White* is the default callout color]

#bcallout[*Blue* uses Berkeley blue and California gold]

#rcallout[*Red* uses theme primary and secondary colors]

#callout(color: "white", emph-fill: rgb("#003262"))[*Overrides* still work]

== Table options

#options-table(
    [Compile time], [42s], [31s],
    [Peak memory], [8.4GB], [6.9GB],
    [Throughput], [91], [124],
    [Summary], [Baseline], [Improved],
)

#v(0.22in)

#column-table(
    [22], [25], [31], [35],
    [18], [24], [28], [32],
)

== Fill-height tables

#fill-table(
    [A], [Short note.], [7],
    [B], [Longer note that wraps over multiple lines so content-proportional row stretching has something to work with.], [9],
    [C], [Compact note.], [6],
)

== Weighted fill-height tables

#weighted-fill-table(
    [A], [One share of the remaining space.], [7],
    [B], [Two shares of the remaining space via `row-weights`.], [9],
    [C], [One share again.], [6],
)
