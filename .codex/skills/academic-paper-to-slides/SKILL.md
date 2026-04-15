---
name: academic-paper-to-slides
description: Convert academic papers, preprints, and local PDF manuscripts into slide decks in the local lemonade Typst theme. Use when Codex is given a research paper or paper PDF and asked to draft, revise, or reorganize slides for paper readings, seminars, research overviews, proposal/midterm/final defenses, or other academic presentations.
---

# Academic Paper to Slides

Turn a paper into a presentation argument. Do not mirror the PDF page by page.

## Use This Skill To

- distill one paper or a small paper set into slides
- extract claims, figures, tables, and exact numbers from a PDF
- adapt the same source into different academic contexts such as seminar, reading report, overview, or defense

## Workflow

1. Determine the presentation type.
   - If the user names the occasion, follow it.
   - Otherwise default to a paper reading or seminar deck.
   - Match the requested language and speaking register.

2. Build a paper brief before writing slides.
   - Extract the title, problem, motivation, assumptions, main idea, method components, evaluation setting, and quantitative results.
   - Keep exact baselines, datasets, model names, metrics, and improvements.
   - Identify 3 to 6 paper-level claims that deserve their own slides.
   - Prefer the paper's own figures and tables over generated visuals.

3. Reorganize around claims, not section order.
   - A strong default arc is background, problem, method, evidence, conclusion.
   - Split method and results across more pages instead of compressing text.
   - Use tables when the source material is highly structured.
   - Each slide should make one main point.

4. Write at slide granularity.
   - Prefer a small set of stable slide archetypes over ad hoc mixes of boxes, paragraphs, tables, and figures.
   - The slide title names the topic in a short noun phrase, not a full sentence.
   - The body text states the takeaway, constraint, or contribution.
   - Compact wording before adding more layout complexity; remove filler and compress obvious subjects or helper verbs first.
   - On figure-led slides, stop a little short of the theoretical text maximum; one sentence less is usually better than one sentence too many.
   - On figure-led slides, do not mix one takeaway box with a loose explanatory paragraph; prefer one or two short takeaway boxes and let the figure carry the detail.
   - For method-overview slides with one architecture figure, prefer stacked short boxes beside the figure. Avoid table-plus-figure hybrids unless both remain clearly readable.
   - Figure captions identify the figure; they do not replace slide text.
   - Do not leave a title-plus-image-only slide.

5. Match the local presentation system.
   - Read workspace instructions first if the repo contains `AGENTS.md` or theme notes.
   - This skill is tailored to the local `lemonade.typ` theme, so reuse its macros, layouts, and deck conventions instead of inventing a parallel system.
   - For repo decks compiled with `typst compile --root .`, prefer root-relative imports such as `/lemonade.typ` and `/theme/...`; avoid fragile `../..` climbing imports.
   - Keep the top-of-file scaffold stable: theme import first, then language or local helpers, then `#show: lemonade-theme.with(...)`.
   - If a layout or helper problem appears across multiple slides, inspect the owning theme file first and prefer a theme-level fix over repeated per-slide workarounds.
   - Read `references/lemonade-theme.md` before drafting or revising slides in this repo.

6. Validate as a deck.
   - Compile the slides.
   - Screenshot figure-heavy pages and inspect scale, whitespace, and footer stability.
   - Do not exempt method-overview slides from figure review. If one slide contains both a table and an overview figure, verify that the figure is still readable at screenshot scale.
   - On figure-led slides, especially fat or wide layouts, treat figure readability as the hard constraint and keep text below the point where the figure becomes postcard-sized.
   - On horizontal figure slides, keep the default text size unless there is a strong reason not to; first shorten the wording and fix the layout so the text column wraps naturally.
   - If a side-by-side slide does not wrap text cleanly, check whether the image helper is bleeding outside its column; prefer in-cell image placement over shrinking text.
   - If a figure is too small, crop, split, or change layout instead of shrinking text.
   - If a figure has shrunk to icon size because a table consumed the page, convert the table to short boxes or split the material across slides.
   - Fix accidental blank continuation pages, broken outlines, and overflowed footer content.

## Writing Guidance

- For reusable deck arcs, read `references/deck-structures.md`.
- For concise academic Chinese sentence style, read `references/chinese-academic-style.md`.
- Treat concise short boxed takeaways as the benchmark for figure-led pages: ideally one short line per box, and rarely more than two.

Target tone:

- concise
- academic
- declarative
- evidence-led
- restrained

Avoid:

- section-by-section retelling of the paper
- student-style narration
- empty praise without data
- body text that repeats the caption
- dense paragraphs when a table or extra slide is clearer
