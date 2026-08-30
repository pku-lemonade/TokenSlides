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
    // Grid style keeps the page fill under the header; "palette" restores the
    // palette's header colors on top of it.
    fills: (header-fill: "palette", header-text-fill: "palette"),
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

== Row spans inside a row

#vboxs(
    vstack(
        ibox[*Model*\ Calibrate and validate],
        ebox[*Compile*\ Generate and integrate],
        heights: (1fr, 1fr),
        fill-height: true,
    ),
    vtable(
        columns: (1fr, 1.8fr, 0.8fr),
        header: ([Track], [Milestone], [Year]),
        center-cols: (0, 2),
        first-column: true,
        row-stretch: "equal",
        table.cell(rowspan: 2, fill: rgb("#DCE7F5"), align: center + horizon)[Model],
        [Calibrate], [2027],
        [Validate], [2028],
        table.cell(rowspan: 2, fill: rgb("#F4E3E1"), align: center + horizon)[Compile],
        [Generate], [2029],
        [Integrate], [2030],
    ),
    widths: (0.28fr, 0.72fr),
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
