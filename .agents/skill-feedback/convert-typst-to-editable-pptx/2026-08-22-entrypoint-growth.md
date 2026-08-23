---
skill: convert-typst-to-editable-pptx
date: 2026-08-22
source: Codex history audit
status: adopted
---

# Conversion details accumulated in the entrypoint

Observed: The entry grew from 152 to 182 lines while reconstruction, typography, calibration, and QA details were also maintained in dedicated references. Written rules and the existing audits still allowed font, fill, and footer drift; the user caught those gaps in rendered comparison. Semantic text grouping did improve editability and remains a core invariant.

Expected: Keep the entry as a one-way routing contract. Put implementation and command detail in one authoritative reference per concern, and enforce measurable fidelity with scripts.

Scope: This applies to Typst-to-PPTX creation or regeneration. PPTX-only edits and audits belong to the presentation workflow; Typst-only edits belong to normal repo maintenance.

Evidence:

- Compiler-deck conversion thread `019f8dc1-3c52-7b50-a696-ad01ad67dd20` exposed font, fill, and footer gaps despite detailed written rules.
- Commits `e007d5e`, `40b4d18`, and `7dacb9e` grew the conversion contract and its reference detail in parallel.
- Commit `420e546` added the useful semantic-grouping invariant and a mechanical audit.

Decision: Keep native editability, semantic text grouping, no flattening, and actual-PPTX validation in the entry. Route detailed reconstruction and QA to existing references.
