# Tokencake: A KV-Cache-centric Serving Framework for LLM-based Multi-Agent Applications Asset Manifest

Artifact Progress:
- [x] Extract paper text to `notes/source.txt`
- [x] Recover likely visuals and write `notes/assets.json`
- [x] Render `notes/asset-manifest.md` from `notes/assets.json`

Scenario: en paper-reading deck.
Extraction status: assets-registered

Source text: `out/tokencake/notes/source.txt` via `pdftotext-layout`.
Pages: `13`

## Figure Assets

### Figure 1
- Asset ID: `tokencake-fig01-workloads`
- Source file: `tokencake.pdf`
- Page: `1`
- BBox: `[314.000, 194.000, 552.000, 340.000]`
- Capture kind: `cropped-composite-pdf`
- Primary output: `out/tokencake/assets/tokencake-fig01-workloads.pdf`
- Dimensions: 238.0 x 146.0 (ar=1.6301)
- Caption: Example LLM-based multi-agent applications, showing specialized agents and external function calls.
- Section hint: 1 Introduction
- Extraction quality: high
- Candidate roles: motivation, workload-example
- Notes: Tighter composite crop covering the two-panel workload diagram without surrounding paper text.

### Figure 2
- Asset ID: `tokencake-fig02-space-contention`
- Source file: `tokencake.pdf`
- Page: `2`
- BBox: `[53.722, 74.904, 294.276, 211.868]`
- Capture kind: `cropped-composite-pdf`
- Primary output: `out/tokencake/assets/tokencake-fig02-space-contention.pdf`
- Dimensions: 240.554 x 136.964 (ar=1.7563)
- Caption: The space contention problem: critical inversions are frequent and non-critical agents can hold KV-cache blocks.
- Section hint: 2 Background and Motivation
- Extraction quality: high
- Candidate roles: motivation, pathology
- Notes: Composite crop of both subpanels for the space-contention evidence.

### Figure 3
- Asset ID: `tokencake-fig03-time-underutilization`
- Source file: `tokencake.pdf`
- Page: `2`
- BBox: `[317.677, 74.904, 558.003, 211.868]`
- Capture kind: `cropped-composite-pdf`
- Primary output: `out/tokencake/assets/tokencake-fig03-time-underutilization.pdf`
- Dimensions: 240.326 x 136.964 (ar=1.7547)
- Caption: The time underutilization problem: stalled agents leave idle KV-cache blocks in GPU memory during function calls.
- Section hint: 2 Background and Motivation
- Extraction quality: high
- Candidate roles: motivation, pathology
- Notes: Composite crop of both subpanels for the time-underutilization evidence.

### Figure 4
- Asset ID: `tokencake-fig04-overview`
- Source file: `tokencake.pdf`
- Page: `3`
- BBox: `[322.231, 76.325, 553.716, 228.460]`
- Capture kind: `native-raster`
- Primary output: `out/tokencake/assets/tokencake-fig04-overview.jpeg`
- Dimensions: 1940 x 1275 (ar=1.5216)
- Caption: Tokencake architecture overview with the Frontend API, Space Scheduler, and Time Scheduler.
- Section hint: 3 Overview
- Extraction quality: high
- Candidate roles: design-overview, thesis
- Notes: Primary architecture figure for the overall system story.

### Figure 6
- Asset ID: `tokencake-fig06-coordination`
- Source file: `tokencake.pdf`
- Page: `4`
- BBox: `[322.231, 76.285, 553.716, 153.808]`
- Capture kind: `native-raster`
- Primary output: `out/tokencake/assets/tokencake-fig06-coordination.jpeg`
- Dimensions: 2135 x 715 (ar=2.986)
- Caption: Coordination between the Space Scheduler and the Time Scheduler.
- Section hint: 3.2 Coordination between Space and Time Schedulers
- Extraction quality: medium
- Candidate roles: design-detail, scheduler-coordination
- Notes: Useful companion asset when the overview slide also needs the control interaction.

### Figure 7
- Asset ID: `tokencake-fig07-time-lifecycle`
- Source file: `tokencake.pdf`
- Page: `5`
- BBox: `[322.231, 243.898, 553.716, 359.220]`
- Capture kind: `native-raster`
- Primary output: `out/tokencake/assets/tokencake-fig07-time-lifecycle.jpeg`
- Dimensions: 1375 x 685 (ar=2.0073)
- Caption: Lifecycle of the Time Scheduler's offload and predictive upload mechanism.
- Section hint: 4.1 Event-Driven Offload and Predictive Upload
- Extraction quality: high
- Candidate roles: design-detail, time-scheduler
- Notes: Main mechanism figure for the time scheduler.

### Figure 8
- Asset ID: `tokencake-fig08-space-feedback`
- Source file: `tokencake.pdf`
- Page: `7`
- BBox: `[58.340, 76.276, 289.697, 214.825]`
- Capture kind: `native-raster`
- Primary output: `out/tokencake/assets/tokencake-fig08-space-feedback.jpeg`
- Dimensions: 1745 x 1045 (ar=1.6699)
- Caption: The Space Scheduler's dynamic memory partitioning feedback loop.
- Section hint: 5.1 Runtime Control with Dynamic Memory Partitioning
- Extraction quality: high
- Candidate roles: design-detail, space-scheduler
- Notes: Main mechanism figure for the space scheduler.

### Figure 9
- Asset ID: `tokencake-fig09-latency`
- Source file: `tokencake.pdf`
- Page: `10`
- BBox: `[63.279, 80.977, 548.734, 306.645]`
- Capture kind: `native-raster`
- Primary output: `out/tokencake/assets/tokencake-fig09-latency.jpeg`
- Dimensions: 5279 x 2454 (ar=2.1512)
- Caption: End-to-end latency comparison of Tokencake, vLLM, and LightLLM across applications, models, and request rates.
- Section hint: 7.2 Performance Results
- Extraction quality: high
- Candidate roles: evaluation, main-result
- Notes: Primary aggregate performance result.

### Figure 10
- Asset ID: `tokencake-fig10-utilization`
- Source file: `tokencake.pdf`
- Page: `10`
- BBox: `[58.351, 515.256, 289.687, 605.341]`
- Capture kind: `native-raster`
- Primary output: `out/tokencake/assets/tokencake-fig10-utilization.jpeg`
- Dimensions: 3495 x 1361 (ar=2.568)
- Caption: GPU KV-cache utilization under varying load.
- Section hint: 7.2 Performance Results
- Extraction quality: medium
- Candidate roles: evaluation, utilization
- Notes: Supports the argument that latency gains come from better memory use.

### Figure 11
- Asset ID: `tokencake-fig11-agent-latency`
- Source file: `tokencake.pdf`
- Page: `11`
- BBox: `[58.276, 160.696, 289.761, 390.385]`
- Capture kind: `native-raster`
- Primary output: `out/tokencake/assets/tokencake-fig11-agent-latency.jpeg`
- Dimensions: 4126 x 4094 (ar=1.0078)
- Caption: Average latency by agent type.
- Section hint: 7.3 Agent Analysis
- Extraction quality: medium
- Candidate roles: evaluation, agent-analysis
- Notes: Per-agent evidence that Tokencake improves individual stages.

### Figure 12
- Asset ID: `tokencake-fig12-abnormal-agents`
- Source file: `tokencake.pdf`
- Page: `11`
- BBox: `[322.283, 76.276, 553.664, 181.756]`
- Capture kind: `native-raster`
- Primary output: `out/tokencake/assets/tokencake-fig12-abnormal-agents.jpeg`
- Dimensions: 3501 x 1596 (ar=2.1936)
- Caption: Reduction in the count of abnormal agents, defined as agents whose execution time exceeds 1.5x the average for their type.
- Section hint: 7.3 Agent Analysis
- Extraction quality: high
- Candidate roles: evaluation, critical-path
- Notes: Compact evidence that the scheduler reduces harmful outliers on the critical path.

### Figure 13
- Asset ID: `tokencake-fig13-offload-tradeoff`
- Source file: `tokencake.pdf`
- Page: `11`
- BBox: `[322.231, 383.286, 553.716, 487.212]`
- Capture kind: `native-raster`
- Primary output: `out/tokencake/assets/tokencake-fig13-offload-tradeoff.jpeg`
- Dimensions: 3497 x 1570 (ar=2.2274)
- Caption: Time tradeoff between KV-cache reuse through offload/upload and full recomputation.
- Section hint: 7.4 Analysis of the Offloading Tradeoff
- Extraction quality: high
- Candidate roles: evaluation, tradeoff
- Notes: Shows why offloading is worthwhile for stalled agents.

### Figure 14
- Asset ID: `tokencake-fig14-overhead-mitigation`
- Source file: `tokencake.pdf`
- Page: `12`
- BBox: `[58.276, 76.323, 289.761, 211.356]`
- Capture kind: `native-raster`
- Primary output: `out/tokencake/assets/tokencake-fig14-overhead-mitigation.jpeg`
- Dimensions: 3600 x 2100 (ar=1.7143)
- Caption: Overhead mitigation for KV-cache offload and upload operations.
- Section hint: 7.4 Analysis of the Offloading Tradeoff
- Extraction quality: high
- Candidate roles: evaluation, overhead
- Notes: Microbenchmark showing why Tokencake's offload optimizations matter.
