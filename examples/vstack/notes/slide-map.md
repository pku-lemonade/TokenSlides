# vStack：面向高效 LLM 推理的异构 HBM-PIM 架构与运行时 Slide Map

| # | Section | Title | Takeaway | Evidence | Archetype | Render | Role | Density |
|---|---|---|---|---|---|---|---|---|
| 1 |  | 标题页 | 交代论文题目、场景与核心主张。 | claim:c3 (deck thesis) | Title slide | script | title | low |
| 2 | 动机 | Decode 时的 KV 压力 | decode attention 已从算力问题转成 KV 带宽与容量共同受限的问题。 | asset:fig01-workflow (prefill 与 decode 的资源形态差异); text:source.txt:196-230 (模型规模、上下文长度、并发请求同时放大 live KV footprint); assets=fig01-workflow | Motivation / Background | script | motivation | medium |
| 3 | 动机 | 现有 HBM-PIM 的结构失配 | Uniform 损容量，Dedicated-PIM 损 GPU-visible 带宽；问题出在 stack 内部分工缺失。 | asset:fig02-baselines (uniform 与 dedicated-PIM 的代价对比); text:source.txt:275-307 (区分粒度仍停在 die，而不是 layer); assets=fig02-baselines | Figure-Led Vertical | script | problem | medium |
| 4 | 动机 | 论文主张 | 同一 stack 内必须同时提供 dense capacity、PIM compute 与 stack-local control。 | text:source.txt:112-173 (四点贡献与总体结果) | Table-Led Structured Slide | script | thesis | medium |
| 5 | 设计 | vStack 整体结构 | compute layers 只保留 hot KV，capacity layers 承担 dense storage，base die 负责跨层协同。 | asset:fig03-architecture (系统级结构); text:source.txt:398-405 (capacity / compute / base-die 的三段分工); assets=fig03-architecture | Method Overview Side-by-Side | script | overview | medium |
| 6 | 设计 | Base Die 控制点 | promotion、demotion、地址转换与 attention 协调都在 stack 内完成，compute-layer miss 不必退化为 host round-trip。 | text:source.txt:456-483 (三类 base-die 模块与 stack-local DMA) | Table-Led Structured Slide | script | mechanism | medium |
| 7 | 设计 | K/V 非对称布局 | K 用 token-major，V 用 dim-head，本质目标是让两个 attention 阶段都避免 cross-bank reduction。 | asset:fig05-kv-layout (score gather 与 context gather 都只需 concat); text:source.txt:612-614 (默认 TM/DH 的 T_agg = L + d); assets=fig05-kv-layout | Figure-Led Vertical | script | mechanism | medium |
| 8 | 设计 | KV 生命周期 | vStack 把 eviction 变成 demotion：热数据离开 compute 层后仍能以压缩形式留在 capacity 层。 | asset:fig06-lifecycle (promotion / demotion 路径); text:source.txt:721-724 (promotion 代价约 1-2 us); text:source.txt:774-781 (K8V4 容量扩展 2.667x); assets=fig06-lifecycle | Figure-Led Vertical | script | mechanism | medium |
| 9 | 设计 | Runtime 策略 | 异构 stack 只是前提，真正决定收益的是哪些 KV 值得占 compute-layer 空间。 | text:source.txt:721-790 (topology-aware placement、category-aware eviction、bounded replication) | Table-Led Structured Slide | script | mechanism | medium |
| 10 | 评估 | 实验设置 | 评估覆盖 4 个模型与 4 类 production-derived traces，故意跨越高复用到低复用两端。 | asset:fig07-workloads (四类 trace 的输入输出长度分布); text:source.txt:813-928 (平台、对比对象、模型与 traces); assets=fig07-workloads | Motivation / Background | script | evaluation-setup | medium |
| 11 | 评估 | 吞吐与容量收益 | vStack 在 16 个 model-trace 组合上全部优于 AttAcc，且模型越大、overflow 越严重，增益越强。 | asset:fig08-throughput (所有组合均优于 AttAcc，GPT-175B 上 Uniform OOM); text:source.txt:975-986 (几何平均 1.62x，按模型 1.20x / 1.38x / 1.94x / 2.15x); text:source.txt:1057-1064 (2x latency SLO 下容量几何平均 1.70x); assets=fig08-throughput | Wide or Fat Evidence | script | result | medium |
| 12 | 评估 | 时延优势 | 更短的 attention step 会更早释放 decode slots，因此 queueing 不会像 AttAcc 那样在高负载下发散。 | asset:fig09-latency (end-to-end latency vs. QPS); asset:fig11-ttft-tbt (TTFT / TBT 分解); text:source.txt:1038-1044 (queue delay 在 QPS=0.2 / 1.0 分别下降 86% / 95%); text:source.txt:1075-1078 (TTFT 几何平均 127x); assets=fig09-latency, fig11-ttft-tbt | Method Overview With Stacked Evidence | script | result | medium |
| 13 | 评估 | 收益来源与能耗 | 最大单项收益先来自 KV-aware layout，且这些吞吐改进不是靠更高能耗换来的。 | asset:fig12-ablation (layout +57.9% 为最大单项收益); asset:fig10-energy (每 token 能耗下降 30%-47%); assets=fig12-ablation, fig10-energy | Two-Up Comparison | script | result | medium |
| 14 | 评估 | 论文边界 | 当 hot/cold 分层不明显或工作集本就能放进 flat PIM tier 时，vStack 的价值会明显收缩。 | text:source.txt:981-986 (Qwen3-4B / thinking 只有 1.03x); text:source.txt:1187-1200 (命中率悖论与 weighted service time) | Table-Led Structured Slide | script | discussion | medium |
| 15 | 总结 | 结论 | 这篇论文把 HBM-PIM 从 attention 加速器推进成面向 KV serving 的异构 memory substrate。 | claim:c3 (stack thesis); claim:c6 (measured benefit) | Conclusion / Takeaways | script | conclusion | low |

## QA Expectations

- title: 标题页不出现续页, 标题、venue 与页脚信息在单页内可读
- motivation-kv-pressure: Figure 1 仍保持可辨识的 prefill/decode 对比, 左侧文字不变成长段落
- motivation-baseline-mismatch: Figure 2 两种 baseline 都能清楚辨认, takeaway 不重复图下注释
- thesis: 贡献表不溢出为续页, 关键数字保持单行可读
- design-overview: Figure 3 在右列保持清晰，不被压成缩略图, 左侧三条职责描述都不换成段落
- design-base-die: 三列表格仍保持单页可读, 标题与表格之间不出现空白浪费
- design-kv-layout: Figure 5 中 K / V 两部分都能辨识, box 不挤压图到缩略图大小
- design-kv-lifecycle: Figure 6 数据路径仍可辨认, 三条 box 保持单页且不挤压证据
- design-runtime: 策略表不出现换页, 表格文字仍明显短于论文原文
- eval-setup: Figure 7 仍能看清四类 trace 的差异, 左侧设置说明不挤压成三段长文
- eval-throughput: Figure 8 的各子图标签仍可读, 两条结论 box 不遮挡宽图空间
- eval-latency: Figure 9 与 Figure 11 在右列都保持可读, 左侧两条结论不挤占 stacked evidence 的高度
- eval-energy-ablation: Figure 12 与 Figure 10 均不缩成缩略图, 比较页标题保持单行
- discussion-limits: 边界页不出现续页, 四条边界仍保留判断而非复述摘要
- conclusion: 总结页不沦为摘要复读, 三条 takeaways 在单页内均可读
