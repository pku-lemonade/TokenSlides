# Tokencake: A KV-Cache-centric Serving Framework for LLM-based Multi-Agent Applications Brief

## Paper

- Title: Tokencake: A KV-Cache-centric Serving Framework for LLM-based Multi-Agent Applications
- Authors: Zhuohang Bian, Feiyang Wu, Teng Ma, Youwei Zhuo
- Venue/status: arXiv preprint (v2)
- Date: October 31, 2025
- Talk mode: en paper-reading deck

## Presentation Thesis

Tokencake argues that multi-agent LLM serving should treat KV cache as a shared workflow resource across both time and space: proactive offload and prefetch exploit tool stalls, while critical-path-aware reservation prevents agent interference.

## Problem Framing

- Workload shift: Multi-agent applications combine agent-agent dependencies with long external function calls, so KV-cache usage is no longer a simple per-request lifecycle.
- Space contention: A non-critical agent can evict a critical-path agent, forcing context recomputation and stalling the entire workflow.
- Time underutilization: During a function call, an agent's KV cache sits idle on the GPU; the paper reports peaks where 18.5% of the used KV-cache pool is occupied by stalled agents.
- Prior-work gap: Compute-centric agent schedulers ignore GPU memory state, while memory-centric KV-cache systems remain agent-agnostic and reactive.

## Deck-Level Claims

- C1: Agentic multi-agent workloads expose two distinct KV-cache failures: critical-path contention in space and idle-cache underutilization in time.
  Evidence: tokencake-fig02-space-contention, tokencake-fig03-time-underutilization, 18.5% idle used KV cache at peak
- C2: Tokencake's core contribution is to co-optimize KV-cache management across both dimensions instead of treating scheduling and memory management as separate problems.
  Evidence: tokencake-fig04-overview, tokencake-fig06-coordination
- C3: The Time Scheduler uses function-call awareness to proactively offload stalled agents and predictively upload their KV cache before resumption.
  Evidence: tokencake-fig07-time-lifecycle, Table 2 comparison against reactive policies
- C4: The Space Scheduler protects critical agents through hybrid-priority scoring and dynamic memory partitioning rather than FIFO allocation.
  Evidence: tokencake-fig08-space-feedback, critical_ratio, hybrid priority metric
- C5: Co-optimizing the two schedulers improves loaded-system performance, cutting end-to-end latency by over 47.06% and raising effective GPU KV utilization by up to 16.9% versus vLLM.
  Evidence: tokencake-fig09-latency, tokencake-fig10-utilization, tokencake-fig12-abnormal-agents
- C6: The offload policy is practical because transfer is far cheaper than recomputation, and Tokencake's buffering and reservation optimizations keep upload overhead in the millisecond range.
  Evidence: tokencake-fig13-offload-tradeoff, tokencake-fig14-overhead-mitigation

## Method Breakdown

- Frontend graph plus metadata: Users describe the agent DAG and function-call nodes, including predicted tool time, so the runtime can reason about dependencies and stall windows.
- Time Scheduler: Static graph analysis finds LLM -> tool -> LLM patterns; runtime call_start and call_finish events drive benefit-based offload and predictive upload.
- Space Scheduler: The scheduler designates the top critical_ratio of agent types as critical using hybrid priority, then splits GPU KV memory into shared and reserved pools that adapt to memory pressure.
- Offload optimizations: CPU block buffering and gradual GPU block reservation keep frequent offload and upload operations cheap enough to use proactively.

## Evaluation Setting

- Applications: Code-Writer and Deep Research represent tool-heavy, dependency-rich multi-agent workloads.
- Baselines: vLLM and LightLLM isolate the effect of Tokencake's agent-aware memory policies because neither baseline includes proactive offloading or predictive uploading.
- Metrics: End-to-end latency, GPU KV-cache utilization, agent latency, abnormal-agent count, and offload or recompute microbenchmarks.
- Load model: Request arrivals follow a Poisson process with comparisons reported across increasing QPS.

## Quantitative Anchors

- Latency improvement: over 47.06% lower end-to-end latency versus vLLM at 1.0 QPS
- KV utilization: up to 16.9% higher effective GPU KV-cache utilization
- Idle cache peak: 18.5% of used KV cache occupied by stalled agents at peak
- Transfer versus recompute: 4096 blocks: about 60 ms transfer versus nearly 9,000 ms recomputation
- Upload overhead mitigation: 5120-block upload drops from 15,163 ms to 4.4 ms with Tokencake's optimizations
- Critical-path metric: abnormal agent means execution time above 1.5x the type average

## Evidence Map

- C1: asset:tokencake-fig02-space-contention, asset:tokencake-fig03-time-underutilization, text:source:29-31;146-148
- C2: asset:tokencake-fig04-overview, asset:tokencake-fig06-coordination, text:source:155-157;184-190
- C3: asset:tokencake-fig07-time-lifecycle, text:source:239-271;470-471
- C4: asset:tokencake-fig08-space-feedback, text:source:346-367;391-392
- C5: asset:tokencake-fig09-latency, asset:tokencake-fig10-utilization, asset:tokencake-fig12-abnormal-agents, text:source:516-517;536-537
- C6: asset:tokencake-fig13-offload-tradeoff, asset:tokencake-fig14-overhead-mitigation, text:source:575-576;610-612;638-640

## Limitations

- Prediction model: Tool-time prediction is deliberately simple; richer features such as call arguments are left to future work.
- Single-GPU scope: The evaluation is limited to one GPU, so distributed KV-cache placement remains open.
- Benchmark breadth: The paper evaluates two representative multi-agent applications rather than a broad public benchmark suite.

## Best Asset-to-Claim Matches

- Workload model: tokencake-fig01-workloads
- Core pathologies: tokencake-fig02-space-contention, tokencake-fig03-time-underutilization
- System overview: tokencake-fig04-overview, tokencake-fig06-coordination
- Time scheduler mechanism: tokencake-fig07-time-lifecycle
- Space scheduler mechanism: tokencake-fig08-space-feedback
- Main performance result: tokencake-fig09-latency, tokencake-fig10-utilization, tokencake-fig12-abnormal-agents
- Offload practicality: tokencake-fig13-offload-tradeoff, tokencake-fig14-overhead-mitigation

## Notes

Table 2 is useful background, but the deck can cover the prior-work gap with concise text boxes instead of a dense table crop.
