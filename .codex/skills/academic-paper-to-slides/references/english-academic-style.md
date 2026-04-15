# English Academic Slide Writing

Use this reference for English-language decks. Target tone: concise, academic, restrained, like a senior researcher summarizing a result rather than narrating process.

For deck arc, section order, and scenario-specific structure, use `deck-structures.md`. This file is only about wording and sentence style.

## Sentence Principles

- Prefer short declarative sentences.
- Let each sentence carry one judgment, constraint, or result.
- Put the evidence and the conclusion close together.
- Prefer nouns and verbs over rhetorical connectors and narrative filler.
- If a sentence needs several commas, multiple clauses, or two rhetorical turns, split it into two sentences or two slides.

## Title Principles

- Prefer short noun-phrase titles over sentence titles.
- Keep titles tighter than body text; if a title wraps into a long line, shorten it instead of keeping the full claim.
- Avoid turning the title into the full takeaway sentence; put the judgment in the body box instead.

## Preferred Tone

- concise
- direct
- technical
- evidence-led
- non-conversational
- restrained

## Good Habits

- Put the exact number and its implication in the same line when possible.
- On figure slides, body text explains why the figure matters; the caption identifies what the figure is.
- On figure-heavy slides, default to one or two short takeaway boxes; each box should preferably fit on one line and rarely exceed two.
- If the title plus two boxes would crowd the evidence, shorten the title, drop one box, or split the slide.
- When text feels dense, compact the sentence before changing the layout: drop obvious subjects, shorten helper verbs, and remove low-information transitions.
- In short takeaway boxes, prefer compact technical phrasing over long labels or code-like tokens when meaning can be preserved.

## Avoid

- process-narration openers such as `In this slide, we show ...`
- rigid chronological scaffolding such as `First ... Then ... Finally ...`
- unsupported praise such as `very significant` or `highly effective` without data
- body text that repeats the caption
- figure-heavy pages that mix one takeaway box with a loose paragraph
- long abstract-like paragraphs pasted onto a slide

## Example Rewrites

Verbose:

- `The results shown in the figure indicate that our method performs better across several datasets and therefore demonstrates strong effectiveness.`

Better:

- `The method improves all evaluated datasets, which suggests the gain is not workload-specific.`

Verbose:

- `The figure shows the overall system architecture.`

Better:

- `The system decouples communication reuse from state management, which improves both latency and cache efficiency.`

Verbose title:

- `Our system reduces blocking on the critical path`

Better title:

- `Critical-Path Blocking`
