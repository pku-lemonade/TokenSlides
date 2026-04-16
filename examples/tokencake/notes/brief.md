# Tokencake Paper Brief

## Scenario

- Talk type: English paper reading / seminar deck
- Source: `tokencake.pdf`
- Paper title: `Tokencake: A KV-Cache-centric Serving Framework for LLM-based Multi-Agent Applications`
- Authors: Zhuohang Bian, Feiyang Wu, Teng Ma, Youwei Zhuo
- Version/date in PDF: `arXiv:2510.18586v2`, October 31, 2025

## Problem

Tokencake studies LLM-based multi-agent applications with frequent external function calls. These workloads stress the KV cache in two distinct ways:

- Space contention: many agents compete for limited GPU KV-cache blocks, so non-critical agents can evict critical-path agents and trigger expensive recomputation.
- Time underutilization: during `LLM Inference1 -> Function Call -> LLM Inference2`, the stalled agent's KV cache sits idle in GPU memory while the tool call runs.

The paper argues that current serving systems miss this workload because they either optimize agent scheduling without controlling memory, or optimize KV-cache memory without understanding agent criticality and function-call structure.

## Motivation and Assumptions

- Multi-agent applications are naturally represented as DAGs with explicit dependencies between specialized agents.
- Critical-path agents matter more than off-path agents because their stalls directly increase end-to-end latency.
- Tool calls have broad and unpredictable latency ranges. Table 1 reports examples from `100 ms` to `5-30 s`, with variability up to `10-60 s`.
- Function-call stalls are predictable enough to become a scheduling window if the system tracks call boundaries and rough completion times.

## Main Idea

Tokencake is a KV-cache-centric serving framework that co-optimizes scheduling and memory management with agent-level context.

- The frontend API lets users define the application as a DAG and annotate function-call nodes with internal stages and predicted durations.
- The Time Scheduler proactively offloads KV cache to CPU memory during long tool stalls and predictively uploads it before the agent resumes.
- The Space Scheduler dynamically partitions GPU KV-cache memory so critical agents retain reserved capacity under pressure.
- Additional runtime optimizations make frequent offload/upload practical instead of turning transfer overhead into a new bottleneck.

## Method Components

### 1. Frontend API

- Represents the application as a DAG of nodes and dependencies.
- Adds `FuncNode` to model external tool calls.
- Allows internal stage decomposition inside a function-using node, for example `query -> embed -> generate`.
- Allows developers to provide `predict_time`, which seeds the Time Scheduler's duration forecast.

### 2. Time Scheduler

- Static pre-analysis finds `LLM Inference1 -> Function Call -> LLM Inference2` patterns and initializes cold-start duration estimates.
- Runtime is event-driven via `call_start` and `call_finish`.
- Offload decision is opportunistic rather than unconditional.
- Core criterion: offload only when the scheduling benefit of freed memory exceeds transfer overhead.
- Decision factors:
  - predicted function-call duration
  - KV-cache size in blocks
  - waiting request queue state
- Predictive upload starts before the function call completes, using a mixed estimate:
  - `t_final = alpha * t_req + (1 - alpha) * t_hist`

### 3. Time-Scheduler Optimizations

- CPU block buffering:
  - keeps freed CPU blocks in an internal free list instead of returning them to the OS
  - avoids bursty allocation/deallocation overhead during frequent offload cycles
- Gradual GPU block reservation:
  - reserves GPU destination blocks over several scheduling cycles before upload
  - avoids all-at-once allocation stalls when the predicted resume time approaches

### 4. Space Scheduler

- Solves critical inversion with dynamic memory partitioning.
- Splits GPU KV-cache memory into:
  - a shared pool for all agents
  - a reserved pool for currently critical agents
- Periodically identifies critical agent types with a hybrid priority score.
- Priority combines:
  - static structure from the DAG
  - dynamic runtime urgency
- Reservation size adapts to global memory pressure and to each critical agent's historical usage plus score.

## Why Prior Work Falls Short

- Agent-aware but compute-centric:
  - Parrot and Autellix use the application graph for request-level scheduling but do not manage KV-cache memory.
  - Teola overlaps LLM and non-LLM stages but remains blind to underlying GPU KV-cache occupancy.
- KV-cache-centric but agent-agnostic:
  - vLLM fixes fragmentation with PagedAttention but keeps stalled caches resident.
  - Mooncake, CachedAttention, and LMCache support offloading, but their triggers are reactive and not function-call-aware.

## Evaluation Setup

- Implementation:
  - about `9k` lines of Python
  - Triton custom kernels
  - reuses some components from vLLM
- Models / hardware:
  - Qwen2.5-14B on `NVIDIA A100 80GB`
  - Qwen2.5-32B on `NVIDIA H200 140GB`
  - `100GB` CPU memory reserved as swap space for offloaded KV cache
- Benchmarks:
  - `Code-Writer`
  - `Deep Research`
- Workload generation:
  - requests synthesized from ShareGPT and AgentCode
  - arrival process follows a Poisson distribution over application QPS
  - tool latencies are simulated with a Poisson distribution to isolate serving behavior
- Baselines:
  - `vLLM`
  - `LightLLM`
- Metrics:
  - End-to-End Latency
  - GPU KV Cache Utilization
  - Abnormal Agent Count: agents whose execution time exceeds `1.5x` the average for their type

## Quantitative Results

- Motivation-level pathology:
  - at peak, stalled agents can occupy up to `18.5%` of the used GPU KV cache
- Main latency result:
  - at `1.0 QPS`, Tokencake reduces average end-to-end latency by over `47.06%` versus vLLM
- GPU memory efficiency:
  - Tokencake maintains about `85.7%` to `87.0%` GPU KV-cache utilization across loads
  - this is up to `16.9%` higher than vLLM
- Agent-level stability:
  - abnormal `File Write` agents drop from `90` to `27` versus vLLM and from `90` to `27` versus LightLLM
- Reuse vs recomputation:
  - for `4096` blocks, offload + upload is about `60 ms` total (`32 ms` offload, `29 ms` upload)
  - recomputation is about `8943 ms`
- Overhead-mitigation microbenchmark:
  - baseline upload grows from `4366 ms` at `1024` blocks to `15163 ms` at `5120` blocks
  - optimized upload stays in single-digit milliseconds and is `4.4 ms` at `5120` blocks

## Figure and Table Inventory

- `raw/tokencake-001-000.jpg`
  - Figure 1a, multi-agent coding workload example
  - proves the workload contains many collaborating agents plus tool-use stages
- `raw/tokencake-001-001.jpg`
  - Figure 1b, deep research workflow example
  - proves the workload also has long dependency chains and tool calls outside coding
- `raw/tokencake-002-002.jpg`
  - Figure 2a, critical-inversion / contention analysis over time
  - proves harmful preemptions are frequent
- `raw/tokencake-002-003.jpg`
  - Figure 2b, space-contention cartoon
  - proves FCFS-style allocation can stall a critical-path agent
- `raw/tokencake-002-004.jpg`
  - Figure 3a, idle KV-cache blocks over time
  - proves idle caches can consume a substantial fraction of GPU memory
- `raw/tokencake-002-005.jpg`
  - Figure 3b, function-call KV-cache lifecycle
  - proves why tool stalls create a keep-vs-evict tradeoff
- `raw/tokencake-003-006.jpg`
  - Figure 4, Tokencake overview
  - proves the system is built around frontend API plus space/time schedulers
- `raw/tokencake-004-007.jpg`
  - Figure 5, API example
  - proves the frontend exposes graph structure, internal stages, and timing hints
- `raw/tokencake-004-008.jpg`
  - Figure 6, scheduler coordination
  - proves the two schedulers cooperate rather than acting independently
- `raw/tokencake-005-009.jpg`
  - Figure 7, time-scheduler lifecycle
  - proves offload/prefetch is event-driven and predictive
- `raw/tokencake-007-010.jpg`
  - Figure 8, dynamic memory partitioning loop
  - proves reservations adapt to pressure and agent importance
- `raw/tokencake-010-011.jpg`
  - Figure 9, end-to-end latency versus QPS
  - proves Tokencake's advantage grows under load
- `raw/tokencake-010-012.jpg`
  - Figure 10, GPU KV-cache utilization
  - proves Tokencake keeps GPU memory productive
- `raw/tokencake-011-013.jpg`
  - Figure 11, average latency by agent type
  - proves most agent types benefit, not only one workload
- `raw/tokencake-011-014.jpg`
  - Figure 12, abnormal agent count
  - proves the space scheduler reduces critical-path stalls
- `raw/tokencake-011-015.jpg`
  - Figure 13, transfer time versus recomputation
  - proves KV-cache reuse is much cheaper than recomputing prefixes
- `raw/tokencake-012-016.jpg`
  - Figure 14, offload/upload overhead mitigation
  - proves CPU buffering plus gradual GPU reservation are necessary for viability

## Deck-Level Claims

- Multi-agent LLM serving fails for KV-cache reasons, not just compute scheduling reasons.
- The workload introduces two distinct KV-cache pathologies: critical-path space contention and function-call time underutilization.
- Tokencake's key move is to make KV-cache management agent-aware through the DAG API and function-call metadata.
- The Time Scheduler is proactive, benefit-driven, and predictive rather than reactive.
- The Space Scheduler protects critical agents with adaptive reservations instead of FCFS-style allocation.
- The measured gains come from keeping GPU memory productive: lower latency, higher utilization, and fewer abnormal agents.
