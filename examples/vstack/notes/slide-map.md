# Slide Map

## 场景

- 类型: 中文文献解读 / seminar
- 结构: systems paper reading
- 原则: 每页只打一个结论；证据必须落到图、表或精确数字

## 计划页序

1. section: front
   title: 标题页
   takeaway: 交代论文题目、场景与来源
   evidence: 题目信息
   archetype: title

2. section: 动机
   title: Decode 阶段的 KV 压力
   takeaway: LLM serving 的瓶颈已从算力转向 KV 带宽与容量
   evidence: decode 算术强度接近 `O(1)`；KV footprint 同时随模型、上下文、并发增长
   archetype: table-led structured slide

3. section: 动机
   title: 现有 HBM-PIM 的结构失配
   takeaway: Uniform 损容量，Dedicated-PIM 损 GPU-visible 带宽；问题出在 stack 内部分工缺失
   evidence: Figure 2；uniform 容量减半；AttAcc 压缩 GPU-side HBM 带宽
   archetype: figure-led vertical

4. section: 动机
   title: 论文主张
   takeaway: 同一 stack 内必须同时容纳 dense layers、compute layers 与 stack-local control
   evidence: 4 个 contributions；`1.62x` throughput、`1.70x` SLO 容量、`30-47%` 能耗下降
   archetype: method overview side-by-side

5. section: 设计
   title: vStack 整体结构
   takeaway: hot KV 上 compute layers，cold KV / weights / activations 上 capacity layers，base die 负责跨层协同
   evidence: Figure 3/4
   archetype: method overview side-by-side

6. section: 设计
   title: Base Die 是关键控制点
   takeaway: promotion、demotion、地址转换与 attention coordination 都在 stack 内完成，避免 host round-trip
   evidence: Figure 3；disaggregated MC / coordinator / quantization unit 三模块
   archetype: table-led structured slide

7. section: 设计
   title: Key / Value 非对称布局
   takeaway: K 用 token-major，V 用 dim-head，本质目标是消除 cross-bank reduction
   evidence: Figure 5；TM/DH 为默认布局
   archetype: figure-led vertical

8. section: 设计
   title: KV 生命周期与 K8V4
   takeaway: vStack 不是简单 cache，而是带在线压缩的分层 KV 管理
   evidence: Figure 6；K8V4 使 capacity-side KV 有效扩展 `2.667x`
   archetype: figure-led vertical

9. section: 设计
   title: Runtime 只把最值钱的 KV 留在 compute 层
   takeaway: topology-aware placement、category-aware eviction、bounded replication 决定异构 stack 是否真正发挥作用
   evidence: `10%` blocks 贡献 `77%` reuse；元数据字段与 demotion score 公式
   archetype: table-led structured slide

10. section: 评估
    title: 实验设置
    takeaway: 评估覆盖 4 个模型、4 类真实 trace，规模从 4B 到 175B
    evidence: Table 3；DGX-A100；traceA/traceB/coder/thinking
    archetype: table-led structured slide

11. section: 评估
    title: 吞吐与容量收益
    takeaway: vStack 在 16 个 model-trace 组合上全部优于 AttAcc，且大模型增益更强
    evidence: Figure 8；几何平均 `1.62x`；GPT-175B 上 uniform OOM
    archetype: wide or fat evidence

12. section: 评估
    title: 时延优势主要来自 TTFT
    takeaway: vStack 更早释放 decode slots，因此 queueing 不会像 AttAcc 那样在高负载下发散
    evidence: Figure 9；Figure 11；`QPS=1.0` 时 queue delay 降 `95%`；TTFT 几何平均 `127x`
    archetype: wide or fat evidence

13. section: 评估
    title: 收益首先来自布局，其次才是调度与压缩
    takeaway: 最大单项增益来自 KV-aware layout，说明数据流与物理布局的一致性比单点 trick 更重要
    evidence: Figure 12；layout `+57.9%`，scheduling `+9.9%`，K8V4 `+8.2%`
    archetype: figure-led vertical

14. section: 评估
    title: 能耗也同步下降
    takeaway: vStack 的收益不是靠多耗能换来的，attention 的 off-chip access 反而更少
    evidence: Figure 10；每 token 能耗下降 `30-47%`
    archetype: figure-led vertical

15. section: 评估
    title: 论文的边界
    takeaway: 当 KV 热冷分层不明显或模型太小，异构 stack 的价值会明显收缩
    evidence: `Qwen3-4B/thinking = 1.03x`；Qwen3-32B/traceA 命中率 `0.56 vs 0.97` 但仍有 `1.43x` 吞吐
    archetype: table-led structured slide

16. section: 总结
    title: 结论
    takeaway: 这篇论文把 HBM-PIM 从“算子加速器”推进到“面向 KV serving 的异构内存基座”
    evidence: 三条总结：分层职责、base-die control、trace-aware runtime
    archetype: table-led structured slide

17. section: back
    title: 谢谢
    takeaway: 收尾
    evidence: none
    archetype: thank-you
