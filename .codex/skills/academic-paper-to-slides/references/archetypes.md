# Slide Archetypes

Use a small set of reusable compositions. The goal is predictable, readable pages rather than one-off layouts.

## Selection Rules

- Default to simpler archetypes before inventing a custom composition.
- On figure-led slides, keep the figure as the main evidence; the text explains why it matters.
- Treat a two-line title on a dense evidence slide as a warning sign. Shorten the title before you start shrinking evidence or rewriting every box.
- Vary neighboring figure-heavy slides instead of repeating the same side-by-side pattern for an entire section.
- If a slide still needs too many words after choosing an archetype, split the material across slides.

## 1. Figure-Led Vertical

Use when:

- one result figure or one pair of comparable figures should dominate the page
- the page only needs 1 or 2 short takeaways

Avoid when:

- the figure is horizontally wide and loses legibility when stacked
- the slide needs 3 substantial text points

```typst
#ibox[
  *Takeaway:* ...
]

#hbox[
  *Key number:* ...
]

#imgs(
  (asset("result.jpg"), [What the figure is]),
  width: 90%,
)
```

Notes:

- Keep the stacked text tight. Each takeaway box should preferably fit on one line and should rarely exceed two.
- Count total page budget, not only box count. The combined boxed text above the figure should usually stay within about 2 to 4 wrapped lines total.
- Count the title and caption as part of the same visual budget. A long title plus two 2-line boxes is already close to the limit, so split the slide or recrop the evidence early.
- Captions should preferably fit on one line. Shorten them before accepting a wrapped caption; only widen the figure block if the figure still reads well.
- If the evidence turns into a thumbnail or narrow strip, change archetype, crop or split the figure, or split the slide.
- The caption identifies the figure. The box carries the judgment.

## 2. Method Overview Side-by-Side

Use when:

- one architecture or pipeline figure needs 3 or 4 short mechanism boxes
- the figure is tall enough to live in a side column or can be cropped into a tall evidence slice

Avoid when:

- the figure is horizontally wide
- the figure is so short that the side column turns into dead whitespace
- the boxes have turned into paragraphs

```typst
#grid(
  columns: (1.05fr, 0.95fr),
  gutter: 0.8em,
  [
    #ibox[*Core idea:* ...]
    #hbox[*Step 1:* ...]
    #nbox[*Step 2:* ...]
    #sbox[*Step 3:* ...]
  ],
  [
    #imgs(
      (asset("overview.jpg"), [System overview]),
      width: 100%,
      fill-height: false,
      cap-size: 16pt,
    )
  ],
)
```

Notes:

- This is the default method slide for architecture papers in this repo.
- Keep mechanism boxes terse and preferably single-line. If 3 or 4 boxes cannot stay short, split the content into an overview slide and one or more mechanism slides.
- The evidence column should feel vertically intentional. One tall figure is good; one short centered figure floating in whitespace is not.
- If the figure shrinks below readable size, first check whether the manifest already has another compatible asset or sub-asset from the same source. Then switch to a wide figure page, use the stacked-evidence variant below, or split the method across two slides.

## 2b. Method Overview With Stacked Evidence

Use when:

- the method still benefits from text on the left and evidence on the right
- the available evidence is short, wide, or naturally split into overview plus zoom
- two related visuals together tell the mechanism better than one undersized side figure

Avoid when:

- the two right-column visuals are unrelated scraps collected only to fill space
- either panel becomes a thumbnail

```typst
#grid(
  columns: (1fr, 1fr),
  gutter: 0.8em,
  [
    #ibox[*Core idea:* ...]
    #hbox[*Mechanism A:* ...]
    #nbox[*Mechanism B:* ...]
  ],
  [
    #imgs(
      (asset("overview.jpg"), [Overall pipeline]),
      width: 100%,
      fill-height: false,
    )
    #v(0.6em)
    #imgs(
      (asset("zoom.jpg"), [Critical submodule or zoomed path]),
      width: 100%,
      fill-height: false,
    )
  ],
)
```

Notes:

- This is the preferred fallback when the default side-by-side method slide leaves a short figure stranded in whitespace.
- Good right-column pairings include overview plus zoom, architecture plus operator table, or pipeline plus one critical stage.
- Prefer already recovered assets or extraction-stage sub-assets over ad hoc late crops.
- If only one source figure exists and no companion asset is available, try a tighter tall crop or extract a smaller reusable sub-asset from the source figure before falling back to post-processing cleanup.
- Otherwise switch to `Wide or Fat Evidence` instead of faking a stack.
- The stack should read as one argument, not two separate slides squeezed together.

## 3. Two-Up Comparison

Use when:

- two panels have similar visual importance
- the comparison itself is the story: two workloads, two baselines, before/after

Avoid when:

- one panel is much denser than the other
- one panel is only supporting evidence and does not deserve equal area

```typst
#ibox[
  *Comparison:* ...
]

#hbox[
  *Implication:* ...
]

#imgs(
  (asset("left.jpg"), [Condition A]),
  (asset("right.jpg"), [Condition B]),
  width: 100%,
  gap: 0.8em,
)
```

Notes:

- Use symmetric captions and similar cropping.
- Prefer one-line captions for both panels so the comparison reads as one unit.
- Do not force several weakly related panels into one contact sheet just to keep them on one slide.
- If one panel needs a different scale, do not force this archetype.

## 4. Table-Led Structured Slide

Use when:

- the source material is regular and tabular: setup, baselines, schedules, progress, ablations
- the user needs precise structured comparison

Avoid when:

- the main evidence is a figure
- the table is becoming prose pasted into cells

```typst
#ibox[
  *Setup:* ...
]

#table(
  columns: (1fr, 2fr),
  inset: 8pt,
  align: (left, left),
  [*Item*], [*Detail*],
  [...], [...],
  [...], [...],
)
```

Notes:

- If a figure must share the slide and becomes tiny, the slide failed. Replace the table with short boxes or split the material.
- Prefer short noun phrases inside cells instead of paragraph-length explanations.

## 5. Wide or Fat Evidence

Use when:

- the source figure is horizontally wide
- the figure contains multiple horizontal stages or broad comparisons

Avoid when:

- the slide also needs a large table
- the page needs dense explanatory text

```typst
#ibox[
  *Main point:* ...
]

#imgs(
  (asset("wide-figure.jpg"), [What the wide figure shows]),
  width: 100%,
)
```

Notes:

- Lower the text budget before lowering the figure size.
- If the figure still reads like a small footer illustration, crop tighter, change the evidence split, or dedicate another slide.

## 6. Progress or Status Matrix

Use when:

- the deck is a proposal, midterm, progress report, or defense
- the page needs to communicate status clearly and defensibly

Avoid when:

- the page should really be a method or results slide with evidence

```typst
#sbox[
  *Stage summary:* ...
]

#table(
  columns: (1.35fr, 0.8fr, 2fr),
  inset: 8pt,
  align: (left, left, left),
  [*Work item*], [*Status*], [*Meaning*],
  [...], [...], [...],
  [...], [...], [...],
)
```

Notes:

- Match the reporting line the user wants to present.
- Keep the table factual. Put interpretation in the summary box, not in the status cell.
