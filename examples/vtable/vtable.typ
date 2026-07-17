#import "/lemonade.typ": *

#show: lemonade-theme.with(
    aspect-ratio: "16-9",
    footer: none,
    title: [vtable usage],
    author: [Lemonade],
    institution: [Theme examples],
)

= vtable

== Basic banded table

#vtable(
    columns: (1.4fr, 1fr, 0.8fr),
    header: ([Stage], [Latency], [Status]),
    center-cols: (1, 2),
    first-column: true,
    [Parse], [12 ms], [Done],
    [Optimize], [38 ms], [Running],
    [Code generation], [21 ms], [Queued],
)

== Grid table with a total row

#vtable(
    columns: (1.4fr, 0.8fr, 0.8fr),
    header: ([Model], [Throughput], [Speedup]),
    style: "grid",
    palette: "blue",
    header-fill: true,
    total-row: true,
    first-column: true,
    center-cols: (1, 2),
    stroke: 1.2pt,
    column-styles: (
        (align: left,),
        (text-fill: rgb("#164e63"),),
        (weight: "black", text-fill: rgb("#166534")),
    ),
    [Baseline], [128 tok/s], [1.00x],
    [Fused kernels], [181 tok/s], [1.41x],
    [Graph capture], [206 tok/s], [1.61x],
    [Best result], [206 tok/s], [*1.61x*],
)

== Reusable full-height preset

#let schedule-table = vtable.with(
    columns: (1.2fr, 2fr, 0.9fr),
    header: ([Phase], [Deliverable], [Owner]),
    palette: "blue",
    center-cols: (2,),
    first-column: true,
    fill-height: true,
    row-stretch: "equal",
    text-size: 22pt,
    header-text-size: 22pt,
)

#schedule-table(
    [Discover], [Profile representative workloads], [Compiler],
    [Design], [Choose fusion and tiling strategies], [Research],
    [Implement], [Lower optimized operations to kernels], [Runtime],
    [Validate], [Compare latency, throughput, and accuracy], [QA],
)
