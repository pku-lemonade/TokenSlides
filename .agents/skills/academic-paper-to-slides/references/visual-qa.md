# Visual QA

Use this rubric after the deck compiles. A slide that technically compiles can still fail visually.
Use `archetypes.md` for composition choice and `lemonade-theme.md` for helper usage; this file is only the rendered acceptance rubric.

## Compile Pass

- `typst compile --root . <deck>.typ <out.pdf>` succeeds.
- The deck has no accidental continuation pages, especially title-only pages or orphaned body fragments created by overflow.
- The outline and footer still render correctly.
- Footer metadata does not wrap, clip, or collide with the counter; long author or institution strings must still produce a stable one-line footer or trigger a theme-level fix.

## Story Pass

- Each slide makes one main point.
- Every evidence-led slide has an explicit takeaway in the body, not only in the caption.
- The takeaway does not need to be a dedicated `Takeaway` box if another short visible box or body line already states the judgment.
- The deck argues by claims, not by replaying the paper section order.

## Figure Pass

- The main figure is readable at screenshot scale.
- Generated figures are grounded in the slide's `visual_evidence` and do not invent metrics, labels, or claims.
- Generated figures use a consistent visual language within the deck and meet polished ACM SOSP/OSDI lecture-diagram quality.
- If the source asset needed cleanup, the crop was prepared reproducibly rather than by ad hoc repeated edits.
- Cropping removes paper chrome such as page headers, line numbers, original captions, neighboring columns, and unrelated panels.
- Cropping does not remove axes, legends, low-edge labels, arrow endpoints, or other necessary annotations.
- If the figure reads like a small footer illustration rather than the slide's main evidence, the slide fails.

## Restraint Pass

- The slide begins with the theme's established boxes, rows, tables, bullets, figures, and listings. A custom surface or one-off shape family must encode information that those primitives cannot.
- Visual emphasis follows semantic importance. A slide fails when several unrelated fills, borders, title treatments, or decorative containers compete at the same level.
- A reference-like, workmanlike composition is preferable to a more elaborate treatment when both communicate the same hierarchy.

## Box Pass

- Primary box body copy is visually at least as large as the deck's normal body copy. Smaller text is reserved for genuinely secondary metadata, captions, or citations.
- Box titles at the same semantic level use a consistent size, weight, fill, and inset. A title must not become smaller merely because one label is longer; shorten or wrap the label instead.
- Text has visible padding on every framed side, but the padding does not dwarf the body. A short body is vertically centered unless top alignment communicates a meaningful sequence or list.
- A box fails when its text sits in one corner while most of the frame is empty, when a narrow track creates avoidable wrapping beside unused page space, or when a large internal margin substitutes for proper spacing between boxes.
- Manual wrapping respects phrase boundaries and produces visually comparable line lengths. Treat an avoidable one-word or 1-4-character final line, unexplained hanging indentation, or a line less than roughly half the length of its neighbor as a defect; rewrite or resize before forcing another break.
- Check inner and outer whitespace separately: tighten excessive box padding, but use deliberate gaps between groups to show hierarchy. Do not make every gap uniformly small.
- On an underfilled slide, first rebalance row/column tracks and box dimensions, then remove redundant wrappers or helper labels, then reduce only excessive padding, and finally adjust the owning theme/component or deck-local canvas. Do not shrink the whole composition and leave larger page-edge whitespace.
- On an overfull slide, compact wording or split the material before reducing type. A successful fit with primary box copy visibly below body size still fails.

## Diagram Pass

- Every edge corresponds to a stated relationship, and every stated relationship that the diagram promises to show has an edge. Decorative or semantically incomplete connectors fail.
- Connector endpoints meet deliberate anchors on box boundaries; they do not stop short, float near a box, enter through title text, or disappear behind a frame.
- Line weight and arrowheads remain obvious at screenshot scale. Arrowheads are proportional to their lines and do not overwhelm the target box.
- One relationship type keeps one color, line style, direction convention, and label treatment across the slide or sequence.
- Prefer short, direct routes with few crossings. If an edge needs a long curve or crosses several unrelated objects, rearrange the nodes before accepting the route.
- Edge labels are concise, use the deck language consistently, and remain clear of boxes, arrowheads, and other labels.

## Layout Pass

- Figure-led slides do not mix one takeaway box with a loose paragraph.
- Not every slide needs a dedicated takeaway box.
- When a figure-led slide does use takeaway boxes, each one should preferably fit on one line and should rarely exceed two.
- Captions should preferably fit on one line. If a caption wraps, shorten it or slightly widen the figure block only if figure readability is preserved.
- One-figure slides do not stack so much text above the figure that the evidence collapses.
- Count title, boxes, and caption together. If they leave the evidence as a thumbnail or narrow strip, the slide fails even if each box is individually short.
- Composite contact-sheet figures get split or re-cropped when the full sheet becomes unreadable at deck scale.
- Table-plus-figure slides only pass if both remain clearly readable.
- Side-by-side slides wrap text cleanly and keep the figure inside its column.
- Method-overview side-by-side slides only pass if the evidence column looks intentional: one tall figure, one tall crop, or a balanced vertical stack. A short centered image with large dead whitespace fails.

## Language Pass

- Chinese decks follow `chinese-academic-style.md`.
- English decks follow `english-academic-style.md`.
- Titles stay short and do not turn into long claim sentences.
- On dense slides, a two-line title is a warning sign; if it creates a continuation page, the slide fails.

## Fix Order

For underfilled box-led slides, use the repair order in Box Pass. The sequence below is for crowded slides or slides whose evidence has become too small.

1. Reuse another recovered asset or change the slide archetype.
2. If the right evidence is missing, produce a better generated asset or recover/split a better extracted source asset according to `figure_source_mode`.
3. If a generated figure is close but inaccurate or inconsistent, revise the prompt and regenerate/edit once before changing the slide layout.
4. If an extracted asset shape is close but still carries chrome or awkward margins, rerun `scripts/prepare_figure.py` with a better anchor, margin, or mode.
5. Compact the wording.
6. Split the slide.
7. Only then consider a justified helper or theme override; never shrink primary copy below normal body size merely to make the page fit.
