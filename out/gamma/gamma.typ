#import "/lemonade.typ": *

#set text(lang: "en")

#let asset(name) = "/out/gamma/assets/" + name

#show: lemonade-theme.with(
  aspect-ratio: "16-9",
  title-align: "left",
  box-compact: true,
  imgs-config: (
    cap-size: 15pt,
    cap-weight: "bold",
    fill-height: false,
  ),
  config-info(
    title: [GAMMA],
    venue: [ICCAD '20],
    author: [Sheng-Chun Kao and Tushar Krishna],
    institution: [Georgia Institute of Technology],
    short-title: [GAMMA],
    date: [November 2020],
  ),
)

#title-slide()

= Motivation

== What Mapping Controls

#ibox[
  *Mapping:* one schedule jointly chooses parallelism, computation order, and tile sizes.
]

#hbox[
  *Consequence:* those choices set reuse and memory traffic, so no fixed dataflow stays efficient across early, middle, and late CNN layers.
]

#imgs(
  (asset("gamma-fig01-overview.pdf"), [CONV dimensions, hierarchical mapper, and physical mapping]),
  width: 94%,
  fill-height: true,
)

== The Search Space Is the Barrier

#ibox[
  *Motivation:* even one VGG16 layer spans orders of magnitude in latency and energy under different valid mappings.
]

#hbox[
  *Scale:* layer 2 is already `O(10^12)` at one level and `O(10^36)` at three levels, so brute force and random search are poor fits.
]

#imgs(
  (asset("gamma-fig02-dse-performance.pdf"), [`10K` random mappings for one VGG16 layer cover radically different hardware outcomes]),
  width: 92%,
  fill-height: true,
)

= Design

== GAMMA Thesis

#grid(
  columns: (1fr, 1fr),
  gutter: 0.8em,
  [
    #ibox[
      *Core claim:* search the complete map space instead of fixing the number of parallel levels in advance.
    ]

    #hbox[
      *Representation:* the genome carries parallel dimension, compute order, and tile sizes in one object.
    ]
  ],
  [
    #sbox[
      *Operators:* `reorder`, `growth`, and `aging` let the search move across variable-depth mappings without a separate learned encoder.
    ]

    #nbox[
      *Evaluation loop:* `MAESTRO` scores each generation, while invalid mappings receive negative-infinity fitness.
    ]
  ],
)

== Encoding the Full Map Space

#ibox[
  *Genome:* a 1-level mapper is encoded as `7` gene pairs; multi-level mappings concatenate mapper levels.
]

#hbox[
  *Decode:* each level becomes one `Cluster` in `MAESTRO`, with the first gene pair as `SpatialMap` and the rest as `TemporalMap`.
]

#imgs(
  (asset("gamma-fig03-encoding.pdf"), [Flexible genome for 1-level and 2-level mappers]),
  (asset("gamma-fig04-decoded-mapper.pdf"), [Decoded mapping in `MAESTRO` form]),
  width: 100%,
  widths: (0.88fr, 1.12fr),
  gap: 0.8em,
  fill-height: true,
)

== Why Fixed-Length Baselines Break

#ibox[
  *Baseline limit:* most generic optimizers assume fixed-length inputs, which freezes the number of parallel levels.
]

#hbox[
  *Consequence:* once mapping depth is fixed in advance, richer accelerators need separately hand-built search spaces instead of one flexible search loop.
]

== Variable-Depth Operators

#ibox[
  *GAMMA move:* `reorder` changes loop order, while `growth` and `aging` add or remove a mapper level.
]

#hbox[
  *Result:* one search loop can span `S1` to `S3` instead of hand-building a different optimizer input for each depth.
]

#imgs(
  (asset("gamma-fig05-ga-workflow.pdf"), [Workflow plus operator summary for GAMMA]),
  width: 98%,
  fill-height: true,
)

= Evaluation

== Experimental Setup

#grid(
  columns: (0.9fr, 1.1fr),
  gutter: 0.8em,
  [
    #ibox[
      *Coverage:* `5` CNNs, `2` hardware budgets, `3` accelerator organizations, and latency or energy objectives.
    ]

    #hbox[
      *Models:* `VGG16`, `MobileNet-V2`, `ResNet-18`, `ResNet-50`, and `MnasNet`.
    ]

    #nbox[
      *Question:* does one search loop stay effective as the accelerator moves from fixed `S1` to flexible `S3`?
    ]
  ],
  [
    #imgs(
      (asset("gamma-table02-hw-resources.pdf"), [Edge and Cloud hardware budgets]),
      width: 100%,
      fill-height: false,
    )
    #v(0.5em)
    #imgs(
      (asset("gamma-table03-target-systems.pdf"), [Target systems `S1`, `S2`, and `S3`]),
      width: 100%,
      fill-height: false,
    )
  ],
)

== Baselines and Search Budget

#grid(
  columns: (1fr, 1fr),
  gutter: 0.8em,
  [
    #ibox[
      *Generic optimizers:* `RS`, `GA`, `DE`, `(1+lambda)-ES`, `CMA-ES`, `TBPSA`, `PSO`, and `pPortfolio`.
    ]

    #hbox[
      *Fixed dataflows:* `NVDLA`-, `Eyeriss`-, and `ShiDianNao`-like mappings test whether GAMMA only beats weak baselines.
    ]
  ],
  [
    #nbox[
      *Budget:* every method gets `10K` samples; GAMMA uses population `200`, `50` generations, and `0.5` evolution rates.
    ]

    #sbox[
      *Validity pressure:* mappings that exceed `SL` or `SG` are invalid, so some baselines fail before they become competitive.
    ]
  ],
)

== GAMMA Wins on the Hard Cases

#ibox[
  *Main result:* GAMMA both finds valid mappings and beats generic optimizers when constraints are tight or the map space becomes more flexible.
]

#hbox[
  *Anchor numbers:* `S1` Edge `224x-440x`, `S2` Edge `209x-1,035x`, `S2` Edge energy `11x-36x`, and `S3` Edge `241x-644x` better than alternatives.
]

#imgs(
  (asset("gamma-fig06-optimization-suite.pdf"), [Optimization results across `S1`, `S2`, and `S3` on Edge and Cloud]),
  width: 100%,
  fill-height: true,
)

== The Learned Mappings Match Layer Shape

#ibox[
  *Interpretability:* GAMMA does not discover arbitrary schedules; it shifts parallelism with the layer shape.
]

#hbox[
  *Pattern:* early layers favor `Y/X`, the middle layer uses a `Y/K/C` three-level mapping, and late layers move toward `C/K`.
]

#imgs(
  (asset("gamma-fig07-found-mappings.pdf"), [Found mappings for early, medium, and late ResNet-18 layers]),
  width: 86%,
  fill-height: true,
)

== End-to-End Wins Persist

#ibox[
  *Cross-model result:* on `S3`, GAMMA stays ahead after moving from layerwise search to end-to-end DNN pipelines.
]

#hbox[
  *Latency edge:* versus the best fixed mapping, GAMMA is `7.5x` faster on MobileNet-V2 and ShuffleNet, `10.2x` on MnasNet, and `20.2x` on ResNet50.
]

#table(
  columns: (1.3fr, 0.8fr, 0.8fr, 0.8fr, 0.8fr),
  inset: 8pt,
  align: (left, left, left, left, left),
  [*Model*], [*Edge lat.*], [*Cloud lat.*], [*Edge en.*], [*Cloud en.*],
  [MobileNet-V2], [`7.5x`], [`5.0x`], [`6.3x`], [`2.0x`],
  [MnasNet], [`10.2x`], [`29.0x`], [`7.4x`], [`2.1x`],
  [ShuffleNet], [`7.5x`], [`18.4x`], [`9.6x`], [`2.2x`],
  [ResNet50], [`20.2x`], [`75.8x`], [`29.7x`], [`1.9x`],
)

== Convergence Is Fast

#ibox[
  *Sample efficiency:* most of the latency drop arrives in the first `20` generations, well before the full `10K`-sample budget is exhausted.
]

#hbox[
  *Examples:* the search settles at `9.67E+05` cycles on MobileNet-V2 and `8.31E+05` on MnasNet under `S3` Edge.
]

#imgs(
  (asset("gamma-fig09-mobilenet.jpeg"), [MobileNet-V2]),
  (asset("gamma-fig09-mnasnet.jpeg"), [MnasNet]),
  width: 100%,
  gap: 0.8em,
  fill-height: true,
)

== Pipeline Slack Can Be Reinvested

#ibox[
  *Extension:* a second GAMMA pass preserves the bottleneck latency while relaxing non-critical layers for lower power or energy.
]

#table(
  columns: (1.05fr, 1fr, 1fr),
  inset: 8pt,
  align: (left, left, left),
  [*System*], [*Latency-Power*], [*Latency-Energy*],
  [ResNet-18], [`95%` lower power at the same pipeline latency], [`58%` lower energy at the same pipeline latency],
  [VGG16], [`99%` lower power], [`78%` lower energy],
  [Bottleneck note], [Layer `2` sets the ResNet-18 pipeline latency], [Stage 2 keeps other layers below that latency],
)

#sbox[
  *Takeaway:* once the bottleneck is fixed, the remaining throughput slack can be converted into system-level efficiency.
]

= Takeaways

== What This Paper Establishes

#grid(
  columns: (1fr, 1fr),
  gutter: 0.8em,
  [
    #ibox[
      *Systems thesis:* mapping is a first-order accelerator design variable, not a minor compile-time knob.
    ]

    #hbox[
      *Method thesis:* the crucial contribution is the flexible representation and operator set that make full-space search feasible.
    ]
  ],
  [
    #sbox[
      *Evidence:* the biggest gains appear exactly where generic baselines fail, namely under tight constraints and richer mapping flexibility.
    ]

    #nbox[
      *Limits:* the evidence is cost-model-driven and centered on CNN-style accelerators, so broader hardware and workload validation remains open.
    ]
  ],
)
