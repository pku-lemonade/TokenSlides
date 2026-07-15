#import "/lemonade.typ": *

#set text(lang: "en")

#show: lemonade-theme.with(
    aspect-ratio: "16-9",
    title-align: "left",
    box-compact: true,
    footer: "bar",
    artifact-badges: ("available", "functional", "reproduced"),
    config-info(
        title: [Graph.hls: A Compiler Framework for Composable Graph Accelerator Design],
        venue: [ISCA 2026],
        author: [*Feiyang Wu*, Xuxiao Yang, Zhuohang Bian, Jing Wang, \ Ruifan Xu, Guangyu Sun, Yun Liang, Youwei Zhuo],
        institution: [Peking University],
        short-title: [Graph.hls],
        date: [June 29, 2026],
    ),
)

// ============================================================
= Motivation
// ============================================================

== Why FPGA?

#grid(
    columns: (1fr, 1.2fr),
    gutter: 1.2em,
    align: horizon,
    [
        #align(center, image("assets/social-graph.png", width: 90%))
        #align(center, text(size: 16pt, fill: rgb("#444444"))[Social / web / knowledge graphs])
    ],
    [
        #set text(size: 24pt)
        #nbox[
            Graph workloads: irregular memory, low compute-to-data ratio, high bandwidth.
        ]

        #v(0.2em)

        #nbox[
            CPU/GPU: cache-unfriendly, memory-wall bottleneck.
        ]

        #v(0.2em)

        #hbox[
            *FPGA*: custom pipelines, on-chip memory (URAM), HBM --- fits graph access patterns.
        ]
    ],
)

== PageRank Example

$ "rank"(v) = 0.15 + 0.85 sum_(u -> v) "rank"(u) / "deg"(u) $

#imgs(image("assets/page3.png"), width: 45%)

== Challenge 1: Manual HLS


#imgs(
    (image("assets/page4.png"),),
    width: 100%,
)

== Challenge 2: Parameter Cascade

What if we want to optimize — e.g., reduce bit width 32→16?

#v(0.5em)

#hbox[
    #text(font: "Inconsolata", size: 28pt)[ap_uint\<32\>] → #text(font: "Inconsolata", size: 28pt)[ap_uint\<16\>]: *200+ line changes* across host, kernel, cache, and packing logic.
]

#imgs(
    (image("assets/fig03-parameter-cascade.svg"),),
    width: 95%,
)

== Challenge 3: Debugging Bottleneck

#text(fill: rgb("#444444"), size: 22pt)[→ After optimizing, we need to debug — but how?]

#v(0.5em)

#nbox[
    16-bit overflow at vertex 65540 → Vitis HW emulation hangs with a #text(font: "Inconsolata", size: 28pt)[deadlock]. No graph context.
]

#imgs(
    (image("assets/fig05-verification-slow.svg"),),
    width: 95%,
)

== Graph.hls Overview

#import "@preview/cetz:0.3.4"
#align(center, cetz.canvas(length: 1.6cm, {
    import cetz.draw: *

    let dkblue = rgb("#1B3A5C")
    let chal-fill = rgb("#E8F0F8")
    let sol-fill = rgb("#D6E4F0")

    let bw = 7.6
    let bh = 1.56
    let cx = 0
    let sx = 9.0

    let ys = (4.4, 2.2, 0.0)

    let chals = (
        ([*Challenge 1*], [Manual HLS]),
        ([*Challenge 2*], [Parameter cascade]),
        ([*Challenge 3*], [Debugging bottleneck]),
    )
    let sols = (
        ([*DSL*], [19 LoC replaces 4,818]),
        ([*GH-Architect*], [hierarchical abstraction + propagation]),
        ([*GH-Scope*], [sub-second IR simulation]),
    )

    for i in range(3) {
        let y = ys.at(i)
        rect(
            (cx - bw / 2, y - bh / 2),
            (cx + bw / 2, y + bh / 2),
            fill: chal-fill,
            stroke: black + 1.5pt,
        )
        content((cx, y + 0.22), text(size: 22pt, fill: rgb("#94070a"))[#chals.at(i).at(0)])
        content((cx, y - 0.22), text(size: 16pt)[#chals.at(i).at(1)])

        rect(
            (sx - bw / 2, y - bh / 2),
            (sx + bw / 2, y + bh / 2),
            fill: sol-fill,
            stroke: black + 1.5pt,
        )
        content((sx, y + 0.22), text(size: 20pt, fill: rgb("#94070a"), weight: "bold")[#sols.at(i).at(0)])
        content((sx, y - 0.22), text(size: 14pt)[#sols.at(i).at(1)])

        line(
            (cx + bw / 2 + 0.15, y),
            (sx - bw / 2 - 0.15, y),
            stroke: dkblue + 1.8pt,
            mark: (end: "stealth", fill: dkblue, scale: 1.0),
        )
    }

    // Dashed separator between C2 and C3
    line(
        (cx - bw / 2 - 0.3, (ys.at(1) + ys.at(2)) / 2),
        (sx + bw / 2 + 1.2, (ys.at(1) + ys.at(2)) / 2),
        stroke: (paint: rgb("#aaaaaa"), thickness: 1pt, dash: "dashed"),
    )
}))

// ============================================================
= Graph.hls DSL
// ============================================================

== PageRank in Graph.hls

#grid(
    columns: (1fr, 1fr),
    gutter: 1em,
    align: horizon,
    [
        #block(text(size: 9pt)[
            ```python
            Iteration {
              edges = iteration_input(G.EDGES)
              dst = map([edges], e: e.dst)
              val = map([edges], e: e.src.rank)
              sum = reduce(key=dst, val=[val],
                   fn=lambda x,y: x+y)
              rank = map([sum], r:
                   0.15+0.85*(r/self.out_deg))
              return rank as
                   result_node_prop.rank
            }
            ```
        ])
    ],
    [
        #image("assets/page9.png", width: 85%)
    ],
)

// ============================================================
= Hierarchical Abstraction
// ============================================================

== Background: Heterogeneous Pipelines

Recent works use heterogeneous pipelines for skewed graphs:
#v(0.3em)
#nbox[*Big pipeline:* supports more vertices, for sparse subgraphs.]
#v(0.2em)
#nbox[*Little pipeline:* high-throughput, for dense subgraphs.]
#v(0.2em)
#hbox[This design introduces multiple levels of concerns --- algorithm, data representation, and hardware mapping.]

== Why Three Levels?

These concerns naturally separate into three abstraction levels:

#import "@preview/cetz:0.3.4"
#align(center, cetz.canvas(length: 1.35cm, {
    import cetz.draw: *

    let dkblue = rgb("#1B3A5C")
    let dkgray = rgb("#444444")

    let rh = 2.4
    let gap = 0.12
    let base-w = 8.0
    let inset = 0.55

    let y0 = 0.0
    let y1 = y0 + rh + gap
    let y2 = y1 + rh + gap
    let total-h = y2 + rh

    let fills = (rgb("#E8F0F8"), rgb("#D0DFF0"), rgb("#B8CEE6"))

    let lbase-w = 8.8
    let rbase-w = 7.2
    let lx = -5.0
    let rx = 5.0

    // Left pyramid: Abstraction Level (wide bottom, narrow top)
    // Vertical outer edge on left, tapered inner edge on right
    let l-labels = ("L1: Algorithm", "L2: Data Repr.", "L3: HW Mapping")
    let l-params = ("VF_thrhd · ε · ratio", "bit width · edge repr.", "partition · SLR/HBM")

    for i in range(3) {
        let y = (y0, y1, y2).at(i)
        let br = lx + lbase-w / 2 - i * inset
        let tr = lx + lbase-w / 2 - (i + 1) * inset
        let bl = lx - lbase-w / 2
        let tl = lx - lbase-w / 2
        line((bl, y), (br, y), (tr, y + rh), (tl, y + rh), close: true, fill: fills.at(i), stroke: black + 1.8pt)
        let label-x = lx - lbase-w / 2 + 1.0
        content((label-x, y + rh / 2 + 0.45), anchor: "west", text(
            size: 26pt,
            weight: "bold",
            fill: dkblue,
        )[#l-labels.at(i)])
        content((label-x, y + rh / 2 - 0.45), anchor: "west", text(
            size: 18pt,
            fill: dkgray,
            font: "Inconsolata",
        )[#l-params.at(i)])
    }

    // Right pyramid: Modification Cost (narrow bottom, wide top)
    // Vertical outer edge on right, tapered inner edge on left
    let r-labels = ("1 LoC", "200+ LoC", "1000+ LoC")
    let r-params = ("define constants", "kernel functions", "program structure")

    for i in range(3) {
        let y = (y0, y1, y2).at(i)
        let bl = rx - rbase-w / 2 + (2 - i) * inset
        let tl = rx - rbase-w / 2 + (2 - i - 1) * inset
        let br = rx + rbase-w / 2
        let tr = rx + rbase-w / 2
        line((bl, y), (br, y), (tr, y + rh), (tl, y + rh), close: true, fill: fills.at(i), stroke: black + 1.8pt)
        let rlabel-x = rx + rbase-w / 2 - 1.0
        content((rlabel-x, y + rh / 2 + 0.45), anchor: "east", text(
            size: 26pt,
            weight: "bold",
            fill: dkblue,
        )[#r-labels.at(i)])
        content((rlabel-x, y + rh / 2 - 0.45), anchor: "east", text(size: 18pt, fill: dkgray)[#r-params.at(i)])
    }

    // Left axis
    let ax-l = lx - lbase-w / 2 - 0.7
    line((ax-l, y0 - 0.2), (ax-l, total-h + 0.2), stroke: dkblue + 2.2pt, mark: (
        end: "stealth",
        fill: dkblue,
        scale: 0.9,
    ))
    content((ax-l, total-h + 0.6), anchor: "south", text(size: 16pt, fill: dkblue)[High])
    content((ax-l, y0 - 0.6), anchor: "north", text(size: 16pt, fill: dkblue)[Low])
    content((ax-l - 1.0, total-h / 2), angle: 90deg, text(size: 17pt, weight: "bold", fill: dkblue)[Abstraction Level])

    // Right axis
    let ax-r = rx + rbase-w / 2 + 0.7
    line((ax-r, y0 - 0.2), (ax-r, total-h + 0.2), stroke: dkblue + 2.2pt, mark: (
        end: "stealth",
        fill: dkblue,
        scale: 0.9,
    ))
    content((ax-r, total-h + 0.6), anchor: "south", text(size: 16pt, fill: dkblue)[High])
    content((ax-r, y0 - 0.6), anchor: "north", text(size: 16pt, fill: dkblue)[Low])
    content((ax-r + 1.0, total-h / 2), angle: -90deg, text(size: 17pt, weight: "bold", fill: dkblue)[Modification Cost])

    // Connecting arrows (interpolate at midpoint of trapezoid edges)
    for i in range(3) {
        let y = (y0, y1, y2).at(i)
        let ly = y + rh / 2
        let lr-bot = lx + lbase-w / 2 - i * inset
        let lr-top = lx + lbase-w / 2 - (i + 1) * inset
        let lr = (lr-bot + lr-top) / 2
        let rl-bot = rx - rbase-w / 2 + (2 - i) * inset
        let rl-top = rx - rbase-w / 2 + (2 - i - 1) * inset
        let rl = (rl-bot + rl-top) / 2
        line((lr + 0.2, ly), (rl - 0.2, ly), stroke: dkblue + 2pt, mark: (end: "stealth", fill: dkblue, scale: 1.2))
    }
}))

== L1: Vertex Routing Threshold

#hbox[
    #text(font: "Inconsolata", size: 28pt)[L1: \{ VF_thrhd: 0.5 \}] --- higher-out-degree vertices go to little pipelines.
]

#imgs(
    (image("assets/page12.png"),),
    width: 95%,
)

== L2: Bit Width

#hbox[
    #text(font: "Inconsolata", size: 28pt)[Node: \{ rank: int\<16\> \}] --- halves memory per vertex property, doubles throughput.
]

#imgs(
    (image("assets/fig10-change-l2.svg"),),
    width: 95%,
)

== L3: Partition Strategy

#hbox[
    #text(font: "Inconsolata", size: 28pt)[pipe_partition: [\{big,2\},\{little,2\},\{little,2\}]]
]

#imgs(
    (image("assets/fig11-change-l3.svg"),),
    width: 95%,
)

// ============================================================
= GH-Architect
// ============================================================

== What is GH-Architect?

Compiler backend: DSL + config → synthesizable accelerator.
#v(0.2em)
#nbox[*Input:* 19 LoC DSL + L1/L2/L3 config.]
#v(0.2em)
#nbox[*Output:* full Vitis HLS project (\~5,000 LoC).]
#v(0.2em)
#nbox[*Key idea:* model parameters as a graph, auto-propagate constraints.]
#v(0.2em)
#hbox[Three steps: enumerate → propagate → generate.]

#{
    import "@preview/cetz:0.3.4": canvas, draw
    let dkblue = rgb("#1B3A5C")
    let ltblue = rgb("#D6E4F0")
    let dkgray = rgb("#444444")
    let dkred = rgb("#94070a")
    let elim-bg = rgb("#E0E0E0")
    let elim-fg = rgb("#999999")

    let bw = 1.5
    let bh = 0.5
    let gap-x = 0.6
    let row-gap = 1.4
    let x1 = 1.2
    let x2 = x1 + bw + gap-x
    let x3 = x2 + bw + gap-x

    let draw-label(y, label) = {
        draw.content((-0.4, y), text(font: "Inter", weight: "bold", size: 26pt, fill: dkblue)[#label])
    }

    let draw-box(x, y, label, style: "open") = {
        let (bg, fg, sw, bdr) = if style == "open" {
            (ltblue, dkblue, 0.8pt, dkblue)
        } else if style == "chosen" {
            (dkblue, white, 0.8pt, dkblue)
        } else {
            (elim-bg, elim-fg, 0.6pt, rgb("#CCCCCC"))
        }
        draw.rect((x - bw / 2, y - bh), (x + bw / 2, y + bh), stroke: bdr + sw, fill: bg)
        draw.content((x, y), text(font: "Inter", size: 22pt, fill: fg, weight: if style == "chosen" { "bold" } else {
            "regular"
        })[#label])
        if style == "dead" {
            draw.line((x - bw / 2, y - bh), (x + bw / 2, y + bh), stroke: dkred + 1.2pt)
        }
    }

    let draw-ors(y, style: "normal") = {
        let fg = if style == "faded" { rgb("#CCCCCC") } else { dkgray }
        draw.content((x1 + bw / 2 + gap-x / 2, y), text(font: "Inter", size: 20pt, fill: fg)[or])
        draw.content((x2 + bw / 2 + gap-x / 2, y), text(font: "Inter", size: 20pt, fill: fg)[or])
    }

    [== Cross-Level Dependency

        Recall Challenge 2: changing one parameter can cascade across levels.

        Example: hub vertex with rank = 0.85, out-degree = 5000.

        #align(center, table(
            columns: (auto, 1fr, 1fr),
            inset: 16pt,
            align: center,
            stroke: rgb("#1B3A5C") + 0.8pt,
            [], [*rank*], [*per edge (÷ 5000)*],
            [*32-bit*],
            table.cell(fill: rgb("#E8F5E8"))[#text(fill: rgb("#2D6A2D"))[0.850]],
            table.cell(fill: rgb("#E8F5E8"))[#text(fill: rgb("#2D6A2D"))[0.000170]],
            [*16-bit*],
            table.cell(fill: rgb("#E8F5E8"))[#text(fill: rgb("#2D6A2D"))[0.850]],
            table.cell(fill: rgb("#FEE8E8"))[#text(fill: rgb("#94070a"), weight: "bold")[0.000]],
        ))

        #hbox[Hub contributions vanish in 16-bit (L2) → wrong ranks → convergence (L1) breaks. Need automatic constraint propagation.]
    ]

    [== Dependency Propagation

        Propagate user choices through the parameter graph to resolve all cross-level constraints:
    ]

    v(1.2em)

    let sc = 1.8cm
    let sbw = 1.1
    let sbh = 0.38
    let sgap = 0.45
    let srow = 1.1
    let sx1 = 0.9
    let sx2 = sx1 + sbw + sgap
    let sx3 = sx2 + sbw + sgap

    let sdraw-label(y, label) = {
        draw.content((-0.3, y), text(font: "Inter", weight: "bold", size: 16pt, fill: dkblue)[#label])
    }

    let sdraw-box(x, y, label, style: "open") = {
        let (bg, fg, sw, bdr) = if style == "open" {
            (ltblue, dkblue, 0.6pt, dkblue)
        } else if style == "chosen" {
            (dkblue, white, 0.6pt, dkblue)
        } else {
            (elim-bg, elim-fg, 0.5pt, rgb("#CCCCCC"))
        }
        draw.rect((x - sbw / 2, y - sbh), (x + sbw / 2, y + sbh), stroke: bdr + sw, fill: bg)
        draw.content((x, y), text(font: "Inter", size: 14pt, fill: fg, weight: if style == "chosen" { "bold" } else {
            "regular"
        })[#label])
        if style == "dead" {
            draw.line((x - sbw / 2, y - sbh), (x + sbw / 2, y + sbh), stroke: dkred + 0.8pt)
        }
    }

    let sdraw-ors(y, style: "normal") = {
        let fg = if style == "faded" { rgb("#CCCCCC") } else { dkgray }
        draw.content((sx1 + sbw / 2 + sgap / 2, y), text(font: "Inter", size: 13pt, fill: fg)[or])
        draw.content((sx2 + sbw / 2 + sgap / 2, y), text(font: "Inter", size: 13pt, fill: fg)[or])
    }

    grid(
        columns: (1fr, 1fr, 1fr),
        column-gutter: 0.3em,
        row-gutter: 0.6em,
        align(center, text(size: 18pt, weight: "bold", fill: dkblue)[1. Enumerate]),
        align(center, text(size: 18pt, weight: "bold", fill: dkblue)[2. Forward]),
        align(center, text(size: 18pt, weight: "bold", fill: dkred)[3. Backward]),
        // Step 1: Open Parameters
        align(center, canvas(length: sc, {
            for (i, row) in (("L3", "2-class", "3-class", "4-class"), ("L2", "8-bit", "16-bit", "32-bit")).enumerate() {
                let y = -i * srow
                sdraw-label(y, row.at(0))
                sdraw-box(sx1, y, row.at(1))
                sdraw-box(sx2, y, row.at(2))
                sdraw-box(sx3, y, row.at(3))
                sdraw-ors(y)
            }
            let y = -2 * srow
            sdraw-label(y, "L1")
            sdraw-box(sx1, y, $ epsilon = 10^(-3) $)
            sdraw-box(sx2, y, $ epsilon = 10^(-6) $)
            sdraw-box(sx3, y, $ epsilon = 10^(-9) $)
            sdraw-ors(y)
        })),
        // Step 2: Forward
        align(center, canvas(length: sc, {
            let y0 = 0.0
            sdraw-label(y0, "L3")
            sdraw-box(sx1, y0, "2-class", style: "chosen")
            sdraw-box(sx2, y0, "3-class", style: "dead")
            sdraw-box(sx3, y0, "4-class", style: "dead")
            sdraw-ors(y0, style: "faded")
            let y1 = -srow
            sdraw-label(y1, "L2")
            sdraw-box(sx1, y1, "8-bit")
            sdraw-box(sx2, y1, "16-bit")
            sdraw-box(sx3, y1, "32-bit")
            sdraw-ors(y1)
            let y2 = -2 * srow
            sdraw-label(y2, "L1")
            sdraw-box(sx1, y2, $ epsilon = 10^(-3) $)
            sdraw-box(sx2, y2, $ epsilon = 10^(-6) $)
            sdraw-box(sx3, y2, $ epsilon = 10^(-9) $)
            sdraw-ors(y2)
            draw.line((sx1, y0 - sbh - 0.03), (sx1, y1 + sbh + 0.03), stroke: dkblue + 0.6pt, mark: (
                end: ">",
                fill: dkblue,
            ))
            draw.content((sx1 + 0.7, (y0 - sbh + y1 + sbh) / 2), text(
                font: "Inter",
                size: 14pt,
                weight: "bold",
                fill: dkblue,
            )[fwd])
        })),
        // Step 3: Backward
        align(center, canvas(length: sc, {
            let y0 = 0.0
            sdraw-label(y0, "L3")
            sdraw-box(sx1, y0, "2-class", style: "chosen")
            sdraw-box(sx2, y0, "3-class", style: "dead")
            sdraw-box(sx3, y0, "4-class", style: "dead")
            sdraw-ors(y0, style: "faded")
            let y1 = -srow
            sdraw-label(y1, "L2")
            sdraw-box(sx1, y1, "8-bit", style: "dead")
            sdraw-box(sx2, y1, "16-bit", style: "dead")
            sdraw-box(sx3, y1, "32-bit", style: "chosen")
            sdraw-ors(y1, style: "faded")
            let y2 = -2 * srow
            sdraw-label(y2, "L1")
            sdraw-box(sx1, y2, $ epsilon = 10^(-3) $, style: "chosen")
            sdraw-box(sx2, y2, $ epsilon = 10^(-6) $, style: "dead")
            sdraw-box(sx3, y2, $ epsilon = 10^(-9) $, style: "dead")
            sdraw-ors(y2, style: "faded")
            draw.line((sx3, y1 - sbh - 0.03), (sx3, y2 + sbh + 0.03), stroke: dkred + 0.6pt, mark: (
                start: ">",
                fill: dkred,
            ))
            draw.content((sx3 - 0.7, (y1 - sbh + y2 + sbh) / 2), text(
                font: "Inter",
                size: 14pt,
                weight: "bold",
                fill: dkred,
            )[bwd])
        })),
    )

    v(0.8em)
    [#hbox[User picks L3 = 2-class → forward prunes L2/L1 options → backward forces L2 = 32-bit to preserve convergence.]]
}

== Code Generation

#hbox[*No manual code edit.* Lower each IR node to target-specific HLS with hardware specs.]

#import "@preview/cetz:0.3.4"
#align(center, cetz.canvas(length: 1.4cm, {
    import cetz.draw: *

    let dkblue = rgb("#1B3A5C")
    let dkgray = rgb("#444444")
    let ltblue = rgb("#E8F0F8")
    let ltblue2 = rgb("#D6E4F0")
    let ltblue3 = rgb("#F0F4F8")

    let bw = 5.2
    let bh = 8.2
    let arr-gap = 1.0
    let pad = 0.4
    let inner-h = 1.1

    // Input box (left)
    let ix = -7.0
    rect((ix - bw / 2, 0), (ix + bw / 2, bh), fill: ltblue, stroke: black + 1.8pt, radius: 0.15)
    content((ix, bh - 0.6), text(size: 24pt, weight: "bold", fill: dkblue)[Input])

    let dy = bh - 1.4
    rect((ix - bw / 2 + pad, dy - inner-h), (ix + bw / 2 - pad, dy), fill: white, stroke: black + 1pt, radius: 0.1)
    content((ix, dy - 0.35), text(size: 18pt, weight: "bold", fill: dkblue)[PageRank DSL])
    content((ix, dy - 0.75), text(size: 16pt, fill: dkgray)[19 LoC])

    let dy2 = dy - inner-h - 0.3
    rect(
        (ix - bw / 2 + pad, dy2 - inner-h * 1.8),
        (ix + bw / 2 - pad, dy2),
        fill: white,
        stroke: black + 1pt,
        radius: 0.1,
    )
    content((ix, dy2 - 0.35), text(size: 18pt, weight: "bold", fill: dkblue)[Resolved Config])
    content((ix, dy2 - 0.85), text(size: 15pt, fill: dkgray, font: "Inconsolata")[L3: 2-class])
    content((ix, dy2 - 1.25), text(size: 15pt, fill: dkgray, font: "Inconsolata")[L2: 32-bit])
    content((ix, dy2 - 1.65), text(size: 15pt, fill: dkgray, font: "Inconsolata")[L1: ε=10⁻³, VF=0.5])

    // Arrow 1
    line((ix + bw / 2 + 0.15, bh / 2), (ix + bw / 2 + arr-gap - 0.15, bh / 2), stroke: black + 2.5pt, mark: (
        end: "stealth",
        fill: black,
        scale: 1.2,
    ))

    // Compiler box (center)
    let cx = 0
    rect((cx - bw / 2, 0), (cx + bw / 2, bh), fill: ltblue2, stroke: black + 1.8pt, radius: 0.15)
    content((cx, bh - 0.6), text(size: 24pt, weight: "bold", fill: rgb("#94070a"))[Compiler])

    let cy1 = bh - 1.4
    rect((cx - bw / 2 + pad, cy1 - inner-h), (cx + bw / 2 - pad, cy1), fill: white, stroke: black + 1pt, radius: 0.1)
    content((cx, cy1 - inner-h / 2), text(size: 17pt, fill: dkblue)[Template selection])

    let cy2 = cy1 - inner-h - 0.6
    line((cx, cy1 - inner-h), (cx, cy2), stroke: black + 1.2pt, mark: (end: "stealth", fill: black, scale: 0.7))
    rect((cx - bw / 2 + pad, cy2 - inner-h), (cx + bw / 2 - pad, cy2), fill: white, stroke: black + 1pt, radius: 0.1)
    content((cx, cy2 - inner-h / 2), text(size: 17pt, fill: dkblue)[Param substitution])

    let cy3 = cy2 - inner-h - 0.6
    line((cx, cy2 - inner-h), (cx, cy3), stroke: black + 1.2pt, mark: (end: "stealth", fill: black, scale: 0.7))
    rect((cx - bw / 2 + pad, cy3 - inner-h), (cx + bw / 2 - pad, cy3), fill: white, stroke: black + 1pt, radius: 0.1)
    content((cx, cy3 - 0.35), text(size: 17pt, fill: dkblue)[HW spec injection])
    content((cx, cy3 - 0.75), text(size: 14pt, fill: dkgray)[SLR · HBM · buffers])

    // Arrow 2
    line((cx + bw / 2 + 0.15, bh / 2), (cx + bw / 2 + arr-gap - 0.15, bh / 2), stroke: black + 2.5pt, mark: (
        end: "stealth",
        fill: black,
        scale: 1.2,
    ))

    // Output box (right)
    let ox = 7.0
    rect((ox - bw / 2, 0), (ox + bw / 2, bh), fill: ltblue3, stroke: black + 1.8pt, radius: 0.15)
    content((ox, bh - 0.6), text(size: 24pt, weight: "bold", fill: dkblue)[Output])

    let oy1 = bh - 1.4
    rect((ox - bw / 2 + pad, oy1 - inner-h), (ox + bw / 2 - pad, oy1), fill: white, stroke: black + 1pt, radius: 0.1)
    content((ox, oy1 - inner-h / 2), text(size: 17pt, fill: dkblue)[Kernel sources])

    let oy2 = oy1 - inner-h - 0.3
    rect((ox - bw / 2 + pad, oy2 - inner-h), (ox + bw / 2 - pad, oy2), fill: white, stroke: black + 1pt, radius: 0.1)
    content((ox, oy2 - inner-h / 2), text(size: 17pt, fill: dkblue)[Host sources])

    let oy3 = oy2 - inner-h - 0.3
    rect((ox - bw / 2 + pad, oy3 - inner-h), (ox + bw / 2 - pad, oy3), fill: white, stroke: black + 1pt, radius: 0.1)
    content((ox, oy3 - inner-h / 2), text(size: 17pt, fill: dkblue)[Vitis config])

    let oy4 = oy3 - inner-h - 0.3
    rect((ox - bw / 2 + pad, oy4 - inner-h), (ox + bw / 2 - pad, oy4), fill: white, stroke: black + 1pt, radius: 0.1)
    content((ox, oy4 - inner-h / 2), text(size: 17pt, fill: dkblue)[Makefile])

    content((ox, 0.4), text(size: 18pt, weight: "bold", fill: rgb("#94070a"))[Ready to compile])
}))

// ============================================================
= GH-Scope
// ============================================================

== Why GH-Scope?

#grid(
    columns: (1fr, 1fr),
    gutter: 1.5em,
    align: horizon,
    [
        #text(size: 24pt, weight: "bold", fill: rgb("#94070a"))[Problem]

        #v(0.5em)

        #nbox[
            HW emulation detects bugs only *after lowering* to hardware-level traces.
        ]

        #v(0.3em)

        #nbox[
            Hours-long cycles. Failures often surface as deadlocks --- *no graph context*.
        ]
    ],
    [
        #text(size: 24pt, weight: "bold", fill: rgb("#2D6A2D"))[GH-Scope]

        #v(0.5em)

        #hbox[
            GH-Architect already produces a *graph-level IR* before code generation.
        ]

        #v(0.3em)

        #hbox[
            Simulate this IR directly --- catch bugs *earlier*, *faster*, with *vertex/edge context*.
        ]
    ],
)

== IR-Level Simulation

#hbox[
    Simulate at the IR level --- no RTL compilation needed. Sub-second execution, *455,000×* faster than hardware emulation.
]

#align(center, image("assets/page23.png", width: 80%))

== Full Pipeline

#imgs(
    (image("assets/page24.png"),),
    width: 95%,
)

// ============================================================
= Evaluation
// ============================================================

== Performance

#hbox[
    L1-only exploration: *2.6×* over ReGraph, *1.2×* over ThunderGP on 6 representative graphs.
]

#imgs(
    (image("assets/fig16-perf-combined-new.png"),),
    width: 98%,
)

== Composition Ablation

#hbox[
    Each level removes a _different_ bottleneck. Gains compound to *4.48×*.
]

#imgs(
    (image("assets/fig18-ablation-new.png"),),
    width: 85%,
)

== Debugging Speedup

#v(1fr)

#imgs(
    (image("assets/fig19-ghscope-speed.svg"),),
    width: 85%,
    fill-height: false,
)

#v(1fr)

== GH-Scope vs. C-Sim

#hbox[
    SOTA Verilog simulators claim $tilde 1 times$ speed with Vitis C-Sim. GH-Scope achieves *301×* over C-Sim.
]

#nbox[
    GH-Scope operates at the IR level --- no RTL compilation needed. Reports graph-level causes, not deadlock symptoms.
]

#hbox[
    Up to *455,000×* faster than hardware emulation across all error types.
]

// ============================================================
= Conclusion
// ============================================================

== Key Takeaways

- We propose *Graph.hls*, a compiler framework that raises graph accelerator design from hand-wired HLS to a composable DSL.

- *GH-Architect* propagates constraints across algorithm (L1), data representation (L2), and hardware mapping (L3) --- resolving cross-level dependencies automatically.

- *GH-Scope* catches graph-level bugs via IR simulation before expensive hardware emulation.

- *2.6×* over ReGraph · *1.2×* over ThunderGP · *4.48×* from composed L1+L2+L3 · up to *455,000×* faster debugging.

#thank-you-slide()
