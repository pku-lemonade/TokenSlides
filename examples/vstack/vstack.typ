#import "/lemonade.typ": *

#set text(lang: "zh")

#let asset(name) = "/examples/vstack/assets/" + name

#show: lemonade-theme.with(
  config-info(
    title: [vStack：面向高效 LLM 推理的异构 HBM-PIM 架构与运行时],
    author: [李卓然],
    institution: [北京大学],
    venue: [MICRO 2026 投稿],
  ),
  aspect-ratio: "16-9",
  title-align: "left",
  box-compact: true,
  imgs-config: (
    cap-size: 15pt,
    cap-weight: "bold",
    fill-height: false,
  ),
)

#title-slide()

= 动机

== Decode 阶段的 KV 压力

#grid(
  columns: (1.08fr, 0.92fr),
  gutter: 0.8em,
  [
    #ibox[
      *核心判断：* decode attention 已经从算力问题转成 KV 带宽与容量问题。
    ]
    #hbox[
      *Prefill:* projection / FFN 主导，memory access 被 `O(L^2)` 计算摊薄。
    ]
    #nbox[
      *Decode:* 每步只生成 1 个 token，却要重读整段历史 KV，算术强度接近 `O(1)`。
    ]
    #sbox[
      *现实特征：* 约 `10%` 的 KV blocks 贡献 `77%` 的 reuse，且不同 workload 差异很大。
    ]
  ],
  [
    #table(
      columns: (0.8fr, 1.45fr),
      inset: 8pt,
      align: (left, left),
      [*压力来源*], [*含义*],
      [模型规模], [hidden size 和 layer 数越大，单 token KV 越大],
      [上下文长度], [请求越长，历史 KV 线性膨胀],
      [并发请求], [live KV footprint 被同时放大],
    )
  ],
)

== 现有 HBM-PIM 的结构失配

#grid(
  columns: (0.92fr, 1.08fr),
  gutter: 0.8em,
  [
    #ibox[
      *Uniform:* 所有 layer 都带 PIM，冷 KV、权重、激活也占 compute-enabled area。
    ]
    #hbox[
      *Dedicated-PIM:* 非 PIM 数据不再浪费面积，但 GPU-visible HBM bandwidth 被固定切走。
    ]
    #sbox[
      *根因：* 现有方案的区分粒度停在 `die`，而不是同一 stack 内的 `layer`。
    ]
  ],
  [
    #imgs(
      asset("fig2-baselines.png"),
      width: 100%,
    )
  ],
)

== 论文主张

#grid(
  columns: (1fr, 0.98fr),
  gutter: 0.8em,
  [
    #ibox[
      *论文主张：* 同一 memory stack 内必须把 hot KV、cold KV、weights、activations 放到不同物理层。
    ]
    #hbox[
      *层级分工：* compute layers 只保留 hot KV；capacity layers 承担 dense storage；base die 负责跨层控制。
    ]
    #sbox[
      *关键数字：* 相对 AttAcc，吞吐几何平均 `1.62x`，SLO 容量 `1.70x`，每 token 能耗下降 `30%–47%`。
    ]
  ],
  [
    #table(
      columns: (0.9fr, 1.4fr),
      inset: 8pt,
      align: (left, left),
      [*贡献*], [*要点*],
      [问题刻画], [现有 homogeneous stack 无法同时满足容量与计算密度],
      [硬件组织], [纵向异构 stack + logic base die],
      [数据布局], [K/V 非对称布局贴合 attention dataflow],
      [运行时], [placement、eviction、replication 都按 trace 特征设计],
    )
  ],
)

= 设计

== vStack 整体结构

#grid(
  columns: (1.0fr, 1.0fr),
  gutter: 0.8em,
  [
    #ibox[
      *容量层:* weights、activations、metadata 与 cold KV 走高密度路径。
    ]
    #hbox[
      *计算层:* 只保留最热的 KV，使 attention 能在 bank-level PIM 上就地执行。
    ]
    #nbox[
      *Base Die:* 把跨层迁移、地址转换与 attention 协调都留在 stack 内部。
    ]
  ],
  [
    #imgs(
      asset("fig3-architecture.png"),
      width: 100%,
    )
  ],
)

== Base Die 是关键控制点

#ibox[
  *结论：* 这篇论文真正新颖的地方不是再加一个 PIM 算子，而是把 memory controller 与跨层数据路径下沉到 base die。
]

#table(
  columns: (0.95fr, 1.1fr, 1.3fr),
  inset: 8pt,
  align: (left, left, left),
  [*模块*], [*职责*], [*为什么必须在 stack 内*],
  [Disaggregated MC], [layered address translation、队列仲裁], [promotion / demotion 对 host 透明，不走 GPU round-trip],
  [Attention coordinator], [gather、broadcast、partial reduce], [让分布式 attention 在 stack 内协调完成],
  [Quantization unit], [在线 `K8V4` 量化 / 反量化], [迁移顺手完成压缩，不额外插入 GPU kernel],
)

#sbox[
  *结果：* compute-layer miss 不必退化成 cross-die forwarding，而是先落到更便宜的 capacity-layer access。
]

== Key / Value 非对称布局

#ibox[
  *结论：* vStack 不是把 KV 当成统一对象放置，而是让 `K` 与 `V` 分别贴合 attention 的两个阶段。
]

#grid(
  columns: (0.98fr, 1.02fr),
  gutter: 0.8em,
  [
    #hbox[
      *K 用 token-major:* 每个 bank 持有整行，score gather 之后只需 concat。
    ]
    #nbox[
      *V 用 dim-head:* 每个 bank 持有整列，output 组装同样避免 cross-bank reduction。
    ]
    #sbox[
      *直接收益：* 布局与数据流一致后，PIM bank 的本地带宽才真正被用起来。
    ]
  ],
  [
    #imgs(
      asset("fig5-kv-layout.png"),
      width: 100%,
    )
  ],
)

== KV 生命周期与 K8V4

#ibox[
  *结论：* vStack 管理的不是一个平面的 KV cache，而是一条带在线压缩的跨层生命周期。
]

#grid(
  columns: (0.95fr, 1.05fr),
  gutter: 0.8em,
  [
    #hbox[
      *Demotion:* compute -> capacity 时在线量化，Keys 做 `FP16 -> INT8`，Values 做 `FP16 -> INT4`。
    ]
    #nbox[
      *Promotion:* 反向路径做解压与重组，只让真正 latency-visible 的 miss 走前台迁移。
    ]
    #sbox[
      *容量效果：* `K8V4` 让 capacity-side KV 的有效空间扩展到 `2.667x`。
    ]
  ],
  [
    #imgs(
      asset("fig6-lifecycle.png"),
      width: 100%,
    )
  ],
)

== Runtime 只把最值钱的 KV 留在计算层

#ibox[
  *核心判断：* 异构 stack 本身只是前提，真正决定收益的是哪些 KV 值得占 compute-layer 位置。
]

#table(
  columns: (0.92fr, 1.35fr),
  inset: 8pt,
  align: (left, left),
  [*策略*], [*作用*],
  [Topology-aware placement], [新请求优先靠近已有 prefix 的 stack / card，减少初始迁移与 callback],
  [Category-aware eviction], [结合类别、上次访问时间、prompt offset 与 remote-hit 估计短期复用],
  [Bounded replication], [只为高 fan-out prefix 建副本，不把复制当默认策略],
  [Continuous batching], [在动态到达下持续暴露 prefix sharing 机会],
)

#sbox[
  *设计依据：* 高复用块非常集中，但不同 trace 的 reuse window 差异很大，所以不能靠单一 LRU。
]

= 评估

== 实验设置

#grid(
  columns: (1fr, 1fr),
  gutter: 0.8em,
  [
    #table(
      columns: (0.95fr, 1.3fr),
      inset: 8pt,
      align: (left, left),
      [*平台 / 对比*], [*配置*],
      [平台], [DGX-A100，8 GPUs，bank-level PIM],
      [带宽], [`UCIe 512 GB/s × 5 stacks`，`TSV DMA 896 GB/s / stack`，`NVLink3 600 GB/s`],
      [对比对象], [Full-GPU、Uniform、AttAcc、vStack],
      [统一调度], [四者共享同一 continuous batching scheduler],
    )
  ],
  [
    #table(
      columns: (0.88fr, 1.35fr),
      inset: 8pt,
      align: (left, left),
      [*负载 / 模型*], [*覆盖范围*],
      [Traces], [`traceA` mixed，`traceB` API/text，`coder`，`thinking`],
      [输入输出], [平均输出从 `78` tokens 到 `3886` tokens，覆盖高复用到低复用两端],
      [模型], [Qwen3-4B、Qwen3-32B、Devstral-123B、GPT-175B],
      [目标], [观察 KV 压力从中等走向主导时，stack 组织的收益如何变化],
    )
  ],
)

== 吞吐与容量收益

#ibox[
  *结论：* vStack 在全部 `16` 个 model-trace 组合上都优于 AttAcc，而且模型越大，增益越强。
]

#hbox[
  *关键数字：* 吞吐几何平均 `1.62x`；按模型看分别为 `1.20x / 1.38x / 1.94x / 2.15x`；`Uniform` 在 GPT-175B 上直接 `OOM`。
]

#imgs(
  asset("fig8-throughput.png"),
  width: 100%,
)

== 时延优势主要来自 TTFT

#ibox[
  *结论：* vStack 的优势首先体现在 queueing 不发散，因为更短的 attention step 会更早释放 decode slots。
]

#grid(
  columns: (1fr,),
  [
    #hbox[
      *关键数字：* Devstral-123B / traceA 上，平均 queue delay 在 `QPS=0.2` 降 `86%`，在 `QPS=1.0` 降 `95%`。
    ]
    #nbox[
      *分解结论：* TTFT 的改善主导总体时延差距；AttAcc 相对 vStack 的 TTFT 几何平均高 `127x`。
    ]
  ],
)

#imgs(
  asset("fig9-latency.png"),
  width: 100%,
)

== 最大收益先来自布局，再来自调度与压缩

#ibox[
  *结论：* 最有价值的不是某一个 trick，而是“布局先对齐数据流，再用 runtime 保住这种对齐”。
]

#grid(
  columns: (0.95fr, 1.05fr),
  gutter: 0.8em,
  [
    #table(
      columns: (1fr, 0.7fr),
      inset: 8pt,
      align: (left, left),
      [*组件*], [*增益*],
      [KV-aware layout], [`+57.9%`],
      [Request scheduling], [`+9.9%`],
      [K8V4], [`+8.2%`],
      [Category-aware eviction], [`+6.1%`],
      [Selective replication], [`+2.1%`],
    )
  ],
  [
    #imgs(
      asset("fig12-ablation.png"),
      width: 100%,
    )
  ],
)

== 能耗也同步下降

#ibox[
  *结论：* vStack 的吞吐与时延收益没有建立在更高能耗上，反而把每 token 能耗进一步压低。
]

#hbox[
  *关键数字：* 相对 AttAcc，每 token 能耗下降 `30%–47%`，节省主要来自 attention 的 off-chip memory access。
]

#imgs(
  asset("fig10-energy.png"),
  width: 82%,
)

== 论文的边界

#ibox[
  *结论：* vStack 并不是无条件优于 AttAcc，它依赖明显的 hot/cold 结构与足够强的 KV overflow。
]

#table(
  columns: (1fr, 1.45fr),
  inset: 8pt,
  align: (left, left),
  [*边界现象*], [*含义*],
  [小模型 / 低复用], [`Qwen3-4B / thinking` 只有 `1.03x`，说明 flat PIM 已足以容纳其工作集],
  [命中率悖论], [在 Qwen3-32B / traceA 上，vStack compute-hit 只有 `0.56`，低于 AttAcc 的 `0.97`，但吞吐仍高 `1.43x`],
  [真正指标], [不能只看 compute-hit，要看 miss 之后落到哪里，capacity-layer miss 远便宜于 cross-die forwarding],
  [工程现实], [结果来自 cycle-accurate simulation，HBM4 实机落地仍需后续验证],
)

= 总结

== 结论

#ibox[
  *一句话总结：* vStack 把 HBM-PIM 从“只做 attention 加速”推进成“围绕 KV serving 重新组织 memory stack”。
]

#hbox[
  *第一点：* 真正需要异构的是 stack 内的物理层，而不是只在系统外层做 software tiering。
]

#nbox[
  *第二点：* base die control 让 promotion、demotion、量化与 attention coordination 都变成 stack-local 操作。
]

#sbox[
  *第三点：* 最大收益来自大模型、高 overflow、可预测 prefix reuse 的场景；这也是这类架构最值得部署的地方。
]

#thank-you-slide(
  title: [谢谢],
  content: [欢迎讨论 vStack 与 KV-centric serving 的系统设计。],
)
