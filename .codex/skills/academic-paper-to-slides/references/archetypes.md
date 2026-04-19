<!-- Derived from archetypes.json. Edit the JSON spec, then regenerate this file. -->

# Slide Archetypes

Use a small set of reusable compositions. The goal is predictable, readable pages rather than one-off layouts.

## Selection Rules

- Default to simpler archetypes before inventing a custom composition.
- Choose by rendered geometry, not by semantic label alone.
- On figure-led slides, keep the figure as the main evidence; the text explains why it matters.
- Treat a two-line title on a dense evidence slide as a warning sign. Shorten the title before you start shrinking evidence or rewriting every box.
- Vary neighboring figure-heavy slides instead of repeating the same side-by-side pattern for an entire section.
- If a slide still needs too many words after choosing an archetype, split the material across slides.

## Title slide

Use when:

- the first slide should be handled entirely by the Lemonade title shell

Avoid when:

- you need to manually compose body content inside the title frame

Contract:

- Renderer: `title_slide`
- Allowed render modes: `script`
- QA rules:
  - first slide only
  - theme shell owns title layout

Notes:

- This archetype is emitted by the deck wrapper, not by per-slide body rendering.

## Outline / Roadmap

Use when:

- the audience needs a section roadmap or explicit talk structure

Avoid when:

- the slide is really a section divider with no usable roadmap items

Contract:

- Renderer: `outline_roadmap`
- Allowed render modes: `script, escape`
- Required fields:
  - `roadmap_or_bullets`: required
- Limits:
  - `boxes_max`: `1`
- QA rules:
  - clear section ordering
  - short roadmap labels

Notes:

- Use this only when the roadmap helps navigation. Do not add filler outline slides.

## Motivation / Background

Use when:

- the slide needs concise framing plus one supporting figure or one compact table

Avoid when:

- the slide is evidence-heavy enough to deserve a dedicated figure-led or table-led archetype

Contract:

- Renderer: `motivation_background`
- Allowed render modes: `script, escape`
- Limits:
  - `boxes_max`: `3`
  - `bullets_max`: `4`
- QA rules:
  - short setup text
  - do not bury the thesis in the background slide
- Fallbacks: `Figure-Led Vertical`, `Table-Led Structured Slide`

Notes:

- This is the catchment archetype for framing slides that still need one concrete supporting artifact.

## Figure-Led Vertical

Use when:

- one result figure or one pair of comparable figures should dominate the page
- the page only needs one or two short takeaways

Avoid when:

- the figure is horizontally wide and loses legibility when stacked
- the slide needs three substantial text points

Contract:

- Renderer: `figure_led_vertical`
- Allowed render modes: `script, escape`
- Required fields:
  - `asset_ids`: min_items=1, max_items=2
- Limits:
  - `boxes_max`: `2`
  - `bullets_max`: `3`
- QA rules:
  - no thumbnail evidence
  - short title
  - short caption
- Fallbacks: `Wide or Fat Evidence`, `Two-Up Comparison`

Notes:

- The caption identifies the figure. A dedicated takeaway box is optional if another short body box already carries the judgment.

## Method Overview Side-by-Side

Use when:

- one architecture or pipeline figure needs two to four short mechanism boxes
- the figure is tall enough to live in a side column

Avoid when:

- the figure is horizontally wide
- the figure is so short that the side column turns into dead whitespace
- the boxes have turned into paragraphs

Contract:

- Renderer: `method_side_by_side`
- Allowed render modes: `script, escape`
- Required fields:
  - `asset_ids`: min_items=1, max_items=1
- Limits:
  - `boxes_max`: `3`
  - `bullets_max`: `2`
- QA rules:
  - side evidence stays readable
  - mechanism boxes stay terse
- Fallbacks: `Method Overview With Stacked Evidence`, `Wide or Fat Evidence`

Notes:

- This is the default method archetype when the overview asset is tall or thin enough for a side column.

## Method Overview With Stacked Evidence

Use when:

- the method still benefits from text on the left and evidence on the right
- the available evidence is short, wide, or naturally split into overview plus zoom

Avoid when:

- the two right-column visuals are unrelated scraps collected only to fill space
- either panel becomes a thumbnail

Contract:

- Renderer: `method_stacked_evidence`
- Allowed render modes: `script, escape`
- Required fields:
  - `asset_ids`: min_items=2, max_items=2
- Limits:
  - `boxes_max`: `3`
  - `bullets_max`: `2`
- QA rules:
  - the two visuals read as one argument
  - stacked evidence remains legible
- Fallbacks: `Wide or Fat Evidence`, `Method Overview Side-by-Side`

Notes:

- Prefer already recovered companion assets or extraction-stage sub-assets over ad hoc late crops.
- Render stacked evidence columns with `#imgs(..., dir: ttb)` so the right-column visuals share the available height instead of each figure block filling it independently.

## Method Cards (2 or 3 Only)

Use when:

- the paper presents two or three named methods, stages, or operators and each one has its own figure
- each method deserves equal visual weight

Avoid when:

- there are four or more methods
- one method is much denser than the others
- any card needs more than one short text block plus one figure

Contract:

- Renderer: `method_cards`
- Allowed render modes: `script, escape`
- Required fields:
  - `cards_or_asset_ids`: required, asset_id_range=[2, 3], allowed_card_counts=[2, 3]
- Limits:
  - `boxes_max`: `1`
  - `cards_allowed`: `[2, 3]`
- QA rules:
  - equal visual weight across cards
  - no overloaded cards
- Fallbacks: `Method Overview Side-by-Side`, `Method Overview With Stacked Evidence`

Notes:

- Use two cards or three cards only. If a fourth item matters, split the slide.

## Two-Up Comparison

Use when:

- two panels have similar visual importance
- the comparison itself is the story

Avoid when:

- one panel is much denser than the other
- one panel is only supporting evidence and does not deserve equal area

Contract:

- Renderer: `comparison`
- Allowed render modes: `script, escape`
- Required fields:
  - `asset_ids`: min_items=2, max_items=2
- Limits:
  - `boxes_max`: `2`
  - `bullets_max`: `2`
- QA rules:
  - symmetric captions
  - comparable visual scale
- Fallbacks: `Figure-Led Vertical`, `Results Comparison`

Notes:

- Do not force several weakly related panels into one contact sheet just to keep them on one slide.

## Results Comparison

Use when:

- a results slide needs two equal-weight figures or one compact comparison table

Avoid when:

- the slide has only one dominant artifact and should be figure-led instead

Contract:

- Renderer: `comparison`
- Allowed render modes: `script, escape`
- Required fields:
  - `comparison_assets_or_table`: required, asset_id_min_items=2
- Limits:
  - `boxes_max`: `2`
  - `bullets_max`: `2`
- QA rules:
  - the comparison itself stays readable
  - supporting text stays secondary
- Fallbacks: `Figure-Led Vertical`, `Table-Led Structured Slide`

Notes:

- Use the table path only when a compact structured comparison is stronger than the figures.

## Table-Led Structured Slide

Use when:

- the source material is regular and tabular: setup, baselines, schedules, progress, ablations
- the audience needs precise structured comparison

Avoid when:

- the main evidence is a figure
- the table is becoming prose pasted into cells

Contract:

- Renderer: `table_structured`
- Allowed render modes: `script, escape`
- Required fields:
  - `table`: required
- Limits:
  - `boxes_max`: `3`
- QA rules:
  - short table cells
  - no tiny companion figure
- Fallbacks: `Progress or Status Matrix`, `Motivation / Background`

Notes:

- If a figure must share the slide and becomes tiny, the slide failed. Split the material.

## Wide or Fat Evidence

Use when:

- the source figure is horizontally wide
- the figure contains multiple horizontal stages or broad comparisons

Avoid when:

- the slide also needs a large table
- the page needs dense explanatory text
- the recovered figure is portrait-oriented or tall-thin enough to live comfortably in a side column

Contract:

- Renderer: `wide_evidence`
- Allowed render modes: `script, escape`
- Required fields:
  - `asset_ids`: min_items=1, max_items=2
- Limits:
  - `boxes_max`: `2`
  - `bullets_max`: `3`
- QA rules:
  - lower the text budget before lowering the figure size
  - wide evidence remains primary
- Fallbacks: `Figure-Led Vertical`, `Method Overview With Stacked Evidence`

Notes:

- This archetype is for actual width-dominant evidence. It is not the default for all overview figures.

## Equation-Led Explanation

Use when:

- one equation or derivation deserves dedicated attention
- notation and explanation need to stay adjacent

Avoid when:

- the equation is only a supporting detail and can stay inside a method or appendix slide

Contract:

- Renderer: `equation_led`
- Allowed render modes: `script, escape`
- Required fields:
  - `equation_or_equation_ids`: required
- Limits:
  - `boxes_max`: `3`
  - `bullets_max`: `3`
- QA rules:
  - equation remains legible
  - notation hints stay short
- Fallbacks: `Method Overview Side-by-Side`, `Motivation / Background`

Notes:

- Use this only when the equation materially advances the argument on that page.

## Conclusion / Takeaways

Use when:

- the deck needs a final compression of the argument into short claims and implications

Avoid when:

- the slide is still introducing new evidence that deserves its own page

Contract:

- Renderer: `conclusion_takeaways`
- Allowed render modes: `script, escape`
- Limits:
  - `boxes_max`: `4`
  - `bullets_max`: `4`
- QA rules:
  - no new unsupported claims
  - conclusion matches shown evidence

Notes:

- Optional supporting evidence is fine, but the summary boxes remain the main content.

## Progress or Status Matrix

Use when:

- the deck is a proposal, midterm, progress report, or defense
- the page needs to communicate status clearly and defensibly

Avoid when:

- the page should really be a method or results slide with evidence

Contract:

- Renderer: `table_structured`
- Allowed render modes: `script, escape`
- Required fields:
  - `table`: required
- Limits:
  - `boxes_max`: `3`
- QA rules:
  - status stays factual
  - interpretation stays outside status cells
- Fallbacks: `Table-Led Structured Slide`

Notes:

- Keep the table factual. Put interpretation in the summary box, not in the status cell.
