#import "/lemonade.typ": *

#set text(lang: "en")

#show: lemonade-theme.with(
  aspect-ratio: "16-9",
  title-align: "left",
  box-compact: true,
  footer: "bar",
  config-info(
    title: [Tokencake],
    venue: [arXiv preprint (v2)],
    author: [Zhuohang Bian, Feiyang Wu, Teng Ma, Youwei Zhuo],
    institution: [Peking University],
    short-title: [Tokencake],
    date: [October 31, 2025],
  ),
)

#title-slide()

= Motivation

== Workload Shift

#hbox[
  *Workloads:* Code-Writer stresses many specialized agents and frequent file or tool calls; Deep Research uses fewer agents but a tighter dependency chain.
]

#nbox[
  *Systems implication:* Some agents sit on the critical path while others wait on external tools, so naive KV-cache placement wastes scarce GPU memory.
]

#imgs(
  image("assets/tokencake-fig01-workloads.pdf"),
  width: 98%,
)

// Render mode: script
// Claim ids: C1
// Evidence: asset:tokencake-fig01-workloads (Code-Writer and Deep Research); text:source:47-50;481-490 (Representative multi-agent workloads combine frequent tool calls with internal agent dependencies.); assets=tokencake-fig01-workloads
// QA: Figure 1 stays readable at large scale., Both support boxes stay to two short lines.

== Two Cache Failures

#hbox[
  *Space:* Critical inversion forces recomputation when a non-critical agent occupies scarce GPU blocks first.
]

#nbox[
  *Time:* Tool stalls leave the first inference prefix idle on GPU; peaks reach 18.5% of used KV cache.
]

#imgs(
  image("assets/tokencake-fig02-space-contention.pdf"),
  image("assets/tokencake-fig03-time-underutilization.pdf"),
  width: 96%,
  gap: 0.8em,
)

// Render mode: script
// Claim ids: C1
// Evidence: asset:tokencake-fig02-space-contention; asset:tokencake-fig03-time-underutilization; text:source:146-148 (Stalled agents can occupy 18.5% of used KV cache at peak.); assets=tokencake-fig02-space-contention, tokencake-fig03-time-underutilization
// QA: Both composite figures remain legible side by side., The support text does not push the figures into thumbnail size.

= Design

== Tokencake Thesis

#grid(
  columns: (0.92fr, 1.08fr),
  gutter: 0.8em,
  [
    #hbox[
      *Core idea:* Tokencake couples graph-aware metadata with two policies: proactive offload and prefetch around tool stalls, and critical-agent reservation under memory pressure.
    ]

  ],
  [
    #imgs(
      (image("assets/tokencake-fig04-overview.jpeg"), [Tokencake Overview]),
      width: 100%,
    )

  ],
)

// Render mode: script
// Claim ids: C2
// Evidence: asset:tokencake-fig04-overview; text:source:155-157;184-190 (One graph feeds both schedulers, and coordination keeps their policies consistent.); assets=tokencake-fig04-overview
// QA: The overview figure stays readable in the side column., Left-column boxes remain terse.

== Time Scheduler

#hbox[
  *Trigger:* Tokencake uses function-call events rather than generic inactivity heuristics, so the offload window is explicit.
]

#nbox[
  *Mechanism:* Static graph analysis gives cold-start estimates, runtime feedback refines them, and predictive upload hides transfer latency before the agent resumes.
]

#imgs(
  (image("assets/tokencake-fig07-time-lifecycle.jpeg"), [Time Scheduler Lifecycle]),
  width: 98%,
)

// Render mode: script
// Claim ids: C3
// Evidence: asset:tokencake-fig07-time-lifecycle; text:source:239-271 (Tokencake is proactive and event-driven, unlike reactive offload policies.); assets=tokencake-fig07-time-lifecycle
// QA: The lifecycle figure stays readable at near-full width.

== Space Scheduler

#hbox[
  *Priority:* Critical agents are chosen by hybrid priority, combining DAG structure with runtime importance.
]

#nbox[
  *Reservation:* The reserved pool grows with memory pressure and is divided across critical agents by score and historical memory demand. The configurable critical_ratio controls how many agent types receive protection.
]

#imgs(
  (image("assets/tokencake-fig08-space-feedback.jpeg"), [Dynamic Memory Partitioning]),
  width: 98%,
)

// Render mode: script
// Claim ids: C4
// Evidence: asset:tokencake-fig08-space-feedback; text:source:346-367;391-392 (Priority and pressure jointly control the reserved pool.); assets=tokencake-fig08-space-feedback
// QA: Figure 8 remains legible without shrinking the support text.

= Evaluation

== Evaluation Setup

#hbox[
  *Workloads:* Code-Writer stresses concurrency and tool use; Deep Research stresses dependency depth and inter-agent coordination.
]

#nbox[
  *Baselines:* vLLM is the main baseline, while LightLLM shows Tokencake still wins against another optimized serving stack.
]

#sbox[
  *Metrics:* The paper reports end-to-end latency, GPU KV utilization, abnormal agents, and offload microbenchmarks. Request arrivals follow a Poisson process across increasing QPS.
]

// Render mode: script
// Claim ids: C5
// Evidence: text:source:468-490 (Code-Writer and Deep Research stress different multi-agent pathologies.); text:source:470-471;481-483 (Baselines do not include Tokencake's proactive offload or predictive upload.)
// QA: The slide stays compact without needing an extra workload figure.

== Loaded-System Gains

#hbox[
  *Main result:* At 1.0 QPS, Tokencake cuts end-to-end latency by over 47.06% versus vLLM, and the gap widens as memory pressure rises.
]

#nbox[
  *Interpretation:* The benefit is modest when the system is not memory-bound, but it grows once tool stalls and agent interference start to constrain batch size.
]

#imgs(
  (image("assets/tokencake-fig09-latency.jpeg"), [End-to-End Latency]),
  width: 98%,
)

// Render mode: script
// Claim ids: C5
// Evidence: asset:tokencake-fig09-latency; text:source:516-517 (At 1.0 QPS, Tokencake reduces end-to-end latency by over 47.06% versus vLLM.); assets=tokencake-fig09-latency
// QA: The multi-panel latency figure stays readable at full width.

== Utilization and Stability

#grid(
  columns: (1fr, 1fr),
  gutter: 0.8em,
  [
    #hbox[
      *Memory efficiency:* Tokencake keeps GPU KV utilization at 86-87%, up to 16.9% above vLLM, because idle caches leave the GPU.
    ]

    #nbox[
      *Critical path:* Abnormal agents above 1.5x the type-average latency drop sharply, which signals fewer contention-induced stalls.
    ]

  ],
  [
    #imgs(
      image("assets/tokencake-fig10-utilization.jpeg"),
      image("assets/tokencake-fig12-abnormal-agents.jpeg"),
      dir: ttb,
      width: 100%,
      gap: 0.6em,
    )

  ],
)

// Render mode: script
// Claim ids: C5
// Evidence: asset:tokencake-fig10-utilization; asset:tokencake-fig12-abnormal-agents; text:source:536-537;572-576 (Utilization reaches 86-87%, up to 16.9% above vLLM, while abnormal agents are those above 1.5x the type average.); assets=tokencake-fig10-utilization, tokencake-fig12-abnormal-agents
// QA: Both evaluation plots remain readable when stacked.

== Offload Beats Recompute

#grid(
  columns: (1fr, 1fr),
  gutter: 0.8em,
  [
    #hbox[
      *Transfer versus recompute:* For 4096 blocks, transfer takes about 60 ms while recomputation takes nearly 9,000 ms, so reuse is decisively cheaper.
    ]

    #nbox[
      *System cost:* Tokencake cuts 5120-block upload latency from 15,163 ms to 4.4 ms, making proactive offload operationally viable.
    ]

  ],
  [
    #imgs(
      image("assets/tokencake-fig13-offload-tradeoff.jpeg"),
      image("assets/tokencake-fig14-overhead-mitigation.jpeg"),
      dir: ttb,
      width: 100%,
      gap: 0.6em,
    )

  ],
)

// Render mode: script
// Claim ids: C6
// Evidence: asset:tokencake-fig13-offload-tradeoff; asset:tokencake-fig14-overhead-mitigation; text:source:575-576;610-612;638-640 (4096 blocks transfer in about 60 ms versus nearly 9,000 ms recomputation; 5120-block upload drops from 15,163 ms to 4.4 ms.); assets=tokencake-fig13-offload-tradeoff, tokencake-fig14-overhead-mitigation
// QA: The two tradeoff plots stay readable when stacked.

= Takeaways

== What This Paper Establishes

#hbox[
  *Main lesson:* The paper is strongest when it treats KV cache as a first-class shared resource across both time and space.
]

#sbox[
  *Why it convinces:* The mechanism slides connect cleanly to workload-level latency gains, higher utilization, and fewer critical-path outliers.
]

#nbox[
  *Limits:* The predictor is simple and the evaluation is single-GPU, so multi-GPU coordination and richer forecasts remain open problems.
]

// Render mode: script
// Claim ids: C2
// Evidence: asset:tokencake-fig09-latency; asset:tokencake-fig12-abnormal-agents; asset:tokencake-fig14-overhead-mitigation
// QA: The final slide reads as a judgment, not a section-by-section recap.
