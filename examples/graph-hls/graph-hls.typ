#import "/lemonade.typ": *

#set text(lang: "en")

#show: lemonade-theme.with(
  aspect-ratio: "16-9",
  title-align: "left",
  box-compact: true,
  footer: "bar",
  imgs-config: (
    cap-size: 15pt,
  ),
  config-info(
    title: [Graph.hls: A Compiler Framework for Composable Graph Accelerator Design],
    venue: [ISCA 2026 confidential draft],
    author: [Anonymous authors],
    institution: [Paper reading deck],
    short-title: [Graph.hls],
    date: [April 2026],
  ),
)

#let asset(name) = image("assets/" + name + ".pdf")

#title-slide()

= Motivation

== Broken Workflow

#ibox[
  *Two failures:* prior graph-HLS frameworks cannot compose optimizations cleanly and still debug through slow hardware emulation.
]

#hbox[
  *Anchor numbers:* the paper reports `50+ min` emulation loops, while GH-Scope finishes validation in under `1 s`.
]

#imgs(
  (asset("fig1-workflow"), [Existing flows spend effort on integration and emulation, not exploration]),
)

== Integration Tax

#ibox[
  *Claim:* a nominal datatype tweak spills across constants, packing logic, kernels, and host transfers, so reuse across frameworks is structurally hard.
]

#hbox[
  *Concrete cost:* ReGraph needs `200+` edited lines across `10+` files for a `32-bit -> 16-bit` SSSP change.
]

#imgs(
  (asset("fig2-bitwidth-cascade"), [One bitwidth change fans out across the accelerator stack]),
)

= Design

== Compiler Thesis

#ibox[
  *Thesis:* Graph.hls separates the design space from the workflow that realizes it.
]

#hbox[
  *Structure:* a hierarchical abstraction feeds GH-Architect for code generation and GH-Scope for IR-level verification.
]

#imgs(
  (asset("fig3-overview"), [Abstraction, generation, and verification form one compiler workflow]),
)

== Cost-Tiered Abstraction

#grid(
  columns: (0.92fr, 1.08fr),
  gutter: 0.8em,
  [
    #ibox[
      *L1:* graph constants change execution behavior but not the pipeline structure.
    ]

    #hbox[
      *L2:* microarchitecture knobs such as property bitwidth and lane count propagate through the full accelerator.
    ]

    #nbox[
      *L3:* dataflow strategy changes rewrite both FPGA organization and host-side coordination.
    ]
  ],
  [
    #imgs(
      (asset("fig4-hierarchy"), [`L1` single-line, `L2` multi-file, `L3` redesign]),
    )
  ],
)

== DSL Frontend

#grid(
  columns: (0.95fr, 1.05fr),
  gutter: 0.8em,
  [
    #ibox[
      *Abstraction:* Graph.hls builds accelerators from `iteration_input`, `map`, `filter`, `reduce`, and `return`.
    ]

    #hbox[
      *Why beyond GAS:* Belief Propagation needs neighbor exclusion before reduction, which the paper argues GAS cannot express directly.
    ]
  ],
  [
    #imgs(
      (asset("fig5a-dsl"), [One DSL block binds schema, parameters, and one iteration]),
    )
  ],
)

== Constraint Propagation

#grid(
  columns: (1fr, 1fr),
  gutter: 0.8em,
  [
    #ibox[
      *L3 first:* GH-Architect chooses a pipeline grouping from graph statistics and hardware structure.
    ]

    #hbox[
      *Then L1/L2:* bidirectional dependency propagation keeps only configurations that are both hardware-feasible and algorithmically valid.
    ]

    #nbox[
      *Worked example:* on `U55C`, PageRank on `rmat-21-32` becomes `11` little + `3` big pipelines; `32-bit` stays because `16-bit` would round `~1e-3` contributions to zero.
    ]
  ],
  [
    #imgs(
      (asset("fig5b-level-examples"), [The hierarchy maps to partitioning, bitwidth, and pipeline changes]),
    )
  ],
)

== IR-Level Validation

#ibox[
  *Checks before synthesis:* GH-Scope validates types, cycle freedom, overflow, non-convergence risk, and golden-reference agreement at the Graph.hls IR level.
]

#hbox[
  *Why it matters:* the debug loop drops from emulation-scale minutes or hours to milliseconds.
]

#table(
  columns: (1.55fr, 1fr, 0.8fr, 0.8fr),
  inset: 8pt,
  align: (left, left, left, left),
  [*Error*], [*HLS emulation*], [*GH-Scope*], [*Speedup*],
  [Algorithm failure (6 iter.)], [`~6 hours`], [`0.04s`], [`~455,000x`],
  [Stream type mismatch], [`73m 40s`], [`0.02s`], [`~186,000x`],
  [Parameter mismatch], [`13m 13s`], [`0.02s`], [`~33,000x`],
)

= Evaluation

== Evaluation Setup

#grid(
  columns: (0.9fr, 1.1fr),
  gutter: 0.8em,
  [
    #ibox[
      *Hardware:* `U55C` is HBM-heavy (`460 GB/s`, `32` channels), while `U200` is DDR-based (`77 GB/s`, `4` channels).
    ]

    #hbox[
      *Coverage:* `6` algorithms on `14` graphs spanning synthetic, social, collaboration, and web workloads.
    ]

    #nbox[
      *Fairness:* the head-to-head comparisons fix `L2/L3` to the baseline configuration and search only over `L1`.
    ]
  ],
  [
    #sbox[
      *U55C / ReGraph:* HBM platform with `960` URAM, `460 GB/s`, and `32` channels.
    ]

    #nbox[
      *U200 / ThunderGP:* DDR platform with `960` URAM, `77 GB/s`, and `4` channels.
    ]

    #ibox[
      *Algorithm set:* `PR`, `SSSP`, `Weighted SSSP`, `CC`, `AR`, and `WCC`.
    ]
  ],
)

== HBM Baseline

#ibox[
  *Main result:* Graph.hls beats ReGraph by `2.6x` on average even when `L2/L3` are fixed to ReGraph's structure.
]

#hbox[
  *Where it wins most:* skewed graphs such as `R24`, `AM`, and `LJ` benefit from better partition-ratio tuning.
]

#imgs(
  (asset("fig6-vs-regraph"), [Only `L1` changes here, so the gain comes from better use of ReGraph's fixed structure]),
)

== DDR Baseline

#ibox[
  *Generalization:* the same L1-only exploration also matches or exceeds ThunderGP on the DDR-based `U200`.
]

#hbox[
  *Coverage:* the paper reports `1.2x` average speedup and `five` large-graph cases where ThunderGP runs out of memory.
]

#imgs(
  (asset("fig7-vs-thundergp"), [Graph.hls keeps pace while avoiding several ThunderGP out-of-memory cases]),
)

== Cross-Level Gains

#ibox[
  *Takeaway:* the hierarchy matters because each level removes a different bottleneck rather than repeating the same optimization.
]

#hbox[
  *Ablation:* Naive `0.71x`, `L1` `1.99x`, `L1+L2` `2.95x`, `L1+L3` `2.52x`, full `L1+L2+L3` `4.48x`.
]

#imgs(
  (asset("fig8-ablation"), [The full gain appears only when the three levels are tuned together]),
)

== Simulation Speed

#ibox[
  *Beyond debugging:* GH-Scope is also a practical large-graph simulator, not just a pre-synthesis checker.
]

#hbox[
  *Anchor number:* average speedup is `301.6x`; PageRank on `rmat-24-16` drops from `1779.06 s` to `8.29 s`.
]

#imgs(
  (asset("fig9-simulation-speedup"), [IR-level simulation consistently outpaces Vitis `C-Sim`]),
)

== Takeaways

#grid(
  columns: (1fr, 1fr),
  gutter: 0.8em,
  [
    #sbox[
      *What works:* the paper turns isolated accelerator tricks into a single compiler story with explicit abstraction boundaries.
    ]

    #ibox[
      *Why the results are credible:* Figures `6` to `9` connect the abstraction directly to both runtime and iteration-time wins.
    ]
  ],
  [
    #ebox[
      *Caveat:* the simulator comparison uses Vitis `C-Sim` as a proxy because the cited parallel simulator is not open-sourced.
    ]

    #nbox[
      *Missing detail:* the main paper says much less about synthesis overheads and generator costs than about runtime and debug speedups.
    ]
  ],
)

#thank-you-slide()
