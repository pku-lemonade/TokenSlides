# Planning Artifacts

Use this reference after workspace initialization and before drafting Typst. This file owns artifact order, artifact responsibilities, slide-map field semantics, and planning-time rules.

For deck arc selection and pacing, use `deck-structures.md`.
For composition choice, use `archetypes.md`.
For Lemonade helper behavior, use `lemonade-theme.md`.
For final acceptance, use `visual-qa.md`.

## Artifact Order

Complete the planning artifacts in this order and keep them as one planning phase before writing Typst:

```text
Artifact Progress:
- [ ] Initialize `notes/assets.json`, `notes/brief.json`, `notes/slides.json`, `notes/review.json`
- [ ] Extract paper text to `notes/source.txt` and update `notes/assets.json`
- [ ] Recover likely visuals and register them in `notes/assets.json`
- [ ] Write `notes/brief.json` from the paper text and asset registry
- [ ] Write `notes/slides.json` with evidence and archetypes
- [ ] Render `notes/asset-manifest.md`, `notes/brief.md`, and `notes/slide-map.md` from JSON
```

- Produce the artifacts in order: JSON skeletons, `notes/source.txt`, `notes/assets.json`, `notes/brief.json`, `notes/slides.json`, then the derived Markdown notes.
- Finish the JSON artifacts before drafting slides.

## Source Text

- Save a reproducible plain-text extraction of the paper to `out/<paper>/notes/source.txt`.
- Use `scripts/paper_artifacts.py extract-source <paper.pdf> --workspace out/<paper>` so `notes/assets.json` records the extractor and page count.
- Prefer a layout-preserving extraction such as `pdftotext -layout` when available.
- Treat `notes/source.txt` as the audit trail for exact wording and numbers used in the brief and slides.

## Asset Registry

- Start with an initial asset recovery pass.
- Prefer the paper's own figures and tables over generated visuals.
- Run recovery early so the deck is planned against real assets.
- Recover all likely reusable slide assets early. Save detailed cleanup for the subset that survives into the final deck.
- If a paper figure likely needs to be split across slides or stacked beside method text, recover the promising sub-assets during the extraction pass rather than assuming a late crop-prep step will solve the layout.
- Delegate PDF or deck figure recovery to `figure_extractor`.
- When you already know the figure number, page, or rough target region, pass that hint to `figure_extractor` and expect `bbox` and `primary_output` back.
- Treat `figure_extractor` as script-first infrastructure. If figure recovery behavior is wrong, fix the extraction skill or script instead of adding parent-side PDF extraction workarounds.
- When `inspect-page` reveals several image candidates on one page, recover the likely reusable sub-assets as stable files during this pass instead of only capturing the whole figure group.
- Prefer candidate-level recovery for obvious left/right or top/bottom panels so later slide planning can reuse them without manual bbox work.
- Record each recovered asset in `out/<paper>/notes/assets.json`, then re-render `notes/asset-manifest.md`.
- Keep all likely candidates in the registry even if some will not be used later.
- Use `scripts/paper_artifacts.py upsert-asset --workspace out/<paper> ...` when you have capture metadata from `figure_extractor`.
- For each entry capture: stable `asset_id`, asset type, source file, page number, `bbox`, capture kind, `primary_output`, normalized caption, dimensions when available, candidate slide roles, and whether follow-up cleanup or additional sub-asset recovery is likely.
- Treat equations as first-class assets when a derivation or notation block must be planned explicitly.

## Brief (`notes/brief.json`)

- Build `notes/brief.json` after the asset registry so the brief can refer to recovered visuals instead of rediscovering them later.
- Use the asset registry plus the paper text as the source of truth for available visuals.
- Capture the title, problem, motivation, assumptions, main idea, method components, evaluation setting, and quantitative results.
- Keep exact baselines, datasets, model names, metrics, and improvements.
- Reorganize around claims, not the paper's section order.
- Identify 3 to 6 deck-level claims.
- Do not collapse a multi-part design story into one generic method claim. Break out motivating failures, overview, and each major mechanism or policy into separate claims when the paper supports them.
- In `mechanisms`, inventory every major mechanism, component, policy, or stage that materially supports the thesis. Do not stop at the headline two if the paper also depends on coordination, runtime, or supporting control steps.
- Inventory which mechanisms and results are best supported by recovered assets versus exact textual evidence.
- Note which mechanisms have direct validating evidence nearby in the paper, such as dedicated figures, equations, algorithms, ablations, overheads, robustness checks, or sensitivity plots.
- Treat any uncovered major mechanism as a planning failure to resolve before drafting slides.
- Add an evidence map that links claim ids to asset ids and text anchors before drafting.

## Slide Map (`notes/slides.json`)

- Write the canonical slide plan in `notes/slides.json`, then render `notes/slide-map.md` for inspection.
- Store for each slide: `slide_id`, section, title, `rhetorical_role`, `archetype`, one-slide-one-claim takeaway, `claim_ids`, evidence, `asset_ids`, optional `equation_ids`, `content_density`, and `qa_expectations`.
- Add richer layout fields only when the archetype needs them:
  - `boxes`: ordered short box content for method, result, and conclusion slides
  - `bullets`: short follow-on list items
  - `table`: `headers`, `rows`, and optional `columns` / `align`
  - `cards`: 2 or 3 card specs for `Method Cards`
  - `equation`: local equation content when `equation_ids` alone are not enough
  - `takeaway_mode`: `auto`, `box`, or `none`
  - `asset_caption_mode`: `short`, `full`, or `none`
  - `asset_captions`: per-asset caption overrides; use an empty string to suppress one caption explicitly
- Let each slide defend one claim.
- Assign evidence from the asset registry or from exact numbers in the paper before writing the slide.
- Follow `deck-structures.md` for deck arc and pacing. When the chosen arc is expanded, break major mechanisms into separate slides and keep direct validating evidence or tradeoffs nearby.
- Include a positioning slide when the prior-work gap is part of the argument.
- Choose a stable slide archetype for each page from `references/archetypes.json`. Treat `references/archetypes.md` as the derived human reference.
- Use `render_mode: "escape"` only for exceptional slides that need layout freedom beyond the scripted emitter.
- Keep `escape_hint` short and concrete. Treat it as a terse body-layout instruction, not a prose brief.
- When a slide uses `render_mode: "escape"`, collect its payload with `scripts/paper_artifacts.py collect-escape-context --workspace out/<paper>` and generate the fragment in the main Codex context instead of from inside the script.
- Write escape fragments to `out/<paper>/fragments/<slide_id>.typ` before deck emission unless the slide explicitly overrides the fragment path.
- Prefer titles that will stay on one line once drafted. If a slide-map title is already long, shorten it before layout work.
- Keep `takeaway` canonical in JSON even when the rendered slide does not use a dedicated takeaway box.
- Use `takeaway_mode: auto` by default. Use `box` when the slide needs an explicit top takeaway box. Use `none` when another short body line or box already carries the judgment.
- Captions default to a short form. Use `asset_caption_mode: full` only when the longer caption earns the space.
- For Chinese decks with paper-derived figures, default to `asset_caption_mode: short` on figure-bearing slides.
- Use `asset_caption_mode: none` or an empty `asset_captions` override only when the figure is unmistakable without a caption and the page budget is genuinely tight.
- Plan takeaways and captions as short lines. If a slide already uses body boxes, keep additional support inside the box system instead of introducing loose bullets as a third text style.

