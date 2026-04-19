# vStack: A Heterogeneous HBM-PIM Architecture and Runtime for Efficient LLM Inference Brief

## Paper

- Title: vStack: A Heterogeneous HBM-PIM Architecture and Runtime for Efficient LLM Inference
- Authors: 匿名作者
- Venue/status: MICRO 2026 投稿
- Date: 2026
- Talk mode: zh paper-reading deck

## Presentation Thesis

vStack 的核心不是把更多算子塞进 PIM，而是把同一 HBM stack 内的不同 layer 明确分工，并让 base die 在 stack 内部完成跨层迁移、地址转换与注意力协调。

## Problem Framing

- 瓶颈转移: decode attention 的算术强度接近 O(1)，因此服务瓶颈已从算力转向 KV 带宽与容量。
- 压力耦合: 模型规模、上下文长度与并发请求会同时放大 live KV footprint，并挤占 attention 可用带宽。
- 复用异构: 约 10% 的 KV blocks 贡献 77% 的 reuse，且短 API、代码编辑、长推理的 reuse 形态完全不同。

## Deck-Level Claims

- c1: KV-centric LLM serving 的核心压力来自 decode 阶段对历史 KV 的反复重读，因此瓶颈同时体现在带宽与容量上。
  Evidence: Figure 1, source.txt:41-47, 196-230
- c2: 现有 uniform 与 dedicated-PIM 组织都失败在 stack 内角色划分：前者让所有字节为 PIM 逻辑付费，后者牺牲 GPU-visible HBM 带宽。
  Evidence: Figure 2, source.txt:83-110, 275-307
- c3: vStack 的论文主张是纵向异构 stack 加 base-die control：compute layers 保留 hot KV，capacity layers 保留 dense storage，base die 负责 stack-local control。
  Evidence: Figure 3, Figure 4, source.txt:112-173, 398-483
- c4: 异构硬件只有和 K/V 非对称布局、K8V4 生命周期以及 trace-aware runtime 配合时，才会把高价值 KV 稳定留在 compute-visible domain。
  Evidence: Figure 5, Figure 6, source.txt:592-664, 721-790
- c5: 评估刻意覆盖 4 个模型与 4 类 production-derived traces，从高复用短请求到低复用长推理都包含在内，因此能看清 vertical heterogeneity 的适用边界。
  Evidence: Figure 7, Table 3, source.txt:813-928
- c6: 在大模型和高 overflow 负载上，vStack 能同时提升吞吐、SLO 容量、时延与能耗，且最大收益先来自数据布局与物理分层的一致性。
  Evidence: Figure 8, Figure 9, Figure 10, Figure 11, Figure 12, source.txt:975-1230
- c7: vStack 不是无条件优于 AttAcc：当工作集已能放进 flat PIM tier，或 workload 缺少可预测的 hot/cold 结构时，收益会明显收缩。
  Evidence: source.txt:981-986, 1187-1200

## Method Breakdown

- 纵向异构 stack: compute layers 保存 hot KV，capacity layers 保存 cold KV、weights、activations 与 metadata。
- Base-die control substrate: base die 上集成 disaggregated MC、attention coordinator 与 quantization unit，把迁移、地址转换和 attention 协调留在 stack 内完成。
- K/V 非对称布局: K 用 token-major，V 用 dim-head，让 score 与 context 两阶段都只需 concat，不做 cross-bank reduction。
- K8V4 生命周期: demotion 时做 FP16→K8V4 在线压缩，promotion 时再解压，使 capacity-side KV 有效扩展 2.667x。
- Trace-aware runtime: topology-aware placement、category-aware eviction、bounded replication 与 continuous batching 一起决定哪些 KV 值得占 compute-layer 空间。

## Evaluation Setting

- 平台: DGX-A100，8 GPUs，bank-level PIM；UCIe 512 GB/s × 5 stacks，TSV DMA 896 GB/s / stack，NVLink3 600 GB/s。
- 对比对象: Full-GPU、Uniform、AttAcc、vStack，四者共享同一 continuous batching scheduler。
- 工作负载: traceB、traceA、coder、thinking，覆盖高复用短 API 到低复用长推理。
- 模型: Qwen3-4B、Qwen3-32B、Devstral-123B、GPT-175B。

## Quantitative Anchors

- 复用集中度: 约 10% 的 KV blocks 贡献 77% 的 reuse。
- 吞吐提升: 相对 AttAcc 的 token throughput 几何平均提升 1.62x，区间 1.03x 到 2.32x。
- SLO 容量: 在 2x latency SLO 下，SLO-compliant serving capacity 几何平均提升 1.70x。
- 按模型吞吐增益: Qwen3-4B / 32B / Devstral-123B / GPT-175B 分别为 1.20x / 1.38x / 1.94x / 2.15x。
- 时延: Devstral-123B / traceA 上平均 queue delay 在 QPS=0.2 下降 86%，在 QPS=1.0 下降 95%。
- TTFT: AttAcc 相对 vStack 的 p50 TTFT 几何平均高 127x，峰值超过 4500x。
- 能耗: 每 token 能耗下降 30%-47%，节省主要来自 attention 的 off-chip memory access。
- 消融: layout +57.9%，request scheduling +9.9%，K8V4 +8.2%，category-aware eviction +6.1%，selective replication +2.1%。

## Evidence Map

- c1: asset:fig01-workflow, text:source.txt:41-47, text:source.txt:196-230
- c2: asset:fig02-baselines, text:source.txt:275-307
- c3: asset:fig03-architecture, asset:fig04-stack-design, text:source.txt:112-173, text:source.txt:398-483
- c4: asset:fig05-kv-layout, asset:fig06-lifecycle, text:source.txt:612-664, text:source.txt:721-790
- c5: asset:fig07-workloads, text:source.txt:813-928
- c6: asset:fig08-throughput, asset:fig09-latency, asset:fig10-energy, asset:fig11-ttft-tbt, asset:fig12-ablation
- c7: text:source.txt:981-986, text:source.txt:1187-1200

## Limitations

- 小模型 / 低复用: Qwen3-4B / thinking 只有 1.03x，说明 flat PIM 已足以容纳其工作集时，vertical heterogeneity 价值有限。
- 命中率悖论: Qwen3-32B / traceA 上，vStack 的 compute-hit 只有 0.56，低于 AttAcc 的 0.97，但吞吐仍高 1.43x，因为 miss 落到 capacity layer 仍远便宜于 cross-die forwarding。
- 工作负载依赖: 收益依赖 hot/cold 结构与可预测 reuse window；长链推理这类低共享负载会削弱优势。
- 工程现实: 结果来自 cycle-accurate simulation，而非真实 HBM4 系统，落地复杂度与真实性能仍需实机验证。

## Best Asset-to-Claim Matches

- decode 阶段为什么变成 KV 问题: fig01-workflow
- 为什么现有 HBM-PIM 组织不够好: fig02-baselines
- vStack 的总体结构与 stack 分工: fig03-architecture, fig04-stack-design
- KV-aware layout 与生命周期: fig05-kv-layout, fig06-lifecycle
- 主结果：吞吐与时延: fig08-throughput, fig09-latency, fig11-ttft-tbt
- 收益来源与成本: fig10-energy, fig12-ablation

## Notes

按 systems paper reading 的中文文献解读弧线组织，标题尽量控制为单行，证据优先落在图和精确数字上。
