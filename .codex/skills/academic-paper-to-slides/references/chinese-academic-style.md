# Chinese Academic Slide Writing

Use this reference for Chinese-language decks. Target tone: concise, academic, restrained, like a senior professor summarizing a result rather than a student narrating process.

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
- Remove filler or weak particles such as `了`, `可以`, `会`, `已经`, `正在` unless they change the meaning materially.
- Avoid turning the title into the full takeaway sentence; put the judgment in the body box instead.

## Preferred Tone

- concise
- direct
- technical
- evidence-led
- non-conversational
- restrained

## Good Habits

- Put exact numbers and the corresponding conclusion in the same sentence when possible.
- On figure slides, body text explains why the figure matters; the caption identifies what the figure is.
- On figure-heavy slides, default to one or two short takeaway boxes; each box should preferably fit on one line and rarely exceed two.
- 优先让 box 保持单行；如果换行，先重写句子，再考虑改版式。
- 优先让 caption 保持单行；如果 caption 换行，先缩短文字，必要时再略微放宽图块宽度，但不要牺牲证据可读性。
- If the title plus two boxes would crowd the evidence, shorten the title, drop one box, or split the slide.
- When text feels dense, compact the sentence before changing the layout: drop obvious subjects, shorten helper verbs, and remove low-information transitions.
- In short takeaway boxes, prefer compact Chinese phrasing over long mixed-language labels or code-like tokens when meaning can be preserved.
- 把低信息量表述当作版面负担处理，优先删除诸如 `图 3 展示了`、`从图中可以看出`、`我们可以发现` 这类起手句。

## Avoid

- process-narration openers such as `接下来我们来看`
- rigid chronological scaffolding such as `本文首先...然后...最后...`
- unsupported praise such as `非常重要` or `十分显著` without evidence
- `图 X 展示了 ...` 这类可以直接改写为结论句的句式
- body text that repeats the caption
- figure-heavy pages that mix one takeaway box with a loose paragraph
- long paragraphs that read like an abstract pasted onto a slide

## Example Rewrites

Verbose:

- `从实验结果可以看出，该方法在多个数据集上都取得了比较好的效果，说明其具有一定的有效性。`

Better:

- `多组数据集上均取得稳定增益，说明该机制并非依赖单一工作负载。`

Verbose:

- `图中展示了系统整体架构。`

Better:

- `系统将通信复用与差分存储解耦，实现了时延与显存的同时优化。`

Verbose:

- `图 9 展示了不同负载下的时延对比结果。`

Better:

- `负载越高，Tokencake 的时延优势越明显，说明收益来自显存压力场景。`

Verbose title:

- `Tokencake 减少了关键路径上的异常阻塞`

Better title:

- `关键路径阻塞`
