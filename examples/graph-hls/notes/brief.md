# Graph.hls Brief

Artifact Progress:
- [x] Recover likely visuals and write `notes/asset-manifest.md`
- [x] Write `notes/brief.md` from the paper text and manifest
- [x] Write `notes/slide-map.md` with evidence and archetypes

## Scenario

- language: English
- register: concise academic seminar / paper-reading deck
- deck_arc: `Systems Paper Reading / OSDI-SOSP Style`
- audience_assumption: computer architecture / systems readers who know HLS and FPGA basics but do not know this compiler

## One-Sentence Thesis

Graph.hls argues that graph accelerator design should be expressed as a cost-tiered, domain-specific configuration problem, with a compiler generating consistent hardware and an IR-level verifier replacing slow emulation loops.

## Problem and Motivation

- Existing HLS graph frameworks leave optimizations trapped inside incompatible codebases, so developers cannot compose techniques from ReGraph, ThunderGP, and similar systems through configuration alone.
- The motivating example is deliberately simple: changing SSSP node properties from 32-bit to 16-bit requires edits across `200+` lines and `10+` files.
- The paper frames the second pain point as verification latency: hardware emulation takes `50+ minutes` per iteration, and locating one algorithmic failure can consume about `6 hours`.
- The workflow failure is structural rather than accidental: algorithm logic, hardware structure, and validation are tightly coupled, so every change becomes a manual integration and debugging task.

## Deck-Level Claims

1. Existing graph-HLS workflows fail because optimization composition and verification are both manual, high-latency tasks.
2. Graph.hls makes the design space composable by organizing parameters into `L1` graph constants, `L2` microarchitecture configuration, and `L3` dataflow strategies.
3. The frontend is expressive enough to cover GAS-style workloads and more irregular graph kernels through `iteration_input`, `map`, `filter`, `reduce`, and `return`.
4. GH-Architect turns those declarations into consistent hardware through heuristic `L3` selection plus deterministic `L1/L2` dependency propagation.
5. GH-Scope shortens the design loop by verifying the Graph.hls IR with type checks, cycle checks, overflow checks, infinite-loop checks, and golden-reference comparison before slow synthesis.
6. The framework improves both performance and productivity: `2.6x` over ReGraph, `1.2x` over ThunderGP, `4.48x` with full multi-level exploration, `301.6x` over Vitis C-Sim, and up to `455,000x` over hardware emulation.

## Method Components

### 1. Hierarchical design abstraction

- `L1` parameters change graph-processing behavior without changing dataflow structure.
- `L2` parameters change representations such as vertex-property bitwidth, edge representation, and parallel lane count; these propagate through the accelerator.
- `L3` parameters change the top-level processing model, such as partitioning strategy and resource assignment, and therefore affect both host code and FPGA organization.
- The key argument is that modification cost is the right abstraction boundary for graph accelerators: `L1` is single-line, `L2` is multi-file propagation, and `L3` is architectural redesign.

### 2. Cross-level dependency reasoning

- The paper insists that graph optimizations are not independent knobs.
- Example dependency: convergence threshold (`L1`) constrains property precision (`L2`).
- Example dependency: `16-bit` properties (`L2`) enable `2x` larger partitions (`L3`), from `512K` to `1M` vertices fitting in URAM.
- Example dependency: partition strategy (`L3`) constrains edge-property representation (`L2`) because vertex-cut replication changes storage decisions.

### 3. Graph.hls frontend

- The frontend is a DSL that builds a spatial dataflow DAG from a graph algorithm specification.
- The paper presents it as a superset of GAS because `Scatter`, `Gather`, and `Apply` map to `iteration_input + map`, `reduce`, and post-reduction `map`.
- The “beyond GAS” evidence is Belief Propagation: selective exclusion of one incoming neighbor can be expressed by inserting `filter` before `reduce`, which GAS cannot express directly.
- Assumptions are explicit: unordered streams, associative/commutative reductions, and one-iteration-at-a-time kernel execution with host-driven outer convergence.

### 4. GH-Architect

- GH-Architect first parses the DSL into a Graph.hls IR with five node types: `iteration_input`, `map`, `filter`, `reduce`, and `return`.
- `L3` is selected heuristically from graph statistics and hardware structure.
- `L1` and `L2` are then resolved by bidirectional dependency propagation until a fixed point is reached.
- The strongest worked example is PageRank on `rmat-21-32` targeting an `Alveo U55C`:
  - The U55C has `3` SLRs and `14` pipeline slots.
  - GH-Architect chooses `11` little pipelines and `3` big pipelines based on the power-law degree distribution.
  - At `32-bit`, each `72-bit` URAM row holds `2` values, so `65,536` destinations require `64` URAMs per pipeline and `896 / 960` total URAMs.
  - `16-bit` looks physically feasible but fails algorithmically for PageRank because contributions around `1e-3` round to zero under the fixed-point precision the paper discusses.
- The user-facing claim is that the compiler replaces “weeks of expert-level integration” with a configuration change.

### 5. GH-Scope

- GH-Scope operates on the Graph.hls IR instead of C-level HLS code.
- Pre-synthesis checks: type consistency and circular-dependency detection on the computation DAG.
- Simulation-time checks: overflow detection and infinite-loop detection.
- Correctness check: automatic comparison against pre-validated golden references maintained inside the framework.
- The paper’s core argument is that keeping graph semantics at the IR level makes conflicts debuggable; the tool can point to the responsible source/destination vertices instead of raw array addresses.

## Evaluation Setup

- Platforms:
  - `Alveo U55C`: `1,304K` LUTs, `960` URAMs, `460 GB/s`, `32` channels, `115W`
  - `Alveo U200`: `1,182K` LUTs, `960` URAMs, `77 GB/s`, `4` channels, `215W`
- Algorithms: `PR`, `SSSP`, `Weighted SSSP`, `CC`, `AR`, `WCC`
- Datasets: `14` graphs spanning synthetic, social, collaboration, and web workloads
- Baselines:
  - ReGraph on the HBM platform (`U55C`)
  - ThunderGP on the DDR platform (`U200`)
- Fairness condition:
  - For baseline comparisons, Graph.hls fixes `L2` and `L3` to match the baseline configuration.
  - The reported head-to-head gains in Figures `6` and `7` come from `L1` exploration only.

## Quantitative Results

- Main runtime wins:
  - `2.6x` average speedup over ReGraph on `U55C`
  - `1.2x` average speedup over ThunderGP on `U200`
- Coverage claim:
  - ThunderGP runs out of memory on `five` large-graph cases, while Graph.hls completes them
- Ablation on SSSP over ReGraph:
  - Naive: `0.71x`
  - `L1` only: `1.99x`
  - `L1 + L2`: `2.95x`
  - `L1 + L3`: `2.52x`
  - `L1 + L2 + L3`: `4.48x`
- GH-Scope productivity:
  - full validation in `0.02` seconds
  - algorithm-failure debugging: `~6 hours` to `0.04s` (`~455,000x`)
  - stream type mismatch: `73m 40s` to `0.02s` (`~186,000x`)
  - parameter mismatch: `13m 13s` to `0.02s` (`~33,000x`)
- Large-graph simulation:
  - `301.6x` average over Vitis C-Sim
  - example: PageRank on `rmat-24-16` drops from `1779.06s` to `8.29s` (`215x`)

## Evidence Inventory

- Motivation and workflow pathology:
  - `fig1-workflow`
  - `fig2-bitwidth-cascade`
- Thesis and system framing:
  - `fig3-overview`
  - `fig4-hierarchy`
- Frontend and generation:
  - `fig5a-dsl`
  - `fig5b-level-examples`
- Runtime evaluation:
  - `fig6-vs-regraph`
  - `fig7-vs-thundergp`
  - `fig8-ablation`
- Verification and simulation:
  - `table5-debugging`
  - `fig9-simulation-speedup`
- Setup references:
  - `table3-platforms`
  - `table4-datasets`

## Discussion and Critique Hooks

- The baseline comparisons are intentionally parameter-matched by fixing `L2/L3`, which makes the fairness story cleaner but also means Figures `6` and `7` are not “full search versus full search.”
- The simulator comparison uses Vitis `C-Sim` as a proxy because the prior parallel HLS simulator the authors cite is not open-sourced.
- The paper strongly emphasizes performance and iteration time, but the main text gives less detail on code quality overheads, synthesis effort, or generator complexity costs than on runtime wins.

