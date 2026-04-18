# Tokencake: A KV-Cache-centric Serving Framework for LLM-based Multi-Agent Applications Slide Map

| # | Section | Title | Takeaway | Evidence | Archetype | Role | Density |
|---|---|---|---|---|---|---|---|
| 1 | Front Matter | Tokencake | KV-cache management is the central systems bottleneck for multi-agent LLM serving. | text:paper-metadata (Title, authors, arXiv version, and date) | Title slide | title | low |
| 2 | Motivation | Motivation | Multi-agent workloads expose KV-cache pathologies that current serving systems do not handle well. | claim:c1 (Space contention and time underutilization) | Outline / Roadmap | section-divider | low |
| 3 | Motivation | Agentic Workloads Stress KV Cache | Multi-agent DAGs mix critical-path dependencies with long external tool stalls, so serving sees both heterogeneous agent importance and large idle windows. | asset:fig1a-coding (Coding workflow example); asset:fig1b-deep-research (Research workflow example); text:table-1 (Tool latencies span 100 ms to 5-30 s with large variability); assets=fig1a-coding, fig1b-deep-research | Two-Up Comparison | motivation | medium |
| 4 | Motivation | Space Contention | FCFS-style allocation lets non-critical agents occupy scarce KV-cache blocks before critical-path work arrives. | asset:fig2a-space-contention-analysis (Preemption events accumulate over time); asset:fig2b-space-contention-diagram (Critical inversion cartoon); assets=fig2a-space-contention-analysis, fig2b-space-contention-diagram | Two-Up Comparison | problem | medium |
| 5 | Motivation | Time Underutilization | Function-call stalls leave useful KV cache idle on the GPU, even though active requests still need memory. | asset:fig3a-idle-kv-blocks (18.5% peak waste); asset:fig3b-kv-cache-lifecycle (Keep-vs-evict tradeoff); assets=fig3a-idle-kv-blocks, fig3b-kv-cache-lifecycle | Two-Up Comparison | problem | medium |
| 6 | Motivation | Why Existing Systems Miss It | Prior systems optimize either workflow scheduling or KV-cache management, but not both together for agentic workloads. | text:source-introduction (Parrot / Autellix / Teola vs vLLM / Mooncake / CachedAttention / LMCache); text:table-2 (Reactive versus function-call-aware offload and prefetch) | Table-Led Structured Slide | positioning | medium |
| 7 | Design | Design | Tokencake combines a DAG-aware frontend with coordinated time and space schedulers around the KV cache. | claim:c3 (Architecture and coordination thesis) | Outline / Roadmap | section-divider | low |
| 8 | Design | Tokencake Overview | Tokencake co-optimizes KV-cache management across both time and space, not as a bolt-on scheduler tweak. | asset:fig4-overview (Frontend API + space scheduler + time scheduler); assets=fig4-overview | Method Overview Side-by-Side | thesis | medium |
| 9 | Design | Expose Agent Context to the Runtime | The API exports DAG structure, internal function-call stages, and predict_time, which turns the runtime into an application-aware controller. | asset:fig5-api (Staged FuncNode graph definition); asset:fig6-coordination (Joint scheduler coordination); assets=fig5-api, fig6-coordination | Two-Up Comparison | mechanism-overview | medium |
| 10 | Design | Function-Call-Aware Time Scheduler | Offload only when a predicted stall is long enough to create useful scheduling capacity, then upload before resume. | asset:fig7-lifecycle (Offload / predict / upload lifecycle); equation:eq1-duration-blend (Duration estimate); equation:eq2-transfer-cost (Transfer threshold); text:algorithm-1 (Benefit-driven offload decision); assets=fig7-lifecycle; equations=eq1-duration-blend, eq2-transfer-cost | Method Overview Side-by-Side | mechanism-detail | medium |
| 11 | Design | Dynamic Memory Partitioning | Tokencake protects critical agents with adaptive reservations driven by hybrid priority and observed memory pressure. | asset:fig8-space-scheduler (Reservation feedback loop); equation:eq3-static-priority (Structural importance); equation:eq4-dynamic-priority (Runtime urgency); text:algorithm-2 (Two-phase reservation update); assets=fig8-space-scheduler; equations=eq3-static-priority, eq4-dynamic-priority | Method Overview Side-by-Side | mechanism-detail | medium |
| 12 | Evaluation | Evaluation | The evaluation tests whether more productive KV-cache use yields better latency, utilization, and stability. | claim:c6 (Measured gains under load) | Outline / Roadmap | section-divider | low |
| 13 | Evaluation | Experimental Setup | The evaluation stresses realistic multi-agent workloads on two Qwen sizes and compares against mainstream serving baselines. | text:section-7.1 (Qwen2.5-14B / A100 80GB, Qwen2.5-32B / H200 140GB, 100GB CPU swap); text:section-7.1 (Code-Writer, Deep Research, Poisson arrivals, vLLM, LightLLM) | Table-Led Structured Slide | evaluation-setup | high |
| 14 | Evaluation | Latency Improves Under Load | Tokencake pulls away as memory pressure rises, which matches the paper’s contention thesis. | asset:fig9-latency (Latency vs QPS); text:section-7.2 (47.06% lower latency than vLLM at 1.0 QPS); assets=fig9-latency | Figure-Led Vertical | evaluation-main | medium |
| 15 | Evaluation | GPU Memory Stays Productive | Offloading stalled caches keeps utilization near 86 to 87 percent instead of leaving memory occupied but not useful. | asset:fig10-gpu-utilization (Higher GPU KV utilization); text:section-7.2 (Up to 16.9% higher utilization than vLLM); assets=fig10-gpu-utilization | Figure-Led Vertical | evaluation-support | medium |
| 16 | Evaluation | Critical-Path Agents Stop Stalling | Agent-aware reservations cut the long-tail stalls that dominate workflow completion time. | asset:fig12-abnormal-agents (Abnormal-agent count); text:section-7.3 (File Write abnormal agents drop from 90 to 27 versus both baselines); asset:fig11-agent-latency (Most agent types also run faster); assets=fig12-abnormal-agents | Figure-Led Vertical | evaluation-support | medium |
| 17 | Evaluation | Reuse Beats Recompute | If a tool stall is long enough, moving KV cache is far cheaper than rebuilding the prefix later. | asset:fig13-offload-vs-recompute (Transfer versus recompute); text:section-7.4 (4096 blocks: about 60 ms transfer versus about 8943 ms recomputation); assets=fig13-offload-vs-recompute | Figure-Led Vertical | evaluation-support | medium |
| 18 | Evaluation | Offload Overhead Needs Mitigation | Proactive offload only works if the runtime removes the bursty allocation overhead it creates. | asset:fig14-overhead-mitigation (Optimized versus baseline transfer latency); text:section-7.4 (5120 blocks: 15163 ms baseline upload versus 4.4 ms optimized); assets=fig14-overhead-mitigation | Figure-Led Vertical | evaluation-support | medium |
| 19 | Takeaways | What Matters in Tokencake | The paper’s contribution is the combination of function-call-aware time scheduling and criticality-aware memory partitioning, with remaining limits in prediction quality and single-GPU scope. | claim:c4 (Function-call-aware time scheduling); claim:c5 (Criticality-aware space scheduling); asset:fig9-latency (Latency gains); asset:fig10-gpu-utilization (Memory productivity); asset:fig12-abnormal-agents (Critical-path stability); asset:fig14-overhead-mitigation (Practical offload overhead) | Conclusion / Takeaways | conclusion | medium |
| 20 | Back Matter | Questions? | Questions and discussion. | text:closing (Thank-you slide with QR code) | Conclusion / Takeaways | closing | low |

## QA Expectations

- title: Title remains readable on the title slide
- section-motivation: Divider page remains visually clean
- motivation-workloads: Both workflow panels stay readable, Boxes stay to one line each
- motivation-space-contention: Both panels remain readable, The consequence box stays concise
- motivation-time-underutilization: Peak-waste number is legible, Lifecycle diagram stays readable
- motivation-prior-systems: Table stays concise, Each row states one gap clearly
- section-design: Divider page remains visually clean
- design-overview: Overview figure is dominant evidence, Boxes remain one line each
- design-agent-context: API figure stays readable, Coordination diagram does not become a thumbnail
- design-time-scheduler: Lifecycle figure stays legible, Equation text fits without shrinking
- design-space-scheduler: Feedback-loop figure remains readable, Priority formulas fit cleanly
- section-evaluation: Divider page remains visually clean
- eval-setup: Setup table remains readable, No overflow from hardware details
- eval-latency: All four subplots remain readable, Anchor number stays prominent
- eval-utilization: Bar labels remain legible, Takeaway box stays short
- eval-critical-path: Abnormal-agent bars remain readable, Anchor number is easy to spot
- eval-reuse-vs-recompute: Comparison curve stays readable, One key number remains visible
- eval-overhead-mitigation: Upload-latency comparison stays readable, Optimization box stays concise
- takeaways: Final boxes stay balanced, Limitations fit without overflow
- thank-you: QR code remains visible, Closing slide stays uncluttered
