---
skill: academic-paper-to-slides
date: 2026-08-22
source: Codex history audit
status: adopted
---

# Existing-deck edits over-triggered generation

Observed: Timely follow-up tasks for page edits, `vstack` refactoring, LPU arrows, legends, spacing, and page count repeatedly loaded the paper-to-slides entry and long planning, archetype, theme, and QA references.

Expected: Once the initial deck exists, handle focused content, layout, theme, and validation work directly. Re-enter the generation workflow only for an explicit source-driven rebuild.

Scope: This applies to post-handoff deck maintenance. It does not exclude a new paper-derived deck or a user-requested rebuild of the narrative and evidence plan from paper sources.

Evidence:

- Timely comparison and task-graph thread `01a00a09-872a-7c52-91e6-b112104fb2b8` loaded the full workflow even though it modified an existing deck.
- Narrow nested-code-to-`vstack` thread `01a00fac-e55a-7c30-ae2c-f8c954485e0e` loaded the entry, theme guidance, the full archetype catalog, and visual QA.
- Page 23/24 thread `01a00f6d-5958-7f83-9e29-31b50ada6a3d` and LPU thread `01a0193d-5def-7d03-ba94-552e1ba7d7f7` repeated the same reads after the user rejected a skill round trip.

Decision: Narrow automatic routing to `paper -> initial deck`; keep later corrections as feedback evidence instead of runtime instructions.
