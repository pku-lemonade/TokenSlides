#import "/lemonade.typ": *

#set text(lang: "en")

#show: lemonade-theme.with(
  aspect-ratio: "16-9",
  title-align: "left",
  box-compact: true,
  footer: "bar",
  config-info(
    title: [Tokencake: A KV-Cache-centric Serving Framework for LLM-based Multi-Agent Applications],
    venue: [arXiv:2510.18586v2],
    author: [Zhuohang Bian et al.],
    institution: [Peking University],
    short-title: [Tokencake],
    date: [October 31, 2025],
  ),
)

#title-slide()

= Motivation

== Agentic Workloads Stress KV Cache

#ibox[
  *Workload:* multi-agent DAGs mix critical-path dependencies with long external tool stalls.
]

#hbox[
  *Tool latency:* Table 1 spans `100 ms` to `5-30 s`, so the idle window is large enough to schedule around.
]

#imgs(
  (image("assets/fig1a-multi-agent-coding.jpeg"), [Multi-agent coding]),
  (image("assets/fig1b-deep-research.jpeg"), [Deep research]),
  gap: 0.8em,
)

== Space Contention

#ibox[
  *Claim:* FCFS-style allocation lets non-critical agents occupy scarce KV-cache blocks before critical-path work arrives.
]

#hbox[
  *Consequence:* the evicted critical agent must rebuild its prefix, so one bad memory decision delays the whole workflow.
]

#imgs(
  (image("assets/fig2a-space-contention-analysis.jpeg"), [Critical inversion events are frequent]),
  (image("assets/fig2b-space-contention-diagram.jpeg"), [A non-critical agent preempts a critical one]),
  widths: (1.05fr, 0.95fr),
  gap: 0.8em,
)

== Time Underutilization

#ibox[
  *Claim:* function-call stalls leave useful KV cache idle on the GPU, even though active requests still need memory.
]

#hbox[
  *Peak waste:* Figure 3a shows stalled agents can occupy up to `18.5%` of the used GPU KV cache.
]

#imgs(
  (image("assets/fig3a-idle-kv-blocks.jpeg"), [Idle KV-cache blocks over time]),
  (image("assets/fig3b-kv-cache-lifecycle.jpeg"), [Inference1 -> function call -> Inference2 lifecycle]),
  widths: (1.05fr, 0.95fr),
  gap: 0.8em,
)

== Why Existing Systems Miss It

#ibox[
  *Gap:* prior systems optimize either application scheduling or KV-cache management, but not both together.
]

#table(
  columns: (1fr, 1.2fr, 1.15fr, 1.45fr),
  inset: 8pt,
  align: (left, left, left, left),
  [*View*], [*Examples*], [*Optimizes*], [*Still misses*],
  [Agent-aware],
  [Parrot / Autellix / Teola],
  [DAG order, stage overlap],
  [No KV-cache control, so critical inversion remains.],

  [KV-cache-centric],
  [vLLM / Mooncake / CachedAttention / LMCache],
  [Fragmentation or offload],
  [No agent criticality or function-call trigger.],
)

= Design

== Tokencake Overview

#grid(
  columns: (0.82fr, 1.18fr),
  gutter: 0.8em,
  [
    #ibox[
      *Thesis:* multi-agent serving should manage KV cache across both time and space.
    ]

    #hbox[
      *Space Scheduler:* reserves blocks for critical agents under pressure.
    ]
  ],
  [
    #imgs(
      (image("assets/fig4-overview.jpeg"), [Frontend API + space scheduler + time scheduler]),
    )
  ],
)

== Expose Agent Context to the Runtime

#ibox[
  *Key move:* Tokencake does not treat a tool-using request as a black box; the API exports structure the runtime can optimize.
]

#hbox[
  *What the runtime learns:* DAG dependencies, internal function-call stages, and `predict_time` for cold-start forecasts.
]

#imgs(
  (image("assets/fig5-api.jpeg"), [API graph + staged `FuncNode`]),
  (image("assets/fig6-coordination.jpeg"), [Space/time schedulers share one memory pool]),
  width: 94%,
  widths: (1.25fr, 0.95fr),
  gap: 0.8em,
)

== Function-Call-Aware Time Scheduler

#grid(
  columns: (0.92fr, 1.08fr),
  gutter: 0.8em,
  [
    #ibox[
      *Runtime:* `call_start` and `call_finish` turn a tool stall into an explicit scheduling window.
    ]

    #hbox[
      *Decision:* offload only when the predicted stall is longer than transfer cost; forecast resume time with $t_"final" = alpha dot t_"req" + (1 - alpha) dot t_"hist"$.
    ]
  ],
  [
    #imgs(
      (image("assets/fig7-lifecycle.jpeg"), [Offload at call start, prefetch before predicted resume]),
    )
  ],
)

== Dynamic Memory Partitioning

#grid(
  columns: (0.92fr, 1.08fr),
  gutter: 0.8em,
  [
    #ibox[
      *Priority:* static DAG importance is combined with dynamic wait-time urgency to select protected agent types.
    ]

    #hbox[
      *Control loop:* a shared pool serves everyone, while the reserved pool expands under high GPU pressure.
    ]
  ],
  [
    #imgs(
      (image("assets/fig8-space-scheduler.jpeg"), [Hybrid priority drives adaptive memory reservation]),
    )
  ],
)

= Evaluation

== Experimental Setup

#grid(
  columns: (1fr, 1fr),
  gutter: 0.8em,
  [
    #ibox[
      *Stress test:* two representative agentic apps, two Qwen sizes, and mainstream baselines.
    ]

    #hbox[
      *Platform:* Qwen2.5-14B on A100 `80GB`, Qwen2.5-32B on H200 `140GB`, plus `100GB` CPU swap.
    ]
  ],
  [
    #nbox[
      *Benchmarks:* Code-Writer stresses concurrent agents; Deep Research stresses dependency-heavy workflows.
    ]

    #sbox[
      *Load:* request arrivals follow a Poisson process over application QPS; tool latencies are also Poisson-simulated.
    ]

    #ibox[
      *Baselines / metrics:* vLLM and LightLLM; end-to-end latency, GPU KV usage, and abnormal agent count.
    ]
  ],
)

== Latency Improves Under Load

#ibox[
  *Main result:* Tokencake pulls away as memory pressure rises, which matches the paper's contention thesis.
]

#hbox[
  *Anchor number:* at `1.0 QPS`, average end-to-end latency falls by over `47.06%` versus vLLM.
]

#imgs(
  (image("assets/fig9-latency.jpeg"), [Latency versus application QPS across two workloads and two model sizes]),
)

== GPU Memory Stays Productive

#ibox[
  *Why latency drops:* Tokencake moves stalled KV cache off the GPU, so occupied memory is mostly attached to computation-ready work.
]

#hbox[
  *Utilization:* Tokencake stays around `85.7%` to `87.0%` GPU KV-cache usage, up to `16.9%` higher than vLLM.
]

#imgs(
  (image("assets/fig10-gpu-utilization.jpeg"), [Higher effective GPU KV-cache usage across load levels]),
)

== Critical-Path Agents Stop Stalling

#ibox[
  *Stability result:* agent-aware reservations cut the long-tail stalls that dominate workflow completion time.
]

#hbox[
  *File Write example:* abnormal agents drop from `90` to `27` versus both baselines.
]

#imgs(
  (image("assets/fig12-abnormal-agents.jpeg"), [Fewer latency outliers for tool-heavy agents]),
)

== Reuse Beats Recompute

#ibox[
  *Tradeoff:* if a tool stall is long enough, moving KV cache is far cheaper than rebuilding the prefix later.
]

#hbox[
  *4096 blocks:* transfer is about `60 ms` total (`32 ms` offload, `29 ms` upload), while recomputation is about `8943 ms`.
]

#imgs(
  (image("assets/fig13-offload-vs-recompute.jpeg"), [Transfer cost stays far below recomputation cost]),
)

== Offload Overhead Needs Mitigation

#ibox[
  *Second tradeoff:* proactive offload only works if the runtime removes the bursty allocation overhead it creates.
]

#hbox[
  *5120 blocks:* baseline upload reaches `15163 ms`, while the optimized path keeps it at `4.4 ms`.
]

#imgs(
  (
    image("assets/fig14-overhead-mitigation.jpeg"),
    [CPU buffering and gradual reservation keep transfer latency in single-digit milliseconds],
  ),
)

== What Matters in Tokencake

#grid(
  columns: (1fr, 1fr),
  gutter: 0.8em,
  [
    #ibox[
      *Systems thesis:* multi-agent serving fails because the KV cache is both space-contended and time-underutilized.
    ]

    #hbox[
      *Design thesis:* the runtime needs both function-call-aware offload and criticality-aware reservation.
    ]
  ],
  [
    #sbox[
      *Evidence:* lower latency, higher utilization, and fewer abnormal agents all point to the same mechanism: more productive GPU memory.
    ]

    #nbox[
      *Limits:* current results depend on simple time prediction and single-GPU evaluation, so distributed extension is the obvious next step.
    ]
  ],
)

#thank-you-slide(
  title: [Questions?],
)[
  #place-image(
    assets.qr-code,
    caption: "pku-lemonade",
    width: 20%,
    position: bottom + right,
    dx: 0em,
    dy: 1em,
  )
]
