# GAMMA Paper Brief

## Scenario

- Talk type: English systems paper reading / seminar deck
- Source PDF: `10321972.pdf`
- Workspace: `out/gamma/`
- Paper title: `GAMMA: Automating the HW Mapping of DNN Models on Accelerators via Genetic Algorithm`
- Authors: `Sheng-Chun Kao` and `Tushar Krishna`
- Venue/date: `ICCAD '20`, November 2-5, 2020

Artifact Progress:
- [x] Extract paper text to `notes/source.txt`
- [x] Recover likely visuals and write `notes/asset-manifest.md`
- [x] Write `notes/brief.md` from the paper text and manifest
- [x] Write `notes/slide-map.md` with evidence and archetypes

## Problem

GAMMA studies compile-time HW mapping for DNN accelerators. The mapping combines three coupled choices:

- parallelization strategy
- computation order
- tile sizes

The paper's core argument is that these choices dominate accelerator efficiency, but no fixed mapping works well for every layer. A mapper therefore needs to search per-layer mappings under strict PE and buffer constraints.

## Motivation and Assumptions

- Mapping materially changes hardware outcomes even when the DNN layer and accelerator are fixed.
  - Figure 2 samples `10K` valid mappings for one VGG16 layer and shows orders-of-magnitude variation in latency and energy.
- The search space is too large for brute force.
  - For the second layer of VGG16, a 1-level mapper is `O(10^12) = O(10^9 x 6! x 6)`.
  - Allowing three levels of parallelism expands this to `O(10^36)`.
- Many generic optimization methods assume fixed-length inputs, which means they cannot naturally search variable numbers of parallelism levels.
- Many candidate mappings are invalid under hardware constraints because tile choices can exceed the available `SL` or `SG` buffers.
- The paper assumes hardware resources are fixed at design time, while the mapping is configurable at compile time.
- The paper also assumes an accurate analytical evaluator exists.
  - GAMMA uses `MAESTRO` as the cost model for latency, energy, power, and related statistics.

## Main Idea

GAMMA turns HW mapping into a domain-specific genetic search problem that can span the full map space instead of a restricted subset.

- A flexible genome encodes:
  - the parallel dimension
  - the computation order
  - the tile size on each dimension
  - the number of parallelism levels
- New operators let the search move across variable-depth mappings:
  - `reorder`
  - `growth`
  - `aging`
- A closed loop with `MAESTRO` evaluates each generation and rejects invalid mappings with a large penalty.

The paper's thesis is not only that GA is a useful optimizer, but that a mapping-specific representation plus mapping-specific operators are what make full-space search practical.

## Method Components

### 1. Mapping Representation

- A 1-level mapper is encoded as `7` pairs of genes.
- Each pair contains:
  - one tensor dimension label such as `K`, `C`, `Y`, `X`, `R`, or `S`
  - one tile size
- The pair order represents computation order.
- The first gene pair marks the spatially parallelized dimension.
- Multi-level mappings concatenate mapper levels, so the genome length varies with the number of levels.

### 2. Decoding to the Cost Model

- GAMMA decodes the first gene pair of each level as `SpatialMap`.
- The remaining gene pairs become `TemporalMap`.
- Each level maps to a `Cluster` in `MAESTRO`.
- This lets one representation cover fixed 2D arrays, flexible 2D arrays, and scale-out 2D systems.

### 3. Evolution Operators

- Standard operators:
  - crossover on tile sizes
  - mutation of parallel dimension
  - mutation of tile size
- GAMMA-specific operators:
  - `reorder`: swap two gene pairs to change computation order
  - `growth`: append a new randomly initialized level
  - `aging`: remove the tail level

These operators are the mechanism that lets GAMMA search `1`, `2`, or `3` levels of parallelism instead of keeping the depth fixed in advance.

### 4. Constraint-Aware Evaluation

- Objectives can be latency, energy, power, area, `EDP`, or combinations.
- The environment decodes every genome in a generation into `MAESTRO` input.
- If a mapping violates hardware constraints, its fitness is set to negative infinity.
- This makes valid-solution discovery part of the search problem, not a post-filter.

## Evaluation Setup

### Models

- `VGG16`
- `MobileNet-V2`
- `ResNet-18`
- `ResNet-50`
- `MnasNet`

### Hardware Budgets

- Edge platform:
  - `168` PEs
  - `512B` local scratchpad per PE
  - `108KB` global scratchpad
- Cloud platform:
  - `65,536` PEs
  - `4MiB` local scratchpad per PE
  - `24MiB` global scratchpad

### Target Systems

- `S1`: fixed 2D PE array with fixed aspect ratio and `2` levels of parallelism
- `S2`: flexible 2D PE array with `1` or `2` levels of parallelism
- `S3`: scale-out 2D accelerator with `2` or `3` levels of parallelism

### Baselines

- Generic optimizers from `Nevergrad`:
  - `RS`
  - `GA`
  - `DE`
  - `(1+lambda)-ES`
  - `CMA-ES`
  - `TBPSA`
  - `PSO`
  - `pPortfolio`
- Fixed dataflows:
  - `NVDLA-like`
  - `Eyeriss-like`
  - `ShiDianNao-like`

### Search Budget

- Every method is capped at `10K` samples.
- GAMMA uses population `200`, generations `50`, and `0.5` rates for mutation, crossover, and the other evolution functions.

## Quantitative Results

### Why the Search Problem Is Hard

- Figure 2 shows several orders of variation in hardware performance from random valid mappings on the same VGG16 layer.
- Random Search often fails to find any valid solution within `10K` samples under tight constraints.

### Main Latency Results

- `S1`:
  - GAMMA finds `224x` to `440x` lower latency on Edge.
  - GAMMA finds `153x` to `1.3E+7x` lower latency on Cloud.
- `S2`:
  - GAMMA finds `209x` to `1,035x` lower latency on Edge.
  - GAMMA finds `337x` to `7.1E+5x` lower latency on Cloud.
- `S3`:
  - GAMMA finds `241x` to `644x` lower latency on Edge.
  - GAMMA finds `657x` to `1.2E+5x` lower latency on Cloud.

### Energy Results

- On `S2`, GAMMA finds:
  - `11x` to `36x` less energy on Edge
  - `2x` to `42x` less energy on Cloud

### Cross-Model Results

- Across models and platforms, the paper reports:
  - `5x` to `1.2E+5x` lower latency
  - `2x` to `1.6E+4x` lower energy
- On `S3` against the best fixed mapping from Table 5:
  - MobileNet-V2: `7.5x` Edge / `5.0x` Cloud latency, `6.3x` Edge / `2.0x` Cloud energy
  - MnasNet: `10.2x` / `29.0x` latency, `7.4x` / `2.1x` energy
  - ShuffleNet: `7.5x` / `18.4x` latency, `9.6x` / `2.2x` energy
  - ResNet50: `20.2x` / `75.8x` latency, `29.7x` / `1.9x` energy

### Interpretable Mapping Behavior

- Figure 7 shows the learned mappings track layer shape:
  - early ResNet-18 layer: `Y`-dominant parallelism
  - medium layer: three-level mapping across `Y`, `K`, and `C`
  - late layer: `C` at `L2` and `K` at `L1`

This matters because the learned patterns are not arbitrary; they align with the heuristics that hand-designed dataflows exploit, while still improving over fixed rules.

### Two-Stage Inter-Layer Optimization

- In a pipelined `S3` deployment:
  - ResNet-18 power drops by `95%`
  - ResNet-18 energy drops by `58%`
  - VGG16 power drops by `99%`
  - VGG16 energy drops by `78%`
- Table 6 identifies layer `2` as the ResNet-18 bottleneck in the latency-first pass.

## Strongest Visual Evidence

- `Figure 2`
  - best motivation figure for why mapping dominates outcomes
- `Figures 3 and 4`
  - clearest explanation of the genome and decode path
- `Figure 5`
  - best single overview for the overall GAMMA loop and operator set
- `Figure 6`
  - core evaluation evidence, but dense and likely needs crop or split
- `Figure 7`
  - best bridge from quantitative win to mechanism
- `Table 5`
  - strongest end-to-end evidence across models and platforms
- `Figures 9a and 9b`
  - cleanest compact evidence for sample efficiency after splitting the original combined crop
- `Table 6`
  - strongest evidence that GAMMA extends beyond one-shot layer mapping

## Deck-Level Claims

- Mapping is a first-order accelerator design variable, not a small compile-time tuning detail.
- The real difficulty is the flexible, constrained map space rather than merely picking another optimizer.
- GAMMA's key contribution is a representation and operator set that can search variable-depth mappings end to end.
- The gains are largest when the accelerator exposes more mapping flexibility, which is exactly where generic baselines break down.
- The method remains interpretable enough to recover layer-shape-aware mappings and to support a second-stage pipeline optimization.
