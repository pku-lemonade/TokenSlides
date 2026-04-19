#import "/lemonade.typ": *

#set text(lang: "zh")

#show: lemonade-theme.with(
  aspect-ratio: "16-9",
  title-align: "left",
  box-compact: true,
  footer: "bar",
  config-info(
    title: [vStack：面向高效 LLM 推理的异构 HBM-PIM 架构与运行时],
    venue: [MICRO 2026 投稿],
    author: [匿名作者],
    institution: [中文文献解读],
    short-title: [vStack],
    date: [2026],
  ),
)

#title-slide()

= 动机

== Decode 时的 KV 压力

#grid(
  columns: (0.95fr, 1.05fr),
  gutter: 0.8em,
  [
    #ibox[
      *核心判断:* decode 每步只追加 1 个 token，却要重读整段历史 KV，因此注意力路径接近 O(1) 算术强度。
    ]
    
    #sbox[
      *复用结构:* 约 10% 的 KV blocks 贡献 77% 的 reuse，且短 API、代码编辑、长推理的 reuse 形态完全不同。
    ]
    
    #nbox(compact: true)[
      prefill 中 projection / FFN 更重，attention 的内存访问会被 O(L^2) 计算摊薄。 decode 中 KV footprint 会被模型规模、上下文长度与并发请求同时放大。
    ]
    
  ],
  [
    #imgs(
      (image("assets/vstack-fig01-workflow.pdf"), [Prefill 与 decode 的资源形态差异]),
      width: 100%,
    )
    
  ],
)

// Render mode: script
// Claim ids: c1
// Evidence: asset:fig01-workflow (prefill 与 decode 的资源形态差异); text:source.txt:196-230 (模型规模、上下文长度、并发请求同时放大 live KV footprint); assets=fig01-workflow
// QA: Figure 1 仍保持可辨识的 prefill/decode 对比, 左侧文字不变成长段落

== 现有 HBM-PIM 的结构失配

#hbox[
  *Uniform:* 所有 layer 都带 PIM，冷 KV、权重、激活也占 compute-enabled area。
]

#nbox[
  *Dedicated-PIM:* 非 PIM 数据不再浪费面积，但 prefill、FFN 与 callback 共用的 HBM 带宽被固定切走。 真正缺失的是同一 stack 内的 layer specialization，而不是更多 software tiering。
]

#imgs(
  (image("assets/vstack-fig02-baselines.pdf"), [Uniform 与 Dedicated-PIM 的结构失配]),
  width: 94%,
)

// Render mode: script
// Claim ids: c2
// Evidence: asset:fig02-baselines (uniform 与 dedicated-PIM 的代价对比); text:source.txt:275-307 (区分粒度仍停在 die，而不是 layer); assets=fig02-baselines
// QA: Figure 2 两种 baseline 都能清楚辨认, takeaway 不重复图下注释

== 论文主张

#ibox[
  *核心主张:* 把 hot KV、cold KV、weights、activations 放到不同物理层，而不是让所有字节为 PIM 逻辑付费。
]

#sbox[
  *关键数字:* 相对 AttAcc，吞吐 1.62x，SLO 容量 1.70x，每 token 能耗下降 30%-47%。
]

#table(
  columns: (0.9fr, 1.4fr),
  inset: 8pt,
  align: (left, left),
  [*贡献*],
  [*要点*],
  [硬件组织],
  [vertical heterogeneous stack + logic base die],
  [数据放置],
  [K/V 非对称布局贴合 attention dataflow],
  [运行时],
  [placement、eviction、replication 按 trace 特征做取舍],
)

// Render mode: script
// Claim ids: c3
// Evidence: text:source.txt:112-173 (四点贡献与总体结果)
// QA: 贡献表不溢出为续页, 关键数字保持单行可读

= 设计

== vStack 整体结构

#grid(
  columns: (0.92fr, 1.08fr),
  gutter: 0.8em,
  [
    #ibox[
      *Capacity:* weights、activations、metadata 与 cold KV 走高密度路径。
    ]
    
    #hbox[
      *Compute:* 只有最热的 KV 留在 PIM-enabled layers，让 attention 就地执行。
    ]
    
    #sbox[
      *Base Die:* 跨层 DMA、地址转换与 attention-side communication 都在 stack 内协调。
    ]
    
  ],
  [
    #imgs(
      (image("assets/vstack-fig03-architecture.pdf"), [vStack 系统架构]),
      width: 100%,
    )
    
  ],
)

// Render mode: script
// Claim ids: c3
// Evidence: asset:fig03-architecture (系统级结构); text:source.txt:398-405 (capacity / compute / base-die 的三段分工); assets=fig03-architecture
// QA: Figure 3 在右列保持清晰，不被压成缩略图, 左侧三条职责描述都不换成段落

== Base Die 控制点

#ibox[
  *结论:* 这篇论文真正新颖的地方不是再加一个 PIM 算子，而是把 memory controller 与跨层数据路径下沉到 base die。
]

#table(
  columns: (0.9fr, 1.1fr, 1.35fr),
  inset: 8pt,
  align: (left, left, left),
  [*模块*],
  [*职责*],
  [*为什么必须本地*],
  [Disaggregated MC],
  [layered address translation、队列仲裁、stack-local DMA],
  [promotion / demotion 对 host 透明，不走 GPU round-trip],
  [Attention coordinator],
  [gather、broadcast、partial reduce],
  [让分布式 attention 在 stack 内完成协调],
  [Quantization unit],
  [在线 K8V4 量化 / 反量化],
  [迁移时顺手完成压缩，不额外插入 GPU kernel],
)

// Render mode: script
// Claim ids: c3
// Evidence: text:source.txt:456-483 (三类 base-die 模块与 stack-local DMA)
// QA: 三列表格仍保持单页可读, 标题与表格之间不出现空白浪费

== K/V 非对称布局

#hbox[
  *K:* bank b_K(n)=n mod B 保存整行，score gather 之后只需 concat。
]

#sbox[
  *V:* bank b_V(j)=j mod B 保存整列，output 组装同样避免 cross-bank reduction。 只有让数据布局贴合 attention dataflow，PIM bank 的本地带宽才真正被利用。
]

#imgs(
  (image("assets/vstack-fig05-kv-layout.pdf"), [K/V 非对称布局]),
  width: 94%,
)

// Render mode: script
// Claim ids: c4
// Evidence: asset:fig05-kv-layout (score gather 与 context gather 都只需 concat); text:source.txt:612-614 (默认 TM/DH 的 T_agg = L + d); assets=fig05-kv-layout
// QA: Figure 5 中 K / V 两部分都能辨识, box 不挤压图到缩略图大小

== KV 生命周期

#hbox[
  *Demotion:* compute -> capacity 时在线做 FP16→K8V4，只把最热的 KV 留在 compute 层。
]

#sbox[
  *容量效果:* capacity-side KV 有效扩展 2.667x，promotion 只需容量层读加解压，而不是重新 prefill。 前台只搬回真正 latency-visible 的 miss，避免把所有冷数据都重新热起来。
]

#imgs(
  (image("assets/vstack-fig06-lifecycle.pdf"), [KV 生命周期与 K8V4 路径]),
  width: 94%,
)

// Render mode: script
// Claim ids: c4
// Evidence: asset:fig06-lifecycle (promotion / demotion 路径); text:source.txt:721-724 (promotion 代价约 1-2 us); text:source.txt:774-781 (K8V4 容量扩展 2.667x); assets=fig06-lifecycle
// QA: Figure 6 数据路径仍可辨认, 三条 box 保持单页且不挤压证据

== Runtime 策略

#ibox[
  *设计依据:* 10% blocks 贡献 77% reuse，但不同 trace 的 reuse window 差异很大，所以不能靠单一 LRU。
]

#table(
  columns: (0.95fr, 1.35fr),
  inset: 8pt,
  align: (left, left),
  [*策略*],
  [*作用*],
  [Topology-aware placement],
  [新请求优先落在已有 prefix 所在的 stack / card，减少初始迁移与 callback],
  [Category-aware eviction],
  [结合类别、上次访问时间、offset 与 remote-hit 估计短期复用概率],
  [Bounded replication],
  [只为高 fan-out、高 callback 成本的 prefix 建副本],
  [Continuous batching],
  [在动态到达下持续暴露 prefix sharing 机会],
)

// Render mode: script
// Claim ids: c4
// Evidence: text:source.txt:721-790 (topology-aware placement、category-aware eviction、bounded replication)
// QA: 策略表不出现换页, 表格文字仍明显短于论文原文

= 评估

== 实验设置

#grid(
  columns: (0.95fr, 1.05fr),
  gutter: 0.8em,
  [
    #ibox[
      *平台 / 对比:* DGX-A100，8 GPUs，bank-level PIM；Full-GPU / Uniform / AttAcc / vStack 共用同一 scheduler。
    ]
    
    #sbox[
      *覆盖范围:* 模型从 4B 到 175B；trace 从高复用短 API 到低复用长推理，正好覆盖 vStack 最可能受益与失效的两端。
    ]
    
    #nbox(compact: true)[
      带宽：UCIe 512 GB/s × 5 stacks，TSV DMA 896 GB/s / stack，NVLink3 600 GB/s。 模型：Qwen3-4B、Qwen3-32B、Devstral-123B、GPT-175B。
    ]
    
  ],
  [
    #imgs(
      (image("assets/vstack-fig07-workloads.pdf"), [四类 trace 的输入输出长度分布]),
      width: 100%,
    )
    
  ],
)

// Render mode: script
// Claim ids: c5
// Evidence: asset:fig07-workloads (四类 trace 的输入输出长度分布); text:source.txt:813-928 (平台、对比对象、模型与 traces); assets=fig07-workloads
// QA: Figure 7 仍能看清四类 trace 的差异, 左侧设置说明不挤压成三段长文

== 吞吐与容量收益

#ibox[
  *关键数字:* 相对 AttAcc，token throughput 几何平均提升 1.62x；按模型分别为 1.20x / 1.38x / 1.94x / 2.15x。
]

#sbox[
  *容量含义:* 2x latency SLO 下，SLO-compliant serving capacity 再提升 1.70x；收益在大模型和高 overflow 负载上最明显。
]

#imgs(
  (image("assets/vstack-fig08-throughput.pdf"), [吞吐收益随 overflow 压力增强]),
  width: 98%,
)

// Render mode: script
// Claim ids: c6
// Evidence: asset:fig08-throughput (所有组合均优于 AttAcc，GPT-175B 上 Uniform OOM); text:source.txt:975-986 (几何平均 1.62x，按模型 1.20x / 1.38x / 1.94x / 2.15x); text:source.txt:1057-1064 (2x latency SLO 下容量几何平均 1.70x); assets=fig08-throughput
// QA: Figure 8 的各子图标签仍可读, 两条结论 box 不遮挡宽图空间

== 时延优势

#grid(
  columns: (1fr, 1fr),
  gutter: 0.8em,
  [
    #ibox[
      *Queueing:* Devstral-123B / traceA 上，平均 queue delay 在 QPS=0.2 下降 86%，在 QPS=1.0 下降 95%。
    ]
    
    #sbox[
      *TTFT:* AttAcc 相对 vStack 的 p50 TTFT 几何平均高 127x，峰值超过 4500x，说明优势首先来自更早释放 decode slots。
    ]
    
  ],
  [
    #imgs(
      (image("assets/vstack-fig09-latency.pdf"), [高负载下延迟不会像 AttAcc 一样发散]),
      (image("assets/vstack-fig11-ttft-tbt.pdf"), [TTFT 主导总体时延差距]),
      dir: ttb,
      width: 100%,
      gap: 0.6em,
    )
    
  ],
)

// Render mode: script
// Claim ids: c6
// Evidence: asset:fig09-latency (end-to-end latency vs. QPS); asset:fig11-ttft-tbt (TTFT / TBT 分解); text:source.txt:1038-1044 (queue delay 在 QPS=0.2 / 1.0 分别下降 86% / 95%); text:source.txt:1075-1078 (TTFT 几何平均 127x); assets=fig09-latency, fig11-ttft-tbt
// QA: Figure 9 与 Figure 11 在右列都保持可读, 左侧两条结论不挤占 stacked evidence 的高度

== 收益来源与能耗

#ibox[
  *主因:* layout 单项带来 +57.9%，说明物理布局先决定上限，调度与压缩是在这个基础上的增益放大器。
]

#sbox[
  *代价:* 每 token 能耗再降 30%-47%，节省主要来自 attention 的 off-chip memory access，而不是牺牲效率换吞吐。
]

#imgs(
  (image("assets/vstack-fig12-ablation.pdf"), [布局贡献最大，其次是调度与压缩]),
  (image("assets/vstack-fig10-energy.pdf"), [每 token 能耗同步下降]),
  width: 100%,
  gap: 0.8em,
)

// Render mode: script
// Claim ids: c6
// Evidence: asset:fig12-ablation (layout +57.9% 为最大单项收益); asset:fig10-energy (每 token 能耗下降 30%-47%); assets=fig12-ablation, fig10-energy
// QA: Figure 12 与 Figure 10 均不缩成缩略图, 比较页标题保持单行

== 论文边界

#ibox[
  *结论:* vStack 并不是无条件优于 AttAcc，它依赖明显的 hot/cold 结构与足够强的 KV overflow。
]

#table(
  columns: (0.95fr, 1.45fr),
  inset: 8pt,
  align: (left, left),
  [*边界现象*],
  [*含义*],
  [小模型 / 低复用],
  [Qwen3-4B / thinking 只有 1.03x，说明 flat PIM 已足以容纳其工作集。],
  [命中率悖论],
  [Qwen3-32B / traceA 上，vStack compute-hit 只有 0.56，但吞吐仍高 1.43x。],
  [真正指标],
  [不能只看 compute-hit，要看 miss 之后落到哪里，capacity-layer miss 远便宜于 cross-die forwarding。],
  [工程现实],
  [结果来自 cycle-accurate simulation，HBM4 实机落地仍需后续验证。],
)

// Render mode: script
// Claim ids: c7
// Evidence: text:source.txt:981-986 (Qwen3-4B / thinking 只有 1.03x); text:source.txt:1187-1200 (命中率悖论与 weighted service time)
// QA: 边界页不出现续页, 四条边界仍保留判断而非复述摘要

= 总结

== 结论

#ibox[
  *第一点:* 真正需要异构的是 stack 内物理层，而不是只在系统外层做 software tiering。
]

#hbox[
  *第二点:* base die control 让 promotion、demotion、量化与 attention coordination 都变成 stack-local 操作。
]

#sbox[
  *第三点:* 最大收益出现在大模型、高 overflow、可预测 prefix reuse 的场景；这也是最值得部署的地方。
]

// Render mode: script
// Claim ids: c3
// Evidence: claim:c3 (stack thesis); claim:c6 (measured benefit)
// QA: 总结页不沦为摘要复读, 三条 takeaways 在单页内均可读
