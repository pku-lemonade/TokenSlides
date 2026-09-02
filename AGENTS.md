# Slides theme (Typst)

IMPORTANT: When unsure about Typst or Touying APIs, use Context7 and web search before changing behavior.

## Scope and source of truth

- The public entry point is `lemonade.typ`, which re-exports `theme/lemonade.typ`.
- A deck file owns content: claims, wording, item order, and which visual belongs on each slide. The theme owns reusable layout, typography, spacing, colors, and component behavior.
- Before editing a named slide, locate its current source and map it to the physical PDF page. Rebuild before trusting old page numbers because Touying overlays and inserted slides can shift them.
- For theme internals, the owning module's comments are the detailed implementation reference. Keep this file focused on behavior and acceptance criteria.
- `out/` is ignored. Treat an existing source there as authoritative only after checking the current workflow, and inspect its changes explicitly rather than relying on `git status`.

## Repository map

- `theme/lemonade.typ`: theme wrapper; wires Touying config and global `set`/`show` rules
- `theme/base.typ`: global layout, font, accent, mode, the resolved `theme()` runtime state, and shared config helpers (`layout-of`, `merge-config`, `resolve-parts`)
- `theme/slide.typ`, `theme/title.typ`, `theme/thank-you.typ`, `theme/outline.typ`, `theme/footer.typ`: slide shells and navigation
- `theme/boxes.typ`: box families plus `vboxs`, `vstack`, and the row-item protocol
- `theme/images.typ`: `img` plus `place-image`, `place-logo`, and `place-qr`
- `theme/code.typ`: listings, captions, line emphasis, numbering, and palettes; `theme/code-langs.typ`: `code-lang` specs and the built-in Python spec
- `theme/arrows.typ`: `solid-arrow`, `connector-arrow`, and `arrow-config`
- `theme/table.typ`: table styling and `vtable`
- `theme/assets.typ`: common logo and QR asset paths
- `docs/`: one compilable reference deck per theme module. Every public theme name appears in at least one of them (`scripts/check.sh --coverage` fails otherwise); update the owning deck when changing a public theme API
- `examples/`: complete sample decks (`paper-reading`, `seminar-zh`, `lecture`) that use only the public API

## Workflow boundaries

- `academic-paper-to-slides` is one-way: paper -> new slide material or an explicit source-driven rebuild. Do not invoke it for routine edits to an existing deck, theme work, validation-only work, or PowerPoint export.
- `convert-typst-to-editable-pptx` is one-way: Typst -> editable PowerPoint. Do not invoke it for later Typst-only or PPTX-only edits unless the user asks to regenerate PowerPoint from Typst.
- For routine post-handoff deck maintenance, edit the delivered `.typ` directly. Synchronize planning JSON, fragments, notes, or derived files only when the active workflow requires it or the user asks.
- Keep narrow visible fixes narrow. Do not turn a page-specific edit into regeneration, research, note maintenance, or unrelated cleanup.
- Record reusable skill failures under `.agents/skill-feedback/<skill>/YYYY-MM-DD-<slug>.md` only when maintaining that skill. Do not load feedback notes during ordinary deck work.

## Configuration contract

- Every user-tweakable theme dictionary is a top-level `#let <feature>-config` in the module it styles. The `-config` suffix is a machine contract used by design-system export tooling.
- Keep aspect-independent values flat, aspect-ratio variants under `layouts:`, and coherent groups in nested dictionaries.
- Put repeated style choices in the owning config or theme module. A value repeated on three or more slides is usually a missing theme default.
- Generated design-system profiles are disposable. Write them to an external scratch directory with an explicit `--output`; do not store snapshots under `.agents/skills/<skill>/references/`.

## Theme component contracts

### Rows and nested layout

- Use `vboxs` as the normal row for boxes, figures, and code. Side-by-side items receive equal-height cells; omit `widths` when tracks are equal.
- `dir: ttb` or `btt` creates a stack. Without explicit `heights`, stacked items keep proportions based on their measured natural heights. `heights` are normalized weights in drawn order; use equal weights only when an even split is intentional.
- Use `vstack` when one outer cell needs its own nested row or stack. It has no visual surface. Its default `fill-height: false` keeps text and boxes natural; use `fill-height: true` for figures that must scale into the cell.
- Row captions are one shared foot band. Images, code, and foreign row items supply `foot:`; their renderers must not draw a second caption.
- Progressive reveal belongs to the outer `vboxs` through `step:`. Do not put `#pause` inside a row. Unrevealed items stay covered so geometry does not move; a `vstack` is revealed as one outer-row item.
- Preserve visible failure behavior when editing row internals. An over-tall row item must spill, report an error, or remain visible; it must never disappear silently.

### Figures and code

- A bare `#img(...)` or `#code[...]` renders at natural size. Put it in `vboxs` when the row should own width, gap, direction, equal height, fill behavior, or reveal timing.
- `img` owns only figure appearance: source, fit, fixed height, border, and caption. A ratio `height:` is invalid because it can measure to zero; fill a container with the row's `fill-height`.
- Use `place-image` only for deliberate floating placement; use the logo and QR presets for those assets.
- Use `#code[...]` with an ordinary raw fence. Start with `indent: 2` for slide listings. Use `scale:` only after indentation and content reduction fail.
- A listing nested in a box uses `frame: false` so the surface is not drawn twice. Use `hl:`, `focus:`, `dim:`, or `mark:` instead of a separate annotation panel.
- A code mark cannot span a boundary created by syntax highlighting. If a required mark crosses tokens and fails, use `lang: none` for that listing instead of adding another highlighter workaround.

### Arrows and connectors

- Use `#solid-arrow()` only for a short filled process arrow between adjacent stages. Set `dir: ltr/rtl/ttb/btt` for direction and use `fill:` only for a semantic color. Use a connector for long, curved, anchored, or labeled relationships.
- Align a solid arrow with its neighboring shapes and size it to their actual gap and scale. Its defaults are a starting point: adjust `length` along `dir` and `thickness` across it so it neither floats nor crowds the boxes. Preserve the standard silhouette.
- Use `connector-arrow(color)` inside CeTZ for anchored relationships: `let edge = connector-arrow(color); line(a, b, ..edge)`.
- A connector line starts on the source boundary and its arrowhead tip lands on the target boundary; it must not stop short, float beside a shape, or penetrate it.
- The connector's `1.05pt` stroke and `0.72` head scale are baseline values. Scale `thickness` and `head-scale` together for the local node size, path length, canvas scale, and final projected size.
- Path geometry, endpoint clipping, and semantic color remain the diagram's responsibility. Use `dash:` only for a distinct relationship state. Prefer short direct routes; rearrange nodes before accepting avoidable crossings or long curves.

## Visual composition

### Hierarchy and structure

- Each slide has one main point. The title names the topic; the body develops it; a conclusion or takeaway states the judgment when the body does not already make it explicit.
- Visual weight follows semantic importance. Give the primary claim or evidence the strongest position and scale; keep context and metadata quieter.
- Start with the theme's boxes, rows, tables, bullets, figures, and listings. Add a custom surface or shape family only when it communicates a relationship those primitives cannot.
- Keep one visual grammar within a slide sequence: corresponding pages use compatible tracks, title treatments, colors, and diagram conventions.
- Avoid competing emphasis. Several saturated fills, thick borders, banners, or callouts at the same level flatten the hierarchy instead of strengthening it.

### Geometry, whitespace, and density

- Align related objects to shared edges, centers, tracks, or baselines. Items with the same semantic role should normally have the same dimensions and treatment.
- Size components from the available body area, not from arbitrary constants copied from another page. Recheck proportions after text, captions, or titles change.
- Distinguish inner and outer whitespace. Text needs visible padding from a frame; gaps between unrelated groups should be larger than gaps within one group.
- Use the body area intentionally. A small cluster stranded in one corner, a short image centered in a tall empty column, or a narrow track wrapping beside unused width is a layout defect.
- Density should support scanning. Do not maximize occupancy by eliminating hierarchy, but do not leave large dead regions while primary text or evidence is undersized.
- Nothing may overlap, clip, touch a frame unintentionally, collide with the footer, or create an accidental continuation page.

### Typography, boxes, and copy

- Primary body and box copy should render at least at the deck's normal body size. Smaller type is for genuinely secondary metadata, captions, citations, or dense diagram labels.
- Titles and box headings at the same semantic level use consistent size, weight, fill, and inset. Shorten or wrap a long label instead of shrinking only that heading.
- A short box body is vertically centered unless top alignment communicates a sequence or list. Padding must be visible without dwarfing the content.
- Rewrite or rebalance before forcing line breaks. Treat an avoidable one-word or 1-4-character final line, a very short line beside a long neighbor, unexplained hanging indentation, or text touching a frame as a defect.
- Avoid nested framed surfaces. When content must sit inside a box, remove its redundant frame and let the outer box own the surface.
- In Chinese deck copy, bullets normally omit terminal full stops and semicolons. Use natural classifiers and conjunctions; use the middle dot only in a formal name.
- Prefer `\` for an intentional Typst line break. Do not use manual breaks to compensate for the wrong track width.

### Figures, tables, diagrams, and color

- A main figure must be readable at screenshot and projected slide scale. If it reads as a thumbnail or footer illustration, enlarge, crop, split, or replace it.
- Prefer native/vector assets when available. A raster asset must remain sharp at its final rendered size; do not solve a low-resolution crop by enlarging it until it blurs.
- Crop source figures reproducibly. Remove page chrome and unrelated panels, but preserve axes, legends, labels, endpoints, and annotations required to understand the evidence.
- Captions should normally fit on one line. Count title, boxes, caption, and footer together; supporting text must not squeeze the evidence into a narrow strip.
- A table-plus-figure or side-by-side composition passes only when both sides remain readable and the columns look intentional. Otherwise change the archetype or split the slide.
- Diagram semantics outrank polish. For schedules and event diagrams, enumerate the promised reads, writes, dispatches, hops, destinations, and compute events, then verify that each appears in the rendered figure.
- Keep one color, line style, direction convention, and label treatment per relationship type. Color should encode role or state, not decorate arbitrary objects.
- Check contrast in the active light/dark mode and at final scale. Muted elements may recede; required evidence, labels, and arrowheads may not.

### Repair order

- Underfilled slide: rebalance rows and columns -> resize boxes or evidence -> remove redundant wrappers or labels -> reduce only excessive inner padding -> adjust the owning component or canvas.
- Overfull or tiny-evidence slide: compact wording -> improve the crop or asset -> change the layout archetype -> split the slide -> only then add a justified theme/helper override.
- Do not shrink the entire composition or primary type merely to make a page fit.

## Deck style overrides

- Write the plain component call first. Add a style argument only after a rendered page shows the defect it fixes.
- Leave `gap`, `after-gap`, `fill-height`, and `fill-pad` off ordinary `vboxs` calls unless the page needs a deliberate exception. Set a repeated gap once through `vboxs-config`.
- Omit `widths` for equal tracks. Near-equal ratios such as `0.48fr / 0.52fr` encode draft text length, not a meaningful hierarchy.
- Do not set ad hoc text sizes in ordinary deck body code. Fix content, tracks, the owning component, or the theme rather than shrinking one page.
- `scale:` on code and per-box `body-inset`, `body-align`, `compact`, or `title-size` are last resorts. `body-inset: (right: 0pt)` remains the routine exception for a frameless listing that must meet a box edge.
- Never restate defaults such as `width: 100%` or `widths: auto`.
- Deck-local CeTZ geometry is content: node positions, local gaps, and arrow lengths must fit that diagram. Theme defaults still govern the shared visual language.

## Validation

- Compile from the repository root: `typst compile --root . <source>.typ <output.pdf>`. `scripts/check.sh` compiles every example deck (`--out` adds `out/`; `--png DIR` / `--diff DIR` render and compare pages for theme changes).
- After every rebuild, confirm the page count and remap the named slide to its physical PDF page. Touying logical counters and physical pages can differ.
- Inspect the rendered target page at screenshot scale. For a page-specific edit, also inspect adjacent pages; for a repeated component or sequence, inspect every affected page or a readable contact sheet.
- Check for overflow, accidental continuation pages, clipping, overlap, footer collisions, unreadable figures, unstable captions, and inconsistent repeated elements.
- Audit semantic completeness separately from visual polish. Compilation and clean bounds do not prove that every required relationship, event, label, note, source, or claim is present.
- Report compile success, artifact checks, and visual inspection as separate evidence. Treat non-fatal parser/font warnings separately from a failed build.
- Do not claim visual QA unless the rendered pages were actually opened and inspected.
