# Paper Brief

## 基本信息

- 题目: `vStack: A Heterogeneous HBM-PIM Architecture and Runtime for Efficient LLM Inference`
- 类型: 体系结构 / 系统论文，围绕 KV-centric LLM serving 的 HBM-PIM 组织与运行时
- 来源: `micro-vstack-4.pdf`
- 语言与场景: 中文文献解读 / seminar

## 论文要解决的问题

LLM decode 阶段会反复读取历史 KV cache。随着上下文长度、并发请求数、模型规模同时增大，decode attention 逐渐从算力受限转为带宽和容量共同受限。

现有 HBM-PIM 方案虽然把 attention 靠近内存执行，但底层 stack 组织仍然不匹配 KV-serving 的异构数据特征：

- `Uniform HBM-PIM`: 所有 layer 都带 PIM，导致冷 KV、权重、激活也占用 compute-enabled area，等效容量减半。
- `Dedicated-PIM / AttAcc`: 把部分 die 固定为 PIM，虽然保住了非 PIM die 的密度，但同时压缩 GPU-visible HBM bandwidth，影响 prefill、FFN、projection 与 KV transfer。

论文核心判断是：问题不只是“是否使用 PIM”，而是“stack 内不同 layer 是否承担不同角色”。

## 动机与关键观察

### 1. Decode attention 是典型带宽瓶颈

- prefill 处理全 prompt，projection / FFN 更重，attention 的 memory access 被 `O(L^2)` 计算摊薄。
- decode 每步只生成 1 个 token，但要重读整段历史 KV，算术强度接近 `O(1)`，因此 attention 成为 memory-bandwidth-limited。

### 2. KV 压力同时来自容量和带宽

- 每 token 的 KV footprint 随 hidden dimension 与 layer 数增长。
- 单请求 KV 大小随 context length 线性增长。
- 多请求并发进一步放大 live KV footprint。

### 3. KV reuse 高度异构

- 生产 trace 中，约 `10%` 的 KV blocks 贡献了 `77%` 的 reuse。
- 短 API 请求有明显 system-prompt / prefix reuse。
- 长链式推理几乎没有跨请求复用。
- reuse 还具有 workload-specific 的时间窗口，不能用简单 LRU 解决。

## 核心主张

vStack 提出“纵向异构”的 HBM-PIM stack：

- capacity layers: 高密度 HBM layer，存 weights、activations、metadata、cold KV。
- compute layers: 带 PIM 的 layer，只存 hot KV。
- logic base die: 负责 stack-local DMA、地址转换、attention 协调、在线量化/反量化。

作者认为，只有把“热 KV 的近存执行”与“冷数据的高密度存储”物理解耦，才能同时缓解容量和带宽压力。

## 方法组成

### A. 异构 stack 组织

- compute layers 放在 capacity layers 之上。
- compute layers 内嵌 FP16 MAC / registers / control logic。
- PIM bank group 的逻辑开销接近硅面积的 `~50%`，因此只值得放最热的 KV。
- 每 stack 的公开容量模型是 `C × B full + P × B half` addressable bytes。

### B. Base-die control substrate

base die 上集成三类关键模块：

- disaggregated memory controller
- attention coordinator
- quantization / dequantization unit

作用：

- 让 capacity ↔ compute 的 promotion / demotion 在 stack 内完成，而不是回到 host GPU。
- 支持 layered address translation，使同一逻辑 KV block 可映射到不同物理 layer。
- 在线执行 `K8V4` 量化与反量化。

### C. KV-aware data layout

Key 和 Value 的布局不对称：

- `K`: token-major，bank `b_K(n)=n mod B` 持有整行，便于 score gather。
- `V`: dim-head，bank `b_V(j)=j mod B` 持有整列，便于 output concat。

目标是避免 cross-bank reduction，把 attention 两阶段都改成 concat-friendly dataflow。

### D. Runtime policies

- topology-aware placement: 新请求优先放在 prefix 已在 nearby stack/card 的位置。
- category-aware eviction: 结合请求类别、上次访问时间、prompt offset、remote-hit 等元数据，估计短期复用概率并决定 demotion。
- bounded replication: 只为高 fan-out、高 callback 成本的 prefix blocks 建副本。
- continuous batching: 在动态到达下持续暴露 prefix sharing 机会。

## 量化与数据移动细节

- compute → capacity 的 demotion 会做在线 `K8V4` 压缩。
- Keys 做 `FP16 -> INT8 (2x)`，Values 做 `FP16 -> INT4 (4x)`，总体等效容量扩展 `2.667x`。
- stack-local DMA 带宽按论文建模为 `896 GB/s per stack`。

## 实验设置

### 平台

- DGX-A100，8 GPUs，HBM3，bank-level PIM
- `UCIe-A BW: 512 GB/s per stack × 5 stacks`
- `TSV DMA BW: 896 GB/s per stack`
- `NVLink3: 600 GB/s`

### 比较对象

- `Full-GPU`: 无 PIM
- `Uniform`: 全 layer PIM
- `AttAcc`: dedicated PIM + HBM
- `vStack`: hybrid stack + aware placement + selective replication + K8V4

### 负载与模型

四类 production-derived traces：

- `traceB`: API/text，`15K` requests，平均输入 `832`，输出 `78`
- `traceA`: mixed，`8K` requests，平均输入 `2043`，输出 `394`
- `coder`: `2.5K` requests，平均输入 `5538`，输出 `852`
- `thinking`: reasoning，`1K` requests，平均输入 `3299`，输出 `3886`

四个模型：

- Qwen3-4B
- Qwen3-32B
- Mistral-Devstral2-123B
- GPT-175B

## 主要结果

### 吞吐

- 相对 AttAcc，`token throughput` 几何平均提升 `1.62x`，区间 `1.03x` 到 `2.32x`。
- 分模型几何平均增益：
  - `1.20x` on Qwen3-4B
  - `1.38x` on Qwen3-32B
  - `1.94x` on Devstral-123B
  - `2.15x` on GPT-175B
- 增益随模型规模增长而单调上升，说明收益来自 KV overflow 压力更严重的场景。
- `Uniform` 在 GPT-175B 上直接 `OOM`。

### 容量 / SLO

- 在 `2x latency SLO` 下，vStack 的 SLO-compliant serving capacity 相对 AttAcc 提升 `1.70x`。
- 区间从 `1.0x` 到 `3.8x`，其中 Devstral-123B / traceB 最明显。
- 对大模型，达到 `90%` 峰值吞吐时的可承载 QPS 为 AttAcc 的 `2.0x - 3.0x`。

### 时延

- 对 Devstral-123B / traceA，平均 queue delay 在 `QPS=0.2` 降低 `86%`，`QPS=1.0` 降低 `95%`。
- p50 TTFT 改善主导总体时延差距：
  - AttAcc 相比 vStack 的 TTFT 几何平均高 `127x`
  - 在 Devstral-123B / traceB 上峰值超过 `4500x`
- TBT 也改善，但幅度更小，几何平均约 `1.8x`。

### 能耗

- 每 token 能耗相对 AttAcc 降低 `30% - 47%`。
- 节能主要来自 attention 的 off-chip memory access 减少，而非 FC layer。

### 消融

在 Devstral-123B / traceA / QPS=32 上，相对 hardware-only baseline：

- layout: `+57.9%`
- request scheduling: `+9.9%`
- K8V4: `+8.2%`
- category-aware eviction: `+6.1%`
- selective replication: `+2.1%`

最重要的不是某个单点技巧，而是“数据布局 + 分层放置 + runtime policy”的组合。

## 局限与批判

- 当模型较小、KV working set 足以被 flat PIM tier 容纳时，异构分层价值很弱，例如 `Qwen3-4B / thinking` 只有 `1.03x`。
- 论文依赖 workload 的 hot/cold 结构明显、且 prefix reuse 可预测；对低复用长推理任务，收益会收缩。
- 评估基于 cycle-accurate simulator，而非真实 HBM4 硬件实现；真实性能和工程复杂度仍需实机验证。
- 论文主要论证 decode 阶段，prefill 与 FFN 仍依赖 GPU-visible bandwidth，因此异构 stack 不能替代 GPU 侧优化。

## 适合在 deck 中展开的 5 个主张

1. 现有 HBM-PIM 设计失败的根因是 stack 组织粒度错了，不是 PIM 算子本身不够强。
2. vStack 的核心不是“更多 PIM”，而是“把 hot KV、cold KV、weights、activations 放到不同物理层”。
3. base die 是这篇论文成立的关键，因为它把 promotion / demotion / attention coordination 变成 stack-local 操作。
4. KV 的非对称布局与 trace-aware runtime 共同决定了收益上限，硬件异构本身只是前提。
5. vStack 的优势在大模型、高 overflow、可预测 reuse 的工作负载上最强；它不是无条件优于 AttAcc。

## 图表库存

- `Figure 1`: inference workflow，证明 decode 为 memory-bound
- `Figure 2`: Uniform vs Dedicated-PIM，证明现有组织一端保容量、一端保带宽，但都无法兼得
- `Figure 3 / 4`: vStack architecture / overview，证明分层职责与 base die 结构
- `Figure 5`: asymmetric K/V layout，证明避免 cross-bank reduction
- `Figure 6`: KV lifecycle，证明 promotion / demotion + K8V4 的数据路径
- `Table 3`: 平台、trace、模型设置
- `Figure 8`: throughput
- `Figure 9`: latency vs QPS
- `Figure 10`: energy per token
- `Figure 11`: TTFT / TBT
- `Figure 12`: ablation + limitation
