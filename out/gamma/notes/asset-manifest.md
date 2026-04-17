# Gamma Asset Manifest

Source PDF: `/Users/youwei/Downloads/slides/10321972.pdf`

Scope: early figure/table recovery only for paper-to-slides planning.

Artifact Progress:
- [x] Extract paper text to `notes/source.txt`
- [x] Recover likely visuals and write `notes/asset-manifest.md`
- [x] Write `notes/brief.md` from the paper text and manifest
- [x] Write `notes/slide-map.md` with evidence and archetypes

## Recovered Assets

### Figure 1
- identifier: `Figure 1`
- source file: `/Users/youwei/Downloads/slides/10321972.pdf`
- page number: `1`
- bbox: `[317.955, 172.295, 558.195, 271.990]`
- capture kind: `cropped-composite-pdf`
- primary_output: `assets/gamma-fig01-overview.pdf`
- claim/evidence: overview of CONV dimensions and hierarchical mapper structure; useful for explaining the search space and mapping abstraction
- follow-up cleanup/splitting: `possible`

### Figure 2
- identifier: `Figure 2`
- source file: `/Users/youwei/Downloads/slides/10321972.pdf`
- page number: `3`
- bbox: `[53.798, 79.936, 294.028, 149.753]`
- capture kind: `cropped-composite-pdf`
- primary_output: `assets/gamma-fig02-dse-performance.pdf`
- claim/evidence: scatter/summary view showing random sampling gives widely varying hardware outcomes on one layer; supports motivation for guided search
- follow-up cleanup/splitting: `possible`

### Figure 3
- identifier: `Figure 3`
- source file: `/Users/youwei/Downloads/slides/10321972.pdf`
- page number: `4`
- bbox: `[53.798, 79.934, 294.040, 161.366]`
- capture kind: `cropped-vector-pdf`
- primary_output: `assets/gamma-fig03-encoding.pdf`
- claim/evidence: encoding example for 1-level and 2-level mappers; supports how GAMMA represents mappings as genomes
- follow-up cleanup/splitting: `unlikely`

### Figure 4
- identifier: `Figure 4`
- source file: `/Users/youwei/Downloads/slides/10321972.pdf`
- page number: `4`
- bbox: `[53.798, 187.657, 294.040, 361.734]`
- capture kind: `cropped-vector-pdf`
- primary_output: `assets/gamma-fig04-decoded-mapper.pdf`
- claim/evidence: genome-to-decoded-mapper illustration; supports the translation from GA representation to MAESTRO cost-model input
- follow-up cleanup/splitting: `unlikely`

### Figure 5
- identifier: `Figure 5`
- source file: `/Users/youwei/Downloads/slides/10321972.pdf`
- page number: `4`
- bbox: `[317.955, 79.931, 558.195, 357.049]`
- capture kind: `cropped-composite-pdf`
- primary_output: `assets/gamma-fig05-ga-workflow.pdf`
- claim/evidence: overall GAMMA workflow and evolution operators; supports the method pipeline and operator inventory
- follow-up cleanup/splitting: `possible`

### Figure 6
- identifier: `Figure 6`
- source file: `/Users/youwei/Downloads/slides/10321972.pdf`
- page number: `7`
- bbox: `[53.798, 79.935, 558.201, 296.408]`
- capture kind: `cropped-vector-pdf`
- primary_output: `assets/gamma-fig06-optimization-suite.pdf`
- claim/evidence: main evaluation figure comparing optimization methods across systems/platforms; supports GAMMA's latency advantages and robustness
- follow-up cleanup/splitting: `likely`

### Figure 7
- identifier: `Figure 7`
- source file: `/Users/youwei/Downloads/slides/10321972.pdf`
- page number: `7`
- bbox: `[57.700, 400.900, 289.600, 484.200]`
- capture kind: `cropped-vector-pdf`
- primary_output: `assets/gamma-fig07-found-mappings.pdf`
- claim/evidence: found mappings for early, medium, and late ResNet-18 layers; supports the claim that evolved mappings adapt to layer characteristics
- follow-up cleanup/splitting: `possible`

### Figure 8
- identifier: `Figure 8`
- source file: `/Users/youwei/Downloads/slides/10321972.pdf`
- page number: `7`
- bbox: `[57.700, 503.000, 293.400, 592.100]`
- capture kind: `cropped-vector-pdf`
- primary_output: `assets/gamma-fig08-s2-energy.pdf`
- claim/evidence: energy comparison on S2 for ResNet-18; supports the energy-efficiency result and the platform-dependent behavior discussion
- follow-up cleanup/splitting: `possible`

### Figure 9
- identifier: `Figure 9`
- source file: `/Users/youwei/Downloads/slides/10321972.pdf`
- page number: `7`
- bbox: `[317.955, 395.839, 558.204, 494.228]`
- capture kind: `cropped-composite-pdf`
- primary_output: `assets/gamma-fig09-convergence.pdf`
- claim/evidence: convergence over generations on end-to-end latency; supports sample efficiency and rapid improvement claims
- follow-up cleanup/splitting: `used panel-level captures for the final deck`

### Figure 9a
- identifier: `Figure 9a`
- source file: `/Users/youwei/Downloads/slides/10321972.pdf`
- page number: `7`
- bbox: `[317.955, 395.839, 438.079, 486.072]`
- capture kind: `native-raster-jpeg`
- primary_output: `assets/gamma-fig09-mobilenet.jpeg`
- claim/evidence: clean MobileNet-V2 convergence panel for the sample-efficiency slide; avoids the Table 5 residue above the combined crop
- follow-up cleanup/splitting: `done`

### Figure 9b
- identifier: `Figure 9b`
- source file: `/Users/youwei/Downloads/slides/10321972.pdf`
- page number: `7`
- bbox: `[438.079, 395.839, 558.204, 486.072]`
- capture kind: `native-raster-jpeg`
- primary_output: `assets/gamma-fig09-mnasnet.jpeg`
- claim/evidence: clean MnasNet convergence panel for the sample-efficiency slide; pairs with Figure 9a for a readable two-up comparison
- follow-up cleanup/splitting: `done`

### Table 2
- identifier: `Table 2`
- source file: `/Users/youwei/Downloads/slides/10321972.pdf`
- page number: `5`
- bbox: `[317.955, 83.616, 558.204, 118.418]`
- capture kind: `cropped-vector-pdf`
- primary_output: `assets/gamma-table02-hw-resources.pdf`
- claim/evidence: hardware resource summary for edge and cloud platforms; useful context for constraints used in evaluation
- follow-up cleanup/splitting: `unlikely`

### Table 3
- identifier: `Table 3`
- source file: `/Users/youwei/Downloads/slides/10321972.pdf`
- page number: `5`
- bbox: `[317.955, 131.790, 558.204, 202.182]`
- capture kind: `cropped-vector-pdf`
- primary_output: `assets/gamma-table03-target-systems.pdf`
- claim/evidence: definitions of target systems S1, S2, and S3; useful setup table for the evaluation environment
- follow-up cleanup/splitting: `unlikely`

### Table 4
- identifier: `Table 4`
- source file: `/Users/youwei/Downloads/slides/10321972.pdf`
- page number: `6`
- bbox: `[53.798, 83.614, 294.034, 280.368]`
- capture kind: `cropped-vector-pdf`
- primary_output: `assets/gamma-table04-baselines.pdf`
- claim/evidence: baseline optimization methods and settings; useful for a methods-comparison setup slide
- follow-up cleanup/splitting: `likely`

### Table 5
- identifier: `Table 5`
- source file: `/Users/youwei/Downloads/slides/10321972.pdf`
- page number: `7`
- bbox: `[56.400, 339.600, 556.700, 398.200]`
- capture kind: `cropped-vector-pdf`
- primary_output: `assets/gamma-table05-end-to-end.pdf`
- claim/evidence: end-to-end latency and energy across models/platforms; high-value quantitative evidence that GAMMA consistently wins
- follow-up cleanup/splitting: `likely`

### Table 6
- identifier: `Table 6`
- source file: `/Users/youwei/Downloads/slides/10321972.pdf`
- page number: `8`
- bbox: `[53.800, 144.200, 291.400, 314.000]`
- capture kind: `cropped-vector-pdf`
- primary_output: `assets/gamma-table06-two-stage.pdf`
- claim/evidence: two-stage inter-layer optimization results; supports the extension beyond intra-layer mapping
- follow-up cleanup/splitting: `likely`
