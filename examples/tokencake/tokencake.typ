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
    author: [Zhuohang Bian, Feiyang Wu, Teng Ma, Youwei Zhuo],
    institution: [Peking University],
    short-title: [Tokencake],
    date: [October 31, 2025],
  ),
)

#title-slide()

= Motivation

== Agentic Workloads Stress KV Cache

#ibox[
  *Takeaway:* Multi-agent DAGs mix critical-path dependencies with long external tool stalls, so serving sees both heterogeneous agent importance and large idle windows.
]

#imgs(
  (image("assets/fig1a-multi-agent-coding.jpeg"), [Multi-agent Coding]),
  (image("assets/fig1b-deep-research.jpeg"), [Deep Research]),
  width: 96%,
  gap: 0.8em,
)

// Render mode: script
// Claim ids: c1
// Evidence: asset:fig1a-coding (Coding workflow example); asset:fig1b-deep-research (Research workflow example); text:table-1 (Tool latencies span 100 ms to 5-30 s with large variability); assets=fig1a-coding, fig1b-deep-research
// QA: Both workflow panels stay readable, Boxes stay to one line each

== Space Contention

#ibox[
  *Takeaway:* FCFS-style allocation lets non-critical agents occupy scarce KV-cache blocks before critical-path work arrives.
]

#imgs(
  (image("assets/fig2a-space-contention-analysis.jpeg"), [Contention Analysis]),
  (image("assets/fig2b-space-contention-diagram.jpeg"), [Critical Inversion Diagram]),
  width: 96%,
  gap: 0.8em,
)

// Render mode: script
// Claim ids: c1
// Evidence: asset:fig2a-space-contention-analysis (Preemption events accumulate over time); asset:fig2b-space-contention-diagram (Critical inversion cartoon); assets=fig2a-space-contention-analysis, fig2b-space-contention-diagram
// QA: Both panels remain readable, The consequence box stays concise

== Time Underutilization

#ibox[
  *Takeaway:* Function-call stalls leave useful KV cache idle on the GPU, even though active requests still need memory.
]

#imgs(
  (image("assets/fig3a-idle-kv-blocks.jpeg"), [Idle KV Blocks]),
  (image("assets/fig3b-kv-cache-lifecycle.jpeg"), [KV-Cache Lifecycle]),
  width: 96%,
  gap: 0.8em,
)

// Render mode: script
// Claim ids: c1
// Evidence: asset:fig3a-idle-kv-blocks (18.5% peak waste); asset:fig3b-kv-cache-lifecycle (Keep-vs-evict tradeoff); assets=fig3a-idle-kv-blocks, fig3b-kv-cache-lifecycle
// QA: Peak-waste number is legible, Lifecycle diagram stays readable

== Why Existing Systems Miss It

#table(
  columns: (1.0fr, 1.2fr, 1.15fr, 1.45fr),
  inset: 8pt,
  align: (left, left, left, left),
  [*View*],
  [*Examples*],
  [*Optimizes*],
  [*Still misses*],
  [Agent-aware],
  [Parrot / Autellix / Teola],
  [DAG order, stage overlap],
  [No KV-cache control, so critical inversion remains.],
  [KV-cache-centric],
  [vLLM / Mooncake / CachedAttention / LMCache],
  [Fragmentation or offload],
  [No agent criticality or function-call trigger.],
)

// Render mode: script
// Claim ids: c2
// Evidence: text:source-introduction (Parrot / Autellix / Teola vs vLLM / Mooncake / CachedAttention / LMCache); text:table-2 (Reactive versus function-call-aware offload and prefetch)
// QA: Table stays concise, Each row states one gap clearly

= Design

== Tokencake Overview

#grid(
  columns: (0.92fr, 1.08fr),
  gutter: 0.8em,
  [
    #ibox[
      *Thesis:* Multi-agent serving should manage KV cache across both time and space, not as a scheduler-only tweak.
    ]
    
    #hbox[
      *Control split:* The frontend exposes agent structure, while the time and space schedulers share one memory pool.
    ]
    
  ],
  [
    #imgs(
      (image("assets/fig4-overview.jpeg"), [Tokencake Overview]),
      width: 100%,
    )
    
  ],
)

// Render mode: script
// Claim ids: c3
// Evidence: asset:fig4-overview (Frontend API + space scheduler + time scheduler); assets=fig4-overview
// QA: Overview figure is dominant evidence, Boxes remain one line each

== Expose Agent Context to the Runtime

#ibox[
  *Takeaway:* The API exports DAG structure, internal function-call stages, and predict_time, which turns the runtime into an application-aware controller.
]

#imgs(
  (image("assets/fig5-api.jpeg"), [Frontend API]),
  (image("assets/fig6-coordination.jpeg"), [Scheduler Coordination]),
  width: 96%,
  gap: 0.8em,
)

// Render mode: script
// Claim ids: c3
// Evidence: asset:fig5-api (Staged FuncNode graph definition); asset:fig6-coordination (Joint scheduler coordination); assets=fig5-api, fig6-coordination
// QA: API figure stays readable, Coordination diagram does not become a thumbnail

== Function-Call-Aware Time Scheduler

#grid(
  columns: (0.92fr, 1.08fr),
  gutter: 0.8em,
  [
    #ibox[
      *Runtime:* `call_start` and `call_finish` turn a tool stall into an explicit offload and prefetch window.
    ]
    
    #hbox[
      *Decision:* Offload only when the predicted stall exceeds transfer cost, then upload before the expected resume time.
    ]
    
  ],
  [
    #imgs(
      (image("assets/fig7-lifecycle.jpeg"), [Time Scheduler Lifecycle]),
      width: 100%,
    )
    
  ],
)

// Render mode: script
// Claim ids: c4
// Evidence: asset:fig7-lifecycle (Offload / predict / upload lifecycle); equation:eq1-duration-blend (Duration estimate); equation:eq2-transfer-cost (Transfer threshold); text:algorithm-1 (Benefit-driven offload decision); assets=fig7-lifecycle; equations=eq1-duration-blend, eq2-transfer-cost
// QA: Lifecycle figure stays legible, Equation text fits without shrinking

== Dynamic Memory Partitioning

#grid(
  columns: (0.92fr, 1.08fr),
  gutter: 0.8em,
  [
    #ibox[
      *Priority:* Static DAG importance is combined with dynamic wait-time urgency to decide which agent types deserve protection.
    ]
    
    #hbox[
      *Control loop:* Tokencake grows the reserved pool under pressure while keeping a shared pool for opportunistic use.
    ]
    
  ],
  [
    #imgs(
      (image("assets/fig8-space-scheduler.jpeg"), [Space Scheduler Feedback Loop]),
      width: 100%,
    )
    
  ],
)

// Render mode: script
// Claim ids: c5
// Evidence: asset:fig8-space-scheduler (Reservation feedback loop); equation:eq3-static-priority (Structural importance); equation:eq4-dynamic-priority (Runtime urgency); text:algorithm-2 (Two-phase reservation update); assets=fig8-space-scheduler; equations=eq3-static-priority, eq4-dynamic-priority
// QA: Feedback-loop figure remains readable, Priority formulas fit cleanly

= Evaluation

== Experimental Setup

#ibox[
  *Stress test:* Two representative agentic apps, two Qwen sizes, and mainstream baselines stress both concurrency and dependency-heavy workflows.
]

#hbox[
  *Platform:* Qwen2.5-14B on A100 80GB, Qwen2.5-32B on H200 140GB, plus 100GB of CPU swap space for offloaded KV cache.
]

#nbox(compact: true)[
  Benchmarks: Code-Writer stresses concurrent agents; Deep Research stresses dependency-heavy workflows. Load: request arrivals follow application QPS and tool latencies are both Poisson-simulated. Baselines / metrics: vLLM and LightLLM; end-to-end latency, GPU KV usage, and abnormal agent count.
]

// Render mode: script
// Claim ids: c6
// Evidence: text:section-7.1 (Qwen2.5-14B / A100 80GB, Qwen2.5-32B / H200 140GB, 100GB CPU swap); text:section-7.1 (Code-Writer, Deep Research, Poisson arrivals, vLLM, LightLLM)
// QA: Setup slide remains box-led rather than turning into a dense table, Hardware and benchmark details stay within one page

== Latency Improves Under Load

#ibox[
  *Takeaway:* Tokencake pulls away as memory pressure rises, which matches the paper’s contention thesis.
]

#imgs(
  (image("assets/fig9-latency.jpeg"), [End-to-End Latency]),
  width: 94%,
)

// Render mode: script
// Claim ids: c6
// Evidence: asset:fig9-latency (Latency vs QPS); text:section-7.2 (47.06% lower latency than vLLM at 1.0 QPS); assets=fig9-latency
// QA: All four subplots remain readable, Anchor number stays prominent

== GPU Memory Stays Productive

#ibox[
  *Takeaway:* Offloading stalled caches keeps utilization near 86 to 87 percent instead of leaving memory occupied but not useful.
]

#imgs(
  (image("assets/fig10-gpu-utilization.jpeg"), [GPU KV Utilization]),
  width: 94%,
)

// Render mode: script
// Claim ids: c6
// Evidence: asset:fig10-gpu-utilization (Higher GPU KV utilization); text:section-7.2 (Up to 16.9% higher utilization than vLLM); assets=fig10-gpu-utilization
// QA: Bar labels remain legible, Takeaway box stays short

== Critical-Path Agents Stop Stalling

#ibox[
  *Takeaway:* Agent-aware reservations cut the long-tail stalls that dominate workflow completion time.
]

#imgs(
  (image("assets/fig12-abnormal-agents.jpeg"), [Abnormal Agents]),
  width: 94%,
)

// Render mode: script
// Claim ids: c6
// Evidence: asset:fig12-abnormal-agents (Abnormal-agent count); text:section-7.3 (File Write abnormal agents drop from 90 to 27 versus both baselines); asset:fig11-agent-latency (Most agent types also run faster); assets=fig12-abnormal-agents
// QA: Abnormal-agent bars remain readable, Anchor number is easy to spot

== Reuse Beats Recompute

#ibox[
  *Takeaway:* If a tool stall is long enough, moving KV cache is far cheaper than rebuilding the prefix later.
]

#imgs(
  (image("assets/fig13-offload-vs-recompute.jpeg"), [Transfer vs Recomputation]),
  width: 94%,
)

// Render mode: script
// Claim ids: c6
// Evidence: asset:fig13-offload-vs-recompute (Transfer versus recompute); text:section-7.4 (4096 blocks: about 60 ms transfer versus about 8943 ms recomputation); assets=fig13-offload-vs-recompute
// QA: Comparison curve stays readable, One key number remains visible

== Offload Overhead Needs Mitigation

#ibox[
  *Takeaway:* Proactive offload only works if the runtime removes the bursty allocation overhead it creates.
]

#imgs(
  (image("assets/fig14-overhead-mitigation.jpeg"), [Overhead Mitigation]),
  width: 94%,
)

// Render mode: script
// Claim ids: c6
// Evidence: asset:fig14-overhead-mitigation (Optimized versus baseline transfer latency); text:section-7.4 (5120 blocks: 15163 ms baseline upload versus 4.4 ms optimized); assets=fig14-overhead-mitigation
// QA: Upload-latency comparison stays readable, Optimization box stays concise

= Takeaways

== What Matters in Tokencake

// Render mode: script
// Claim ids: c6
// Evidence: claim:c4 (Function-call-aware time scheduling); claim:c5 (Criticality-aware space scheduling); asset:fig9-latency (Latency gains); asset:fig10-gpu-utilization (Memory productivity); asset:fig12-abnormal-agents (Critical-path stability); asset:fig14-overhead-mitigation (Practical offload overhead)
// QA: Final boxes stay balanced, Limitations fit without overflow

= Back Matter

== Questions?

// Render mode: script
// Claim ids: c6
// Evidence: text:closing (Thank-you slide with QR code)
// QA: QR code remains visible, Closing slide stays uncluttered
