# Graph.hls Asset Manifest

Artifact Progress:
- [x] Recover likely visuals and write `notes/asset-manifest.md`
- [x] Write `notes/brief.md` from the paper text and manifest
- [x] Write `notes/slide-map.md` with evidence and archetypes

Source PDF: `/Users/youwei/Downloads/GraphyFlow-ISCA26-7.pdf`
Workspace: `out/graph-hls`

## Recovered Assets

### Fig. 1: workflow comparison
- source_file: `/Users/youwei/Downloads/GraphyFlow-ISCA26-7.pdf`
- page: `1`
- bbox: `307,155,563,282`
- capture_kind: `cropped-vector-pdf`
- primary_output: `out/graph-hls/assets/fig1-workflow.pdf`
- preview_output: `out/graph-hls/assets/fig1-workflow-preview.png`
- supports: opening motivation; existing HLS graph frameworks cannot compose optimizations and require repeated hardware emulation to locate bugs
- follow_up: low; crop is already figure-only and readable

### Fig. 2: 32-bit to 16-bit change cascade
- source_file: `/Users/youwei/Downloads/GraphyFlow-ISCA26-7.pdf`
- page: `3`
- bbox: `48,49,300,181`
- capture_kind: `cropped-vector-pdf`
- primary_output: `out/graph-hls/assets/fig2-bitwidth-cascade.pdf`
- preview_output: `out/graph-hls/assets/fig2-bitwidth-cascade-preview.png`
- supports: concrete evidence that a single logical change spreads across constants, packing logic, kernels, URAM logic, and host code
- follow_up: low; good for a full-slide motivation or problem slide

### Fig. 3: Graph.hls overview
- source_file: `/Users/youwei/Downloads/GraphyFlow-ISCA26-7.pdf`
- page: `4`
- bbox: `49,46,563,202`
- capture_kind: `cropped-composite-pdf`
- primary_output: `out/graph-hls/assets/fig3-overview.pdf`
- preview_output: `out/graph-hls/assets/fig3-overview-preview.png`
- supports: thesis slide; Graph.hls combines hierarchical abstraction with GH-Architect and GH-Scope
- follow_up: low; overview can be used directly without extra cleanup

### Fig. 4: hierarchical design abstraction
- source_file: `/Users/youwei/Downloads/GraphyFlow-ISCA26-7.pdf`
- page: `5`
- bbox: `48,50,300,127`
- capture_kind: `cropped-vector-pdf`
- primary_output: `out/graph-hls/assets/fig4-hierarchy.pdf`
- preview_output: `out/graph-hls/assets/fig4-hierarchy-preview.png`
- supports: explanation of L1/L2/L3 and why modification cost is the organizing principle
- follow_up: low; clean figure for a wide evidence slide

### Fig. 5: frontend and abstraction summary
- source_file: `/Users/youwei/Downloads/GraphyFlow-ISCA26-7.pdf`
- page: `6`
- bbox: `48,48,563,228`
- capture_kind: `cropped-vector-pdf`
- primary_output: `out/graph-hls/assets/fig5-full.pdf`
- preview_output: `out/graph-hls/assets/fig5-full-preview.png`
- supports: backup asset when one slide needs both the DSL panel and the optimization examples together
- follow_up: medium; the figure is dense, so the sub-assets below are more likely to survive into the final deck

### Fig. 5a: Graph.hls DSL example
- source_file: `/Users/youwei/Downloads/GraphyFlow-ISCA26-7.pdf`
- page: `6`
- bbox: `48,48,244,198`
- capture_kind: `cropped-vector-pdf`
- primary_output: `out/graph-hls/assets/fig5a-dsl.pdf`
- preview_output: `out/graph-hls/assets/fig5a-dsl-preview.png`
- supports: DSL expressiveness slide; shows GraphConfig, HierarchicalParam, and Iteration in one concrete example
- follow_up: low; readable code-like crop for a side-figure slide

### Fig. 5b: level-specific optimization examples
- source_file: `/Users/youwei/Downloads/GraphyFlow-ISCA26-7.pdf`
- page: `6`
- bbox: `250,48,563,198`
- capture_kind: `cropped-vector-pdf`
- primary_output: `out/graph-hls/assets/fig5b-level-examples.pdf`
- preview_output: `out/graph-hls/assets/fig5b-level-examples-preview.png`
- supports: GH-Architect and cross-level dependency slide; shows how L1/L2/L3 map to concrete code and pipeline changes
- follow_up: low; good companion asset beside the worked example numbers

### Table III: FPGA platforms
- source_file: `/Users/youwei/Downloads/GraphyFlow-ISCA26-7.pdf`
- page: `11`
- bbox: `48,45,287,123`
- capture_kind: `cropped-vector-pdf`
- primary_output: `out/graph-hls/assets/table3-platforms.pdf`
- preview_output: `out/graph-hls/assets/table3-platforms-preview.png`
- supports: evaluation setup; U55C vs U200 memory system and resource budget
- follow_up: medium; likely better recreated as a smaller Typst table than embedded as an image

### Table IV: datasets
- source_file: `/Users/youwei/Downloads/GraphyFlow-ISCA26-7.pdf`
- page: `11`
- bbox: `48,123,287,304`
- capture_kind: `cropped-vector-pdf`
- primary_output: `out/graph-hls/assets/table4-datasets.pdf`
- preview_output: `out/graph-hls/assets/table4-datasets-preview.png`
- supports: evaluation setup; 14 graphs spanning synthetic, social, collaboration, and web workloads
- follow_up: high; dense table will likely need summarization or recreation instead of direct embedding

### Fig. 6: Graph.hls vs ReGraph
- source_file: `/Users/youwei/Downloads/GraphyFlow-ISCA26-7.pdf`
- page: `11`
- bbox: `300,45,563,136`
- capture_kind: `cropped-vector-pdf`
- primary_output: `out/graph-hls/assets/fig6-vs-regraph.pdf`
- preview_output: `out/graph-hls/assets/fig6-vs-regraph-preview.png`
- supports: main HBM result; 2.6x average speedup with only L1 exploration while L2/L3 are fixed to ReGraph’s structure
- follow_up: low; direct figure-led result slide

### Fig. 7: Graph.hls vs ThunderGP
- source_file: `/Users/youwei/Downloads/GraphyFlow-ISCA26-7.pdf`
- page: `11`
- bbox: `300,205,563,304`
- capture_kind: `cropped-vector-pdf`
- primary_output: `out/graph-hls/assets/fig7-vs-thundergp.pdf`
- preview_output: `out/graph-hls/assets/fig7-vs-thundergp-preview.png`
- supports: DDR result and coverage slide; 1.2x average speedup and multiple ThunderGP out-of-memory cases
- follow_up: low; direct figure-led result slide

### Fig. 8: ablation across L1/L2/L3
- source_file: `/Users/youwei/Downloads/GraphyFlow-ISCA26-7.pdf`
- page: `12`
- bbox: `300,45,563,152`
- capture_kind: `cropped-vector-pdf`
- primary_output: `out/graph-hls/assets/fig8-ablation.pdf`
- preview_output: `out/graph-hls/assets/fig8-ablation-preview.png`
- supports: key method/evaluation link; gains require combining the hierarchy rather than tuning one level in isolation
- follow_up: low; direct evidence for the cross-level thesis

### Table V: debugging time comparison
- source_file: `/Users/youwei/Downloads/GraphyFlow-ISCA26-7.pdf`
- page: `12`
- bbox: `311,210,563,302`
- capture_kind: `cropped-vector-pdf`
- primary_output: `out/graph-hls/assets/table5-debugging.pdf`
- preview_output: `out/graph-hls/assets/table5-debugging-preview.png`
- supports: GH-Scope productivity slide; 0.02 to 0.04 second validation versus 13 to 74 minutes or about 6 hours in emulation
- follow_up: low; strong table-led evidence and readable after crop

### Fig. 9: GH-Scope simulation speedup
- source_file: `/Users/youwei/Downloads/GraphyFlow-ISCA26-7.pdf`
- page: `13`
- bbox: `48,45,300,152`
- capture_kind: `cropped-vector-pdf`
- primary_output: `out/graph-hls/assets/fig9-simulation-speedup.pdf`
- preview_output: `out/graph-hls/assets/fig9-simulation-speedup-preview.png`
- supports: large-scale simulation slide; 301.6x average speedup over Vitis C-Sim and 215x on rmat-24-16 PageRank
- follow_up: low; direct figure-led evidence

## Asset Notes

- The strongest reusable slide assets are `fig1`, `fig2`, `fig3`, `fig4`, `fig5a`, `fig5b`, `fig6`, `fig7`, `fig8`, `table5`, and `fig9`.
- `table3` and `table4` are useful planning references, but they are dense enough that a slide will likely render them more clearly by retyping only the necessary rows or summary facts.
- `fig5-full` is preserved as a backup asset, but the split `fig5a` and `fig5b` crops are better aligned with the planned argument.
