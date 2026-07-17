# English Academic Slide Writing

Use this reference for English-language decks. Target tone: concise, academic, restrained, like a senior researcher summarizing a result rather than narrating process.

For deck arc, section order, and scenario-specific structure, use `deck-structures.md`.
For slide-map field defaults, caption policy, and planning-time layout choices, use `planning-artifacts.md`.
For rendered pass/fail checks, use `visual-qa.md`.
This file is only about wording and sentence style.

## Sentence Principles

- Prefer short declarative sentences.
- Let each sentence carry one judgment, constraint, or result.
- Put the evidence and the conclusion close together.
- Prefer nouns and verbs over rhetorical connectors and narrative filler.
- If a sentence needs several commas, multiple clauses, or two rhetorical turns, split it into two sentences or two slides.

## Title Principles

- Prefer short noun-phrase titles over sentence titles.
- Keep titles tighter than body text; if a title wraps into a long line, shorten it instead of keeping the full claim.
- On dense method or figure slides, prefer a one-line title.
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
- When text feels dense, compact the sentence before changing the layout: drop obvious subjects, shorten helper verbs, and remove low-information transitions.
- In short takeaway boxes, prefer compact technical phrasing over long labels or code-like tokens when meaning can be preserved.
- Treat low-information phrasing as wording debt. Cut obvious lead-ins such as `Figure 4 shows`, `the figure above`, `we can see that`, or `it can be observed that`.

## Avoid

- process-narration openers such as `In this slide, we show ...`
- rigid chronological scaffolding such as `First ... Then ... Finally ...`
- unsupported praise such as `very significant` or `highly effective` without data
- openers such as `Figure 3 shows ...` when the sentence can state the takeaway directly
- body text that repeats the caption
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

Verbose:

- `Figure 9 shows the latency comparison under different workloads.`

Better:

- `Tokencake's latency advantage grows with load, which matches the memory-pressure thesis.`

Verbose title:

- `Our system reduces blocking on the critical path`

Better title:

- `Critical-Path Blocking`
