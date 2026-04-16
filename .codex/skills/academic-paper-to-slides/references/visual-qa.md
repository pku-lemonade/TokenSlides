# Visual QA

Use this rubric after the deck compiles. A slide that technically compiles can still fail visually.

## Compile Pass

- `typst compile --root . <deck>.typ <out.pdf>` succeeds.
- The deck has no accidental continuation pages, especially title-only pages or orphaned body fragments created by overflow.
- The outline and footer still render correctly.

## Story Pass

- Each slide makes one main point.
- Every evidence-led slide has an explicit takeaway in the body, not only in the caption.
- The deck argues by claims, not by replaying the paper section order.

## Figure Pass

- The main figure is readable at screenshot scale.
- If the source asset needed cleanup, the crop was prepared reproducibly rather than by ad hoc repeated edits.
- Cropping removes paper chrome such as page headers, line numbers, original captions, neighboring columns, and unrelated panels.
- Cropping does not remove axes, legends, low-edge labels, arrow endpoints, or other necessary annotations.
- If the figure reads like a small footer illustration rather than the slide's main evidence, the slide fails.

## Layout Pass

- Figure-led slides do not mix one takeaway box with a loose paragraph.
- On figure-led slides, each takeaway box should preferably fit on one line and should rarely exceed two.
- Captions should preferably fit on one line. If a caption wraps, shorten it or slightly widen the figure block only if figure readability is preserved.
- One-figure slides do not stack so much text above the figure that the evidence collapses.
- Count title, boxes, and caption together. If they leave the evidence as a thumbnail or narrow strip, the slide fails even if each box is individually short.
- Composite contact-sheet figures get split or re-cropped when the full sheet becomes unreadable at deck scale.
- Table-plus-figure slides only pass if both remain clearly readable.
- Side-by-side slides wrap text cleanly and keep the figure inside its column.
- Method-overview side-by-side slides only pass if the evidence column looks intentional: one tall figure, one tall crop, or a balanced vertical stack. A short centered image with large dead whitespace fails.
- If the slide could be fixed by reusing another recovered asset or extraction-stage sub-asset, do that before reaching for post-processing crop cleanup.
- Adjacent figure-heavy slides do not all reuse the exact same archetype unless the content truly demands it.
- Ordinary figure layout should use the theme helper. A deck-local replacement helper is a smell unless `theme/images.typ` truly lacks the needed behavior.
- Body boxes and captions should not spend space on low-information phrasing such as `Figure X shows ...` or obvious restatements of what the viewer can already see.

## Language Pass

- Chinese decks follow `chinese-academic-style.md`.
- English decks follow `english-academic-style.md`.
- Titles stay short and do not turn into long claim sentences.
- On dense slides, a two-line title is a warning sign; if it creates a continuation page, the slide fails.

## Fix Order

1. Reuse another recovered asset or change the slide archetype.
2. If the right evidence is missing, recover or split a better source asset.
3. If the asset shape is close but still carries chrome or awkward margins, rerun `scripts/prepare_figure.py` with a better anchor, margin, or mode.
4. Compact the wording.
5. Split the slide.
6. Only then consider local helper overrides or text-size changes.
