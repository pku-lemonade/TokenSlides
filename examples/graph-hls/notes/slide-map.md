# Graph.hls Slide Map

Artifact Progress:
- [x] Recover likely visuals and write `notes/asset-manifest.md`
- [x] Write `notes/brief.md` from the paper text and manifest
- [x] Write `notes/slide-map.md` with evidence and archetypes

## Planned Slides

| # | Section | Title | Takeaway | Evidence | Archetype |
| --- | --- | --- | --- | --- | --- |
| 1 | Front Matter | Graph.hls | Graph.hls frames graph accelerator design as a compiler problem rather than a manual HLS integration task. | Paper title, ISCA 2026, subtitle from brief | Title slide |
| 2 | Motivation | Broken Workflow | Existing frameworks fail twice: they cannot compose optimizations cleanly, and they force debugging through slow emulation loops. | `fig1-workflow`; `50+ minutes` per iteration from abstract | Figure-Led Vertical |
| 3 | Motivation | Integration Tax | A “simple” `32 -> 16` bitwidth change spills across constants, packing, kernels, and host code, which exposes why reuse across frameworks is so hard. | `fig2-bitwidth-cascade`; `200+ lines`, `10+ files` | Figure-Led Vertical |
| 4 | Design | Compiler Thesis | Graph.hls separates the design space into a hierarchical abstraction and two engines: generation and verification. | `fig3-overview`; GH-Architect + GH-Scope summary | Wide or Fat Evidence |
| 5 | Design | Cost-Tiered Abstraction | The `L1/L2/L3` split is the paper’s core abstraction: it matches optimization scope to modification cost and automation strategy. | `fig4-hierarchy`; L1 single-line, L2 multi-file, L3 redesign | Figure-Led Vertical |
| 6 | Design | DSL Frontend | The frontend covers normal GAS pipelines and also irregular graph kernels because the core operators are `map/filter/reduce` over graph streams. | `fig5a-dsl`; Belief Propagation example from text | Method Overview Side-by-Side |
| 7 | Design | Constraint Propagation | GH-Architect first chooses an `L3` layout from graph statistics, then resolves `L1/L2` deterministically to emit a globally consistent Vitis project. | `fig5b-level-examples`; PageRank worked example with `11` little + `3` big pipelines, `896/960` URAM use, `16-bit` false convergence | Method Overview With Stacked Evidence |
| 8 | Design | IR-Level Validation | GH-Scope verifies the IR before synthesis, so type mismatches, cyclic graphs, overflow, and non-convergence are caught in seconds instead of emulation-scale minutes or hours. | `table5-debugging`; `0.02s`, `0.04s`, `455,000x` | Table-Led Structured Slide |
| 9 | Evaluation | Evaluation Setup | The evaluation spans two very different FPGA memory systems, six graph algorithms, and fourteen datasets under parameter-matched baselines. | Table III exact platform stats; Table IV dataset coverage; ReGraph on `U55C`, ThunderGP on `U200` | Table-Led Structured Slide |
| 10 | Evaluation | HBM Baseline | Even with only `L1` exploration enabled, Graph.hls beats ReGraph by `2.6x` on average because partition tuning improves load balance without changing structure. | `fig6-vs-regraph`; strongest gains on `R24`, `AM`, `LJ` | Figure-Led Vertical |
| 11 | Evaluation | DDR Baseline | Graph.hls also matches or exceeds ThunderGP on `U200` and handles large-graph cases where ThunderGP runs out of memory. | `fig7-vs-thundergp`; `1.2x` average; `five` OoM cases in text | Figure-Led Vertical |
| 12 | Evaluation | Cross-Level Gains | The ablation is the strongest evidence for the hierarchy: real gains appear only when `L1/L2/L3` are combined rather than tuned independently. | `fig8-ablation`; `0.71x`, `1.99x`, `2.95x`, `2.52x`, `4.48x` | Figure-Led Vertical |
| 13 | Evaluation | Simulation Speed | GH-Scope is not only a debugger; it is a practical large-graph simulator that averages `301.6x` speedup over Vitis `C-Sim`. | `fig9-simulation-speedup`; `1779.06s -> 8.29s` on `rmat-24-16` PR | Figure-Led Vertical |
| 14 | Discussion | Takeaways | The paper’s strongest contribution is the compiler story; the main caveats are proxy-simulator comparison and limited discussion of synthesis/overhead costs. | Exact text on Vitis `C-Sim` proxy; fair-comparison setup; missing deeper cost breakdown | Table-Led Structured Slide |
| 15 | Front Matter | Thank You | End on the claim that Graph.hls turns isolated accelerator hacks into a configurable design-and-verify workflow. | Title-level recap; no new evidence | Thank-you slide |

## Slide-to-Asset Notes

- Slides `2` to `8` should spend the bulk of the deck budget on the argument that Graph.hls is a compiler and workflow contribution, not just a faster accelerator instance.
- Slides `10` to `13` are the main evidence block and should remain figure-led.
- Slide `9` should likely retype only the most important setup facts rather than embedding dense table screenshots.
- Slide `14` should stay short and judgmental: one strengths box and one caveats box is enough.
