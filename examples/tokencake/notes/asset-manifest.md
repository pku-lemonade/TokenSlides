# Tokencake: A KV-Cache-centric Serving Framework for LLM-based Multi-Agent Applications Asset Manifest

Artifact Progress:
- [x] Extract paper text to `notes/source.txt`
- [x] Recover likely visuals and write `notes/assets.json`
- [x] Render `notes/asset-manifest.md` from `notes/assets.json`

Scenario: en paper-reading deck.
Extraction status: source-extracted

Source text: `examples/tokencake/notes/source.txt` via `pdftotext-layout`.
Pages: `13`

## Figure Assets

### Figure 1a: Multi-agent Coding
- Asset ID: `fig1a-coding`
- Source file: `tokencake.pdf`
- Page: `1`
- BBox: `[324.417, 198.747, 433.829, 321.466]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig1a-multi-agent-coding.jpeg`
- Dimensions: 2220 x 2490 (ar=0.8916)
- Caption: Multi-agent coding application with collaborating programmer, checker, reviewer, and reviser agents.
- Section hint: Introduction
- Extraction quality: high
- Candidate roles: motivation, workload-example

### Figure 1b: Deep Research
- Asset ID: `fig1b-deep-research`
- Source file: `tokencake.pdf`
- Page: `1`
- BBox: `[442.128, 196.440, 551.540, 321.448]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig1b-deep-research.jpeg`
- Dimensions: 2280 x 2605 (ar=0.8752)
- Caption: Deep Research application with planner, searcher, summary, reflector, and generation stages.
- Section hint: Introduction
- Extraction quality: high
- Candidate roles: motivation, workload-example

### Figure 2: Space Contention
- Asset ID: `fig2-space-contention`
- Source file: `tokencake.pdf`
- Page: `2`
- BBox: `[53.722, 74.904, 294.276, 211.868]`
- Capture kind: `cropped-composite-pdf`
- Primary output: `examples/tokencake/assets/fig2-space-contention.pdf`
- Dimensions: 240.554 x 136.964 (ar=1.7563)
- Caption: Critical-path agents get preempted when non-critical agents occupy KV-cache space first.
- Section hint: Introduction
- Extraction quality: high
- Candidate roles: motivation, pathology-evidence

### Figure 2a: Contention Analysis
- Asset ID: `fig2a-space-contention-analysis`
- Source file: `tokencake.pdf`
- Page: `2`
- BBox: `[56.905, 74.904, 166.317, 184.316]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig2a-space-contention-analysis.jpeg`
- Dimensions: 1200 x 1200 (ar=1.0)
- Caption: Preemption events accumulate steadily in the Code-Writer workload.
- Section hint: Introduction
- Extraction quality: high
- Candidate roles: motivation, pathology-evidence

### Figure 2b: Critical Inversion Diagram
- Asset ID: `fig2b-space-contention-diagram`
- Source file: `tokencake.pdf`
- Page: `2`
- BBox: `[180.984, 83.534, 291.872, 185.061]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig2b-space-contention-diagram.jpeg`
- Dimensions: 770 x 705 (ar=1.0922)
- Caption: A non-critical agent can occupy memory first and preempt a critical-path agent.
- Section hint: Introduction
- Extraction quality: high
- Candidate roles: motivation, pathology-evidence

### Figure 3: Time Underutilization
- Asset ID: `fig3-time-underutilization`
- Source file: `tokencake.pdf`
- Page: `2`
- BBox: `[317.677, 74.904, 558.003, 211.868]`
- Capture kind: `cropped-composite-pdf`
- Primary output: `examples/tokencake/assets/fig3-time-underutilization.pdf`
- Dimensions: 240.326 x 136.964 (ar=1.7547)
- Caption: Function-call stalls leave KV-cache blocks idle or force expensive eviction and recomputation.
- Section hint: Introduction
- Extraction quality: high
- Candidate roles: motivation, pathology-evidence

### Figure 3a: Idle KV Blocks
- Asset ID: `fig3a-idle-kv-blocks`
- Source file: `tokencake.pdf`
- Page: `2`
- BBox: `[320.860, 74.904, 430.272, 184.316]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig3a-idle-kv-blocks.jpeg`
- Dimensions: 1200 x 1200 (ar=1.0)
- Caption: Stalled agents can occupy up to 18.5 percent of used GPU KV cache.
- Section hint: Introduction
- Extraction quality: high
- Candidate roles: motivation, pathology-evidence

### Figure 3b: KV-Cache Lifecycle
- Asset ID: `fig3b-kv-cache-lifecycle`
- Source file: `tokencake.pdf`
- Page: `2`
- BBox: `[444.858, 77.202, 555.922, 185.168]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig3b-kv-cache-lifecycle.jpeg`
- Dimensions: 1255 x 1220 (ar=1.0287)
- Caption: During a function call, the system must choose between wasting memory and paying recomputation later.
- Section hint: Introduction
- Extraction quality: high
- Candidate roles: motivation, pathology-evidence

### Figure 4: Tokencake Overview
- Asset ID: `fig4-overview`
- Source file: `tokencake.pdf`
- Page: `3`
- BBox: `[322.231, 76.325, 553.716, 228.460]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig4-overview.jpeg`
- Dimensions: 1940 x 1275 (ar=1.5216)
- Caption: Tokencake combines a frontend API with coordinated space and time schedulers around the KV cache.
- Section hint: Overview
- Extraction quality: high
- Candidate roles: thesis, system-overview

### Figure 5: Frontend API
- Asset ID: `fig5-api`
- Source file: `tokencake.pdf`
- Page: `4`
- BBox: `[69.852, 75.856, 278.195, 175.905]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig5-api.jpeg`
- Dimensions: 4927 x 2366 (ar=2.0824)
- Caption: The frontend expresses a multi-agent workflow as a DAG with staged function nodes.
- Section hint: Frontend API
- Extraction quality: high
- Candidate roles: implementation, frontend-api

### Figure 6: Scheduler Coordination
- Asset ID: `fig6-coordination`
- Source file: `tokencake.pdf`
- Page: `4`
- BBox: `[322.231, 76.285, 553.716, 153.808]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig6-coordination.jpeg`
- Dimensions: 2135 x 715 (ar=2.986)
- Caption: The space scheduler and time scheduler cooperate on reservation, offload, and prefetch decisions.
- Section hint: Overview
- Extraction quality: high
- Candidate roles: mechanism-overview, scheduler-coordination

### Figure 7: Time Scheduler Lifecycle
- Asset ID: `fig7-lifecycle`
- Source file: `tokencake.pdf`
- Page: `5`
- BBox: `[322.231, 243.898, 553.716, 359.220]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig7-lifecycle.jpeg`
- Dimensions: 1375 x 685 (ar=2.0073)
- Caption: The time scheduler analyzes, offloads, predicts completion, and uploads KV cache before resumption.
- Section hint: Time Scheduler
- Extraction quality: high
- Candidate roles: time-scheduler, mechanism-detail

### Figure 8: Space Scheduler Feedback Loop
- Asset ID: `fig8-space-scheduler`
- Source file: `tokencake.pdf`
- Page: `7`
- BBox: `[58.340, 76.276, 289.697, 214.825]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig8-space-scheduler.jpeg`
- Dimensions: 1745 x 1045 (ar=1.6699)
- Caption: The space scheduler updates critical-agent reservations from priority and observed memory pressure.
- Section hint: Space Scheduler
- Extraction quality: high
- Candidate roles: space-scheduler, mechanism-detail

### Figure 10: GPU KV Utilization
- Asset ID: `fig10-gpu-utilization`
- Source file: `tokencake.pdf`
- Page: `10`
- BBox: `[58.351, 515.256, 289.687, 605.341]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig10-gpu-utilization.jpeg`
- Dimensions: 3495 x 1361 (ar=2.568)
- Caption: Tokencake sustains about 86 to 87 percent GPU KV-cache utilization versus roughly 70 to 74 percent for vLLM.
- Section hint: Evaluation
- Extraction quality: high
- Candidate roles: evaluation-support, utilization-evidence

### Figure 9: End-to-End Latency
- Asset ID: `fig9-latency`
- Source file: `tokencake.pdf`
- Page: `10`
- BBox: `[63.279, 80.977, 548.734, 306.645]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig9-latency.jpeg`
- Dimensions: 5279 x 2454 (ar=2.1512)
- Caption: Tokencake scales better with load and cuts end-to-end latency versus vLLM and LightLLM.
- Section hint: Evaluation
- Extraction quality: high
- Candidate roles: evaluation-main, headline-result

### Figure 11: Agent Latency
- Asset ID: `fig11-agent-latency`
- Source file: `tokencake.pdf`
- Page: `11`
- BBox: `[58.276, 160.696, 289.761, 390.385]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig11-agent-latency.jpeg`
- Dimensions: 4126 x 4094 (ar=1.0078)
- Caption: Every agent type runs faster on Tokencake than on the baselines.
- Section hint: Evaluation
- Extraction quality: high
- Candidate roles: evaluation-support, critical-path-evidence

### Figure 12: Abnormal Agents
- Asset ID: `fig12-abnormal-agents`
- Source file: `tokencake.pdf`
- Page: `11`
- BBox: `[322.283, 76.276, 553.664, 181.756]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig12-abnormal-agents.jpeg`
- Dimensions: 3501 x 1596 (ar=2.1936)
- Caption: Tokencake sharply reduces abnormal critical-path agents with unusually long runtimes.
- Section hint: Evaluation
- Extraction quality: high
- Candidate roles: evaluation-support, critical-path-evidence

### Figure 13: Transfer vs Recomputation
- Asset ID: `fig13-offload-vs-recompute`
- Source file: `tokencake.pdf`
- Page: `11`
- BBox: `[322.231, 383.286, 553.716, 487.212]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig13-offload-vs-recompute.jpeg`
- Dimensions: 3497 x 1570 (ar=2.2274)
- Caption: KV-cache transfer is orders of magnitude cheaper than recomputing the same context.
- Section hint: Evaluation
- Extraction quality: high
- Candidate roles: evaluation-support, time-scheduler-evidence

### Figure 14: Overhead Mitigation
- Asset ID: `fig14-overhead-mitigation`
- Source file: `tokencake.pdf`
- Page: `12`
- BBox: `[58.276, 76.323, 289.761, 211.356]`
- Capture kind: `native-raster`
- Primary output: `examples/tokencake/assets/fig14-overhead-mitigation.jpeg`
- Dimensions: 3600 x 2100 (ar=1.7143)
- Caption: CPU block buffering and gradual GPU reservation reduce transfer overhead from seconds to milliseconds.
- Section hint: Evaluation
- Extraction quality: high
- Candidate roles: evaluation-support, overhead-evidence

## Equation Assets

### Equation 1: Duration Blend
- Asset ID: `eq1-duration-blend`
- Source file: `tokencake.pdf`
- Page: `6`
- Section hint: Time Scheduler
- Extraction quality: high
- Candidate roles: time-scheduler, policy-formula
- Equation text: `t_final = alpha * t_req + (1 - alpha) * t_hist`
- Equation context: Blend a developer-provided function-call estimate with historical execution time for predictive upload.

### Transfer-Time Model
- Asset ID: `eq2-transfer-cost`
- Source file: `tokencake.pdf`
- Page: `6`
- Section hint: Time Scheduler
- Extraction quality: high
- Candidate roles: time-scheduler, policy-formula
- Equation text: `T_transfer = T_offload(N_blocks) + T_upload(N_blocks)`
- Equation context: Estimate whether the stall window is long enough to justify offloading the KV cache.

### Static Priority
- Asset ID: `eq3-static-priority`
- Source file: `tokencake.pdf`
- Page: `8`
- Section hint: Space Scheduler
- Extraction quality: high
- Candidate roles: space-scheduler, policy-formula
- Equation text: `priority_static = w_static * node_depth * node_out_degree`
- Equation context: Measure structural importance of an agent inside the DAG.

### Dynamic Priority
- Asset ID: `eq4-dynamic-priority`
- Source file: `tokencake.pdf`
- Page: `8`
- Section hint: Space Scheduler
- Extraction quality: high
- Candidate roles: space-scheduler, policy-formula
- Equation text: `priority_dynamic = time_wait * log(tokens_req / time_wait)`
- Equation context: Blend fairness and short-request preference when ranking waiting agents.
