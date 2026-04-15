# Common Deck Structures

Treat these as deck arcs, not literal one-slide-per-section templates. Convert the chosen arc into a slide map before writing Typst.

## 1. General Paper Talk

Use when the user asks for a paper presentation, reading report, or seminar without a defense-specific context.

Typical arc:

1. 研究背景 / Motivation
2. 问题定义 / Problem
3. 核心方法 / Method
4. 关键设计 / Algorithm or System Design
5. 实验设置 / Evaluation Setup
6. 主要结果 / Main Results
7. 局限与讨论 / Limitations or Discussion
8. 总结 / Takeaways

## 2. Systems Paper Reading / OSDI-SOSP Style

Use when the source is a systems, architecture, storage, database, kernel, networking, or serving paper, especially when the paper's value comes from workload pathologies, system decomposition, or several distinct mechanisms.

This arc applies to both English and Chinese decks. Treat language choice and deck arc as separate decisions.

Typical arc:

1. Workload pressure or motivating failure
2. Why existing systems fail
3. Thesis and contributions
4. System overview
5. Mechanism A
6. Mechanism B or policy detail
7. Evaluation setup and baselines
8. Main results
9. Overhead, robustness, or sensitivity
10. Limitations, critique, or takeaways

Notes:

- Spend at least two pages before deep design if the motivation depends on concrete pathologies or production constraints.
- If the system has two or more independent mechanisms, give them separate slides instead of hiding them inside one summary page.
- Separate the main performance win from overhead or tradeoff evidence whenever both matter.

## 3. Chinese Paper Reading / Seminar

Use when the talk is a reading report, group seminar, or literature sharing.

Use this as the default Chinese seminar arc for non-systems papers. For systems papers, prefer `Systems Paper Reading / OSDI-SOSP Style` and then apply `chinese-academic-style.md` for wording.

Typical arc:

1. 研究背景
2. 论文要解决的问题
3. 方法概览
4. 方法细节
5. 实验结果
6. 论文评价 / 思考

## 4. Chinese Thesis Defense / Progress Report

Use when the user explicitly asks for 开题 / 中期 / 预答辩 / 答辩.

Typical arc:

1. 研究背景
2. 研究目标
3. 技术路线
4. 当前工作进展
5. 阶段性结果
6. 进度安排 / 后续计划

For progress or timeline pages, follow the narrative the user wants to present. Do not expose hidden completion status if the user asks for a different reporting口径.

## Selection Rule

- If the user names the occasion, follow the occasion.
- If the user only provides a paper PDF, default to `Systems Paper Reading / OSDI-SOSP Style` for systems papers and `General Paper Talk` otherwise.
- If the user wants Chinese academic style but does not specify a scenario, use `Systems Paper Reading / OSDI-SOSP Style` for systems papers and `Chinese Paper Reading / Seminar` otherwise.
