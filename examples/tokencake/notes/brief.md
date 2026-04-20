# Tokencake: A KV-Cache-centric Serving Framework for LLM-based Multi-Agent Applications Brief

## Paper

- Title: Tokencake: A KV-Cache-centric Serving Framework for LLM-based Multi-Agent Applications
- Authors: Zhuohang Bian, Feiyang Wu, Teng Ma, Youwei Zhuo
- Venue/status: arXiv:2510.18586v2
- Date: October 31, 2025
- Talk mode: en paper-reading deck

## Presentation Thesis

Tokencake argues that multi-agent LLM serving is bottlenecked by KV-cache management, so the runtime must manage cache lifecycle with both function-call awareness and agent criticality rather than treating memory as a passive byproduct of compute scheduling.

## Problem Framing

- Workload shift: Multi-agent applications execute as DAGs with heterogeneous agent importance and frequent external function calls.
- Pathology 1: Space contention causes critical inversion when non-critical agents consume scarce GPU KV-cache blocks before critical-path work arrives.
- Pathology 2: Time underutilization leaves stalled agents’ KV cache idle on the GPU during long tool calls.
- Why prior work misses it: Agent-aware schedulers ignore KV-cache placement, while KV-cache-centric systems remain reactive and agent-agnostic.

## Deck-Level Claims

- c1: Multi-agent applications create two distinct KV-cache pathologies: critical-path space contention and function-call time underutilization.
  Evidence: fig1a-coding, fig1b-deep-research, fig2a-space-contention-analysis, fig2b-space-contention-diagram, fig3a-idle-kv-blocks, fig3b-kv-cache-lifecycle, 18.5% peak idle-cache waste
- c2: Existing systems optimize either workflow scheduling or KV-cache management, but not both jointly for agentic workloads.
  Evidence: Parrot, Autellix, Teola, vLLM, Mooncake, CachedAttention, LMCache, Table 2 trigger comparison
- c3: Tokencake’s central design is a KV-cache-centric runtime that exposes agent structure through the frontend and coordinates space and time schedulers around one memory pool.
  Evidence: fig4-overview, fig5-api, fig6-coordination
- c4: The Time Scheduler should offload only when the predicted stall window exceeds transfer cost and should prefetch before the agent resumes.
  Evidence: fig7-lifecycle, eq1-duration-blend, eq2-transfer-cost, Algorithm 1
- c5: The Space Scheduler avoids critical inversion by reserving memory for critical agents using hybrid priority and runtime memory-pressure feedback.
  Evidence: fig8-space-scheduler, eq3-static-priority, eq4-dynamic-priority, Algorithm 2
- c6: The combined policy keeps GPU memory productive and translates into large wins under load: lower end-to-end latency, higher KV-cache utilization, fewer abnormal agents, and viable offload overhead.
  Evidence: fig9-latency, fig10-gpu-utilization, fig12-abnormal-agents, fig13-offload-vs-recompute, fig14-overhead-mitigation, 47.06% latency reduction, 16.9% utilization gain

## Method Breakdown

- Frontend API: Represents the application as a DAG, adds staged FuncNode abstractions, and lets developers provide predict_time hints.
- Time Scheduler: Uses call_start / call_finish events, predictive duration modeling, opportunistic offload, and predictive upload.
- CPU block buffering: Caches freed CPU blocks in an internal free list so bursty offload cycles avoid expensive allocator churn.
- Gradual GPU reservation: Reserves destination blocks over multiple cycles so predictive upload does not stall on one large allocation.
- Space Scheduler: Partitions GPU KV-cache into shared and reserved pools, then adjusts reserve size and per-agent shares from pressure, historical usage, and hybrid priority.

## Evaluation Setting

- Implementation: About 9k lines of Python with Triton kernels and reused vLLM components.
- Models / hardware: Qwen2.5-14B on NVIDIA A100 80GB and Qwen2.5-32B on NVIDIA H200 140GB.
- Swap space: 100GB of CPU memory reserved for offloaded KV cache.
- Benchmarks: Code-Writer and Deep Research.
- Workload model: Requests and tool latencies are both generated with Poisson processes.
- Baselines: vLLM and LightLLM.
- Metrics: End-to-End Latency, GPU KV Cache Utilization, and Abnormal Agent Count (>1.5x mean latency for its type).

## Quantitative Anchors

- Idle-cache waste: Up to 18.5% of used GPU KV cache is held by stalled agents.
- Headline latency gain: At 1.0 QPS, Tokencake reduces average end-to-end latency by over 47.06% versus vLLM.
- GPU utilization: Tokencake sustains about 85.7% to 87.0% utilization, up to 16.9% higher than vLLM.
- Abnormal agents: File Write abnormal agents fall from 90 to 27 versus both baselines.
- Transfer vs recompute: For 4096 blocks, transfer costs about 60 ms while recomputation costs about 8943 ms.
- Mitigated upload cost: At 5120 blocks, optimized upload is 4.4 ms versus 15163 ms in the unoptimized baseline.

## Evidence Map

- c1: asset:fig1a-coding, asset:fig1b-deep-research, asset:fig2a-space-contention-analysis, asset:fig2b-space-contention-diagram, asset:fig3a-idle-kv-blocks, asset:fig3b-kv-cache-lifecycle
- c2: text:source-introduction, text:table-2
- c3: asset:fig4-overview, asset:fig5-api, asset:fig6-coordination
- c4: asset:fig7-lifecycle, equation:eq1-duration-blend, equation:eq2-transfer-cost, text:algorithm-1
- c5: asset:fig8-space-scheduler, equation:eq3-static-priority, equation:eq4-dynamic-priority, text:algorithm-2
- c6: asset:fig9-latency, asset:fig10-gpu-utilization, asset:fig12-abnormal-agents, asset:fig13-offload-vs-recompute, asset:fig14-overhead-mitigation

## Limitations

- Prediction model: The scheduler relies on a relatively simple execution-time predictor and could benefit from richer features such as function-call arguments.
- Deployment scope: The evaluation is single-GPU; extending the design to multi-GPU and NVLink-backed hierarchies remains future work.

## Best Asset-to-Claim Matches

- Workload examples: fig1a-coding, fig1b-deep-research
- Workload pathologies: fig2a-space-contention-analysis, fig2b-space-contention-diagram, fig3a-idle-kv-blocks, fig3b-kv-cache-lifecycle
- Architecture and coordination: fig4-overview, fig5-api, fig6-coordination
- Time-scheduler mechanism: fig7-lifecycle, eq1-duration-blend, eq2-transfer-cost
- Space-scheduler mechanism: fig8-space-scheduler, eq3-static-priority, eq4-dynamic-priority
- Headline results: fig9-latency, fig10-gpu-utilization, fig12-abnormal-agents, fig13-offload-vs-recompute, fig14-overhead-mitigation

## Notes

Use the Systems Paper Reading / OSDI-SOSP Style arc. Keep titles short and make the KV-cache thesis explicit on every evidence slide.
