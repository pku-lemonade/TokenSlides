# Paper-to-slides workflow artifacts

What the `academic-paper-to-slides` skill writes, the helper commands behind
it, and how a generated deck is validated. Paths are relative to the
repository root; the skills live under `.agents/skills/`.

## Workspace layout

The paper-to-slides skill keeps each paper self-contained:

- `out/<paper>/<paper>.typ`
- `out/<paper>/notes/source.txt`
- `out/<paper>/notes/assets.json`
- `out/<paper>/notes/brief.json`
- `out/<paper>/notes/slides.json`
- `out/<paper>/notes/review.json`
- `out/<paper>/notes/asset-manifest.md`
- `out/<paper>/notes/brief.md`
- `out/<paper>/notes/slide-map.md`
- `out/<paper>/assets/...`

The JSON files are canonical. The Markdown notes are derived inspection artifacts rendered from that JSON so the planning state stays machine-checkable.

This keeps crops, extracted figures, and deck notes out of shared top-level folders.

## Helper commands

Initialize a paper workspace and JSON artifacts:

```bash
python3 .agents/skills/academic-paper-to-slides/scripts/paper_artifacts.py \
  init-workspace paper.pdf --workspace out/<paper>
```

Extract source text into `notes/source.txt`:

```bash
python3 .agents/skills/academic-paper-to-slides/scripts/paper_artifacts.py \
  extract-source paper.pdf --workspace out/<paper>
```

Re-render the human-readable notes after editing `assets.json`, `brief.json`, or `slides.json`:

```bash
python3 .agents/skills/academic-paper-to-slides/scripts/paper_artifacts.py \
  render-notes --workspace out/<paper>
```

Emit a deterministic Typst scaffold from `notes/slides.json`:

```bash
python3 .agents/skills/academic-paper-to-slides/scripts/paper_artifacts.py \
  emit-deck --workspace out/<paper>
```

Disable escape fragments and force scripted layouts for all slides:

```bash
python3 .agents/skills/academic-paper-to-slides/scripts/paper_artifacts.py \
  emit-deck --workspace out/<paper> --disable-escape
```

The emitter is archetype-aware rather than fully generic. The canonical archetype contract now lives in [`.agents/skills/academic-paper-to-slides/references/archetypes.json`](../.agents/skills/academic-paper-to-slides/references/archetypes.json). The human-facing [`archetypes.md`](../.agents/skills/academic-paper-to-slides/references/archetypes.md) is derived from that JSON spec.

Slides can carry:

- `archetype`, `asset_ids`, and `equation_ids`
- richer layout fields such as `boxes`, `bullets`, `table`, `cards`, and `equation`
- `render_mode: "script" | "escape"`
- short `escape_hint` instructions when `render_mode` is `escape`

For escape slides, collect the exact payload the main Codex context should render into a fragment:

```bash
python3 .agents/skills/academic-paper-to-slides/scripts/paper_artifacts.py \
  collect-escape-context --workspace out/<paper>
```

Write the fragment to `out/<paper>/fragments/<slide_id>.typ`, then run `emit-deck`. The script only consumes fragment artifacts; it does not make its own model call.

Regenerate the derived archetype reference:

```bash
python3 .agents/skills/academic-paper-to-slides/scripts/paper_artifacts.py \
  render-archetypes-ref
```

## Validating a deck

Compile a deck directly:

```bash
typst compile --root . out/<paper>/<paper>.typ /tmp/out.pdf
```

Compile every reference and example deck, failing on errors and warnings:

```bash
scripts/check.sh            # docs/ and examples/
scripts/check.sh --out      # plus every deck under out/
scripts/check.sh --coverage # every public theme name appears in a docs/ deck
```

Use the repo helper when you want a validation PDF in a stable temp location:

```bash
bash .agents/skills/academic-paper-to-slides/scripts/validate_deck.sh \
  out/<paper>/<paper>.typ
```

The validation helper writes the PDF under `/tmp/academic-paper-to-slides/` by default, validates JSON artifacts when a paper workspace exists, renders page previews, and writes review findings to `notes/review.json` or `review/review.json`.

When `slides.json` is present, the rendered-page review accounts for Lemonade outline pages inserted by `=` section headings. Expected rendered page count can therefore be larger than planned slide count.

If a deck compile fails and the workspace contains escape-mode slides, the validation helper retries once by re-emitting the deck with `--disable-escape`. The rendered review records that fallback in `review.json`.
