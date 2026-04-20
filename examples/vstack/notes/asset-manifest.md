# vStack: A Heterogeneous HBM-PIM Architecture and Runtime for Efficient LLM Inference Asset Manifest

Artifact Progress:
- [x] Extract paper text to `notes/source.txt`
- [x] Recover likely visuals and write `notes/assets.json`
- [x] Render `notes/asset-manifest.md` from `notes/assets.json`

Scenario: zh paper-reading deck.
Extraction status: source-extracted

Source text: `examples/vstack/notes/source.txt` via `pdftotext-layout`.
Pages: `13`

## Figure Assets

### Figure 1
- Asset ID: `fig01-workflow`
- Source file: `vstack.pdf`
- Page: `2`
- BBox: `[317.955, 83.686, 558.155, 164.277]`
- Capture kind: `fallback-raster`
- Primary output: `examples/vstack/assets/vstack-fig01-workflow.png`
- Dimensions: 1002 x 337 (ar=2.9733)
- Caption: Figure 1: LLM inference workflow. Prefill processes the full prompt through compute-heavy projection and feed-forward layers. Decode generates one token per step, rereading the accumulated KV cache; as the context grows, attention shifts from compute-bound to memory-bound.
- Section hint: Background and Motivation
- Extraction quality: high
- Candidate roles: motivation, workflow, background

### Figure 2
- Asset ID: `fig02-baselines`
- Source file: `vstack.pdf`
- Page: `3`
- BBox: `[56.201, 83.687, 291.615, 213.314]`
- Capture kind: `fallback-raster`
- Primary output: `examples/vstack/assets/vstack-fig02-baselines.png`
- Dimensions: 982 x 541 (ar=1.8152)
- Caption: Figure 2: Baseline HBM-PIM organizations. Uniform equips every layer with PIM and halves effective density; dedicated-PIM preserves density elsewhere but reduces GPU-visible HBM bandwidth.
- Section hint: Background and Motivation
- Extraction quality: high
- Candidate roles: motivation, baseline, comparison

### Figure 3
- Asset ID: `fig03-architecture`
- Source file: `vstack.pdf`
- Page: `4`
- BBox: `[79.020, 83.687, 532.958, 337.910]`
- Capture kind: `fallback-raster`
- Primary output: `examples/vstack/assets/vstack-fig03-architecture.png`
- Dimensions: 1892 x 1060 (ar=1.7849)
- Caption: Figure 3: vStack system architecture. Each stack combines dense capacity layers, PIM-enabled compute layers, and a logic base die that coordinates stack-local movement and attention-side communication.
- Section hint: Overview of vStack
- Extraction quality: high
- Candidate roles: overview, architecture, method

### Figure 4
- Asset ID: `fig04-stack-design`
- Source file: `vstack.pdf`
- Page: `4`
- BBox: `[65.811, 377.832, 281.985, 509.900]`
- Capture kind: `fallback-raster`
- Primary output: `examples/vstack/assets/vstack-fig04-stack-design.png`
- Dimensions: 901 x 551 (ar=1.6352)
- Caption: Figure 4: vStack design. Each stack combines dense capacity layers, PIM-enabled compute layers, and a logic base die that manages stack-local movement and attention coordination.
- Section hint: vStack Hardware Design
- Extraction quality: high
- Candidate roles: overview, stack-organization, method

### Figure 5
- Asset ID: `fig05-kv-layout`
- Source file: `vstack.pdf`
- Page: `6`
- BBox: `[317.955, 83.686, 558.165, 207.228]`
- Capture kind: `fallback-raster`
- Primary output: `examples/vstack/assets/vstack-fig05-kv-layout.png`
- Dimensions: 1002 x 516 (ar=1.9419)
- Caption: Figure 5: Key/Value placement in compute-layer PIM banks. Token-major Keys and dim-head Values eliminate cross-bank reduction in both attention phases.
- Section hint: KV-Aware Data Placement
- Extraction quality: high
- Candidate roles: mechanism, layout, method

### Figure 6
- Asset ID: `fig06-lifecycle`
- Source file: `vstack.pdf`
- Page: `7`
- BBox: `[53.798, 83.685, 294.003, 195.480]`
- Capture kind: `fallback-raster`
- Primary output: `examples/vstack/assets/vstack-fig06-lifecycle.png`
- Dimensions: 1002 x 467 (ar=2.1456)
- Caption: Figure 6: KV block lifecycle. Active blocks reside in compute layers; demotion quantizes FP16 to K8V4 and scatters pages to capacity layers; promotion reverses the path.
- Section hint: Runtime Optimizations
- Extraction quality: high
- Candidate roles: mechanism, lifecycle, runtime

### Figure 7
- Asset ID: `fig07-workloads`
- Source file: `vstack.pdf`
- Page: `8`
- BBox: `[53.336, 558.981, 294.045, 682.441]`
- Capture kind: `fallback-raster`
- Primary output: `examples/vstack/assets/vstack-fig07-workloads.png`
- Dimensions: 1004 x 515 (ar=1.9495)
- Caption: Figure 7: Prompt and generation length distributions across four traces.
- Section hint: Experimental Methodology
- Extraction quality: high
- Candidate roles: evaluation-setup, workload, trace

### Figure 8
- Asset ID: `fig08-throughput`
- Source file: `vstack.pdf`
- Page: `9`
- BBox: `[53.798, 83.686, 558.204, 202.309]`
- Capture kind: `fallback-raster`
- Primary output: `examples/vstack/assets/vstack-fig08-throughput.png`
- Dimensions: 2102 x 495 (ar=4.2465)
- Caption: Figure 8: Token throughput normalized to AttAcc. vStack outperforms AttAcc on every pair while preserving large-model capacity. Uniform is unavailable for GPT-175B due to OOM.
- Section hint: Evaluation
- Extraction quality: high
- Candidate roles: result, throughput, main-evidence

### Figure 9
- Asset ID: `fig09-latency`
- Source file: `vstack.pdf`
- Page: `9`
- BBox: `[53.798, 238.921, 558.442, 358.815]`
- Capture kind: `fallback-raster`
- Primary output: `examples/vstack/assets/vstack-fig09-latency.png`
- Dimensions: 2103 x 501 (ar=4.1976)
- Caption: Figure 9: Normalized p50 end-to-end latency vs. QPS. vStack stays flat while AttAcc diverges under load. Uniform is unavailable for GPT-175B due to OOM.
- Section hint: Evaluation
- Extraction quality: high
- Candidate roles: result, latency, main-evidence

### Figure 10
- Asset ID: `fig10-energy`
- Source file: `vstack.pdf`
- Page: `10`
- BBox: `[53.798, 83.686, 294.040, 157.956]`
- Capture kind: `fallback-raster`
- Primary output: `examples/vstack/assets/vstack-fig10-energy.png`
- Dimensions: 1002 x 311 (ar=3.2219)
- Caption: Figure 10: Normalized energy breakdown per token for Mistral-Devstral2-123B at QPS = 32 on traceA and traceB.
- Section hint: Evaluation
- Extraction quality: high
- Candidate roles: result, energy, efficiency

### Figure 11
- Asset ID: `fig11-ttft-tbt`
- Source file: `vstack.pdf`
- Page: `11`
- BBox: `[53.798, 83.435, 558.430, 203.411]`
- Capture kind: `fallback-raster`
- Primary output: `examples/vstack/assets/vstack-fig11-ttft-tbt.png`
- Dimensions: 2103 x 501 (ar=4.1976)
- Caption: Figure 11: Normalized p50 TTFT and TBT vs. QPS for Devstral-123B and Qwen3-32B. TTFT dominates the latency gap.
- Section hint: Evaluation
- Extraction quality: high
- Candidate roles: result, latency-breakdown, main-evidence

### Figure 12
- Asset ID: `fig12-ablation`
- Source file: `vstack.pdf`
- Page: `11`
- BBox: `[42.864, 216.378, 294.042, 333.106]`
- Capture kind: `fallback-raster`
- Primary output: `examples/vstack/assets/vstack-fig12-ablation.png`
- Dimensions: 1048 x 487 (ar=2.152)
- Caption: Figure 12: Cumulative throughput contribution of each vStack component for Devstral-123B at QPS = 32 on traceA. The largest gain comes from KV-aware layout.
- Section hint: Ablation and Discussion
- Extraction quality: high
- Candidate roles: result, ablation, discussion
