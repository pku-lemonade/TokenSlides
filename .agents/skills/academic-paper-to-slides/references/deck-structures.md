# Common Deck Structures

Treat these as deck arcs, not literal one-slide-per-section templates. Convert the chosen arc into a slide map before writing Typst.

For artifact responsibilities and slide-map field guidance, use `planning-artifacts.md`.

## 1. Systems Paper Reading / OSDI-SOSP Style

Use when the user asks for a paper presentation, reading report, or seminar without a defense-specific context.

This is the default paper-reading arc in this skill. Treat it as coverage-first when the paper has several mechanisms, moving parts, or nearby validating evidence.

Minimum narrative skeleton:

1. Research background or motivation
2. Problem definition or prior-work gap
3. Thesis and overview
4. Mechanism A
5. Mechanism B or policy detail
6. Evaluation setup and baselines
7. Main results
8. Overhead, robustness, or sensitivity
9. Limitations, critique, or takeaways

Expanded default when the paper has enough structure to support it:

1. Motivation or concrete failure
2. Why prior work misses it
3. Thesis and overview
4. Mechanism A
5. Mechanism A evidence or tradeoff, if present
6. Mechanism B
7. Mechanism B evidence or policy detail, if present
8. Mechanism C, runtime, or coordination detail, if present
9. Evaluation setup and baselines
10. Main results
11. Robustness, overhead, or limitations

Notes:

- Spend at least two pages before deep design if the motivation depends on concrete failures, pathologies, or operating constraints.
- If the paper has two or more independent mechanisms, give them separate slides instead of hiding them inside one summary page.
- If the paper has several distinct mechanisms or mechanism-specific evidence, prefer the expanded arc over the minimum skeleton.
- The majority of non-front-matter and non-back-matter slides should usually serve the design-related arc rather than a compressed overview-plus-results template.
- Treat overhead or tradeoff pages as optional companions to a mechanism, not mandatory filler when the paper does not present them.
- Separate the main performance win from overhead or tradeoff evidence whenever both matter.

## 2. Chinese Thesis Defense / Progress Report

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
- If the user only provides a paper PDF, default to `Systems Paper Reading / OSDI-SOSP Style`.
- If the user wants Chinese academic style but does not specify a scenario, use `Systems Paper Reading / OSDI-SOSP Style` plus `chinese-academic-style.md`.
