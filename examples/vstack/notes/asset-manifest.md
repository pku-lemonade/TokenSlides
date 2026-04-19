# vStack: A Heterogeneous HBM-PIM Architecture and Runtime for Efficient LLM Inference Asset Manifest

Artifact Progress:
- [x] Extract paper text to `notes/source.txt`
- [x] Recover likely visuals and write `notes/assets.json`
- [x] Render `notes/asset-manifest.md` from `notes/assets.json`

Scenario: zh paper-reading deck.
Extraction status: assets-registered

Source text: `out/vstack/notes/source.txt` via `pdftotext-layout`.
Pages: `13`

## Figure Assets

### Figure 1
- Asset ID: `fig01-workflow`
- Source file: `/Users/youwei/Downloads/slides/vstack.pdf`
- Page: `2`
- BBox: `[317.955, 83.686, 558.155, 164.277]`
- Capture kind: `cropped-vector-pdf`
- Primary output: `out/vstack/assets/vstack-fig01-workflow.pdf`
- Dimensions: 240.2 x 80.591 (ar=2.9805)
- Caption: Figure 1: LLM inference workflow. Prefill processes the full prompt through compute-heavy projection and feed-forward layers. Decode generates one token per step, rereading the accumulated KV cache; as the context grows, attention shifts from compute-bound to memory-bound.
- Section hint: Background and Motivation
- Extraction quality: high
- Candidate roles: motivation, workflow, background

### Figure 2
- Asset ID: `fig02-baselines`
- Source file: `/Users/youwei/Downloads/slides/vstack.pdf`
- Page: `3`
- BBox: `[56.201, 83.687, 291.615, 213.314]`
- Capture kind: `cropped-vector-pdf`
- Primary output: `out/vstack/assets/vstack-fig02-baselines.pdf`
- Dimensions: 235.414 x 129.627 (ar=1.8161)
- Caption: Figure 2: Baseline HBM-PIM organizations. Uniform equips every layer with PIM and halves effective density; dedicated-PIM preserves density elsewhere but reduces GPU-visible HBM bandwidth.
- Section hint: Background and Motivation
- Extraction quality: high
- Candidate roles: motivation, baseline, comparison

### Figure 3
- Asset ID: `fig03-architecture`
- Source file: `/Users/youwei/Downloads/slides/vstack.pdf`
- Page: `4`
- BBox: `[79.020, 83.687, 532.958, 337.910]`
- Capture kind: `cropped-vector-pdf`
- Primary output: `out/vstack/assets/vstack-fig03-architecture.pdf`
- Dimensions: 453.938 x 254.223 (ar=1.7856)
- Caption: Figure 3: vStack system architecture. Each stack combines dense capacity layers, PIM-enabled compute layers, and a logic base die that coordinates stack-local movement and attention-side communication.
- Section hint: Overview of vStack
- Extraction quality: high
- Candidate roles: overview, architecture, method

### Figure 4
- Asset ID: `fig04-stack-design`
- Source file: `/Users/youwei/Downloads/slides/vstack.pdf`
- Page: `4`
- BBox: `[65.811, 377.832, 281.985, 509.900]`
- Capture kind: `cropped-vector-pdf`
- Primary output: `out/vstack/assets/vstack-fig04-stack-design.pdf`
- Dimensions: 216.174 x 132.069 (ar=1.6368)
- Caption: Figure 4: vStack design. Each stack combines dense capacity layers, PIM-enabled compute layers, and a logic base die that manages stack-local movement and attention coordination.
- Section hint: vStack Hardware Design
- Extraction quality: high
- Candidate roles: overview, stack-organization, method

### Figure 5
- Asset ID: `fig05-kv-layout`
- Source file: `/Users/youwei/Downloads/slides/vstack.pdf`
- Page: `6`
- BBox: `[317.955, 83.686, 558.165, 207.228]`
- Capture kind: `cropped-vector-pdf`
- Primary output: `out/vstack/assets/vstack-fig05-kv-layout.pdf`
- Dimensions: 240.21 x 123.542 (ar=1.9444)
- Caption: Figure 5: Key/Value placement in compute-layer PIM banks. Token-major Keys and dim-head Values eliminate cross-bank reduction in both attention phases.
- Section hint: KV-Aware Data Placement
- Extraction quality: high
- Candidate roles: mechanism, layout, method

### Figure 6
- Asset ID: `fig06-lifecycle`
- Source file: `/Users/youwei/Downloads/slides/vstack.pdf`
- Page: `7`
- BBox: `[53.798, 83.685, 294.003, 195.480]`
- Capture kind: `cropped-vector-pdf`
- Primary output: `out/vstack/assets/vstack-fig06-lifecycle.pdf`
- Dimensions: 240.205 x 111.796 (ar=2.1486)
- Caption: Figure 6: KV block lifecycle. Active blocks reside in compute layers; demotion quantizes FP16 to K8V4 and scatters pages to capacity layers; promotion reverses the path.
- Section hint: Runtime Optimizations
- Extraction quality: high
- Candidate roles: mechanism, lifecycle, runtime

### Figure 7
- Asset ID: `fig07-workloads`
- Source file: `/Users/youwei/Downloads/slides/vstack.pdf`
- Page: `8`
- BBox: `[53.336, 558.981, 294.045, 682.441]`
- Capture kind: `cropped-vector-pdf`
- Primary output: `out/vstack/assets/vstack-fig07-workloads.pdf`
- Dimensions: 240.709 x 123.46 (ar=1.9497)
- Caption: Figure 7: Prompt and generation length distributions across four traces.
- Section hint: Experimental Methodology
- Extraction quality: high
- Candidate roles: evaluation-setup, workload, trace

### Figure 8
- Asset ID: `fig08-throughput`
- Source file: `/Users/youwei/Downloads/slides/vstack.pdf`
- Page: `9`
- BBox: `[53.798, 83.686, 558.204, 202.309]`
- Capture kind: `cropped-vector-pdf`
- Primary output: `out/vstack/assets/vstack-fig08-throughput.pdf`
- Dimensions: 504.406 x 118.623 (ar=4.2522)
- Caption: Figure 8: Token throughput normalized to AttAcc. vStack outperforms AttAcc on every pair while preserving large-model capacity. Uniform is unavailable for GPT-175B due to OOM.
- Section hint: Evaluation
- Extraction quality: high
- Candidate roles: result, throughput, main-evidence

### Figure 9
- Asset ID: `fig09-latency`
- Source file: `/Users/youwei/Downloads/slides/vstack.pdf`
- Page: `9`
- BBox: `[53.798, 238.921, 558.442, 358.815]`
- Capture kind: `cropped-vector-pdf`
- Primary output: `out/vstack/assets/vstack-fig09-latency.pdf`
- Dimensions: 504.644 x 119.894 (ar=4.2091)
- Caption: Figure 9: Normalized p50 end-to-end latency vs. QPS. vStack stays flat while AttAcc diverges under load. Uniform is unavailable for GPT-175B due to OOM.
- Section hint: Evaluation
- Extraction quality: high
- Candidate roles: result, latency, main-evidence

### Figure 10
- Asset ID: `fig10-energy`
- Source file: `/Users/youwei/Downloads/slides/vstack.pdf`
- Page: `10`
- BBox: `[53.798, 83.686, 294.040, 157.956]`
- Capture kind: `cropped-vector-pdf`
- Primary output: `out/vstack/assets/vstack-fig10-energy.pdf`
- Dimensions: 240.242 x 74.27 (ar=3.2347)
- Caption: Figure 10: Normalized energy breakdown per token for Mistral-Devstral2-123B at QPS = 32 on traceA and traceB.
- Section hint: Evaluation
- Extraction quality: high
- Candidate roles: result, energy, efficiency

### Figure 11
- Asset ID: `fig11-ttft-tbt`
- Source file: `/Users/youwei/Downloads/slides/vstack.pdf`
- Page: `11`
- BBox: `[53.798, 83.435, 558.430, 203.411]`
- Capture kind: `cropped-vector-pdf`
- Primary output: `out/vstack/assets/vstack-fig11-ttft-tbt.pdf`
- Dimensions: 504.632 x 119.976 (ar=4.2061)
- Caption: Figure 11: Normalized p50 TTFT and TBT vs. QPS for Devstral-123B and Qwen3-32B. TTFT dominates the latency gap.
- Section hint: Evaluation
- Extraction quality: high
- Candidate roles: result, latency-breakdown, main-evidence

### Figure 12
- Asset ID: `fig12-ablation`
- Source file: `/Users/youwei/Downloads/slides/vstack.pdf`
- Page: `11`
- BBox: `[42.864, 216.378, 294.042, 333.106]`
- Capture kind: `cropped-vector-pdf`
- Primary output: `out/vstack/assets/vstack-fig12-ablation.pdf`
- Dimensions: 251.178 x 116.728 (ar=2.1518)
- Caption: Figure 12: Cumulative throughput contribution of each vStack component for Devstral-123B at QPS = 32 on traceA. The largest gain comes from KV-aware layout.
- Section hint: Ablation and Discussion
- Extraction quality: high
- Candidate roles: result, ablation, discussion
