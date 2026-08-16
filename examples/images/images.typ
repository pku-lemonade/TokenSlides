// Compilable reference for theme/images.typ and theme/assets.typ.
//
// Compile from the repository root:
//   typst compile --root . examples/images/images.typ /tmp/images.pdf
//
// A figure is `#img(source)` or `#img(source, [caption])`, and it is a `vboxs`
// row item — the same thing `#code` and the box helpers are. There is no
// separate image-layout call: one figure, two side by side, a vertical stack,
// and a figure sharing a row with a box are all `vboxs`.
//
//   #img(fig)                          one figure, natural size
//   #vboxs(img(fig))                   one figure, filling the slide
//   #vboxs(img(a), img(b))             two at one height
//   #vboxs(img(a), img(b), dir: ttb)   stacked
//   #vboxs(ibox[...], img(a))          a figure beside a box
//
// `source` is a path or ready-made `image(...)` content. Prefer `image(...)` for
// deck-relative paths; a bare string is resolved from the theme module, so use a
// root-absolute string such as "/examples/images/assets/a.png" instead.

#import "/lemonade.typ": *

// These assets already live in the repository, so this example adds no copied
// binaries. Each `image(...)` path resolves relative to this source file.
#let workflow = image("../vstack/assets/vstack-fig01-workflow.png")
#let baselines = image("../vstack/assets/vstack-fig02-baselines.png")
#let architecture = image("../vstack/assets/vstack-fig03-architecture.png")
#let stack-design = image("../vstack/assets/vstack-fig04-stack-design.png")

#set text(lang: "en")

// Deck-wide defaults split by who owns the knob: `img-config` is one figure
// (caption typography, frame, fit), `vboxs-config` is the row every figure sits
// in (gaps, and whether a row fills the slide). Per-call arguments override both.
#show: lemonade-theme.with(
    aspect-ratio: "16-9",
    footer: "plain",
    img-config: (
        cap-size: 18pt,
        cap-weight: "bold",
    ),
    vboxs-config: (
        fill-height: false,
        fill-pad: 0.5em,
    ),
    title: [Image Layout Examples],
    short-title: [Image Layouts],
    author: [Lemonade],
    institution: [Theme Examples],
)

= Image Layouts

// Row parameters (`vboxs`) — where the figures go:
//   dir: ltr | rtl | ttb | btt
//   width: overall block width
//   widths: per-item tracks, side by side only
//   gap: row or column gap
//   bleed: extend a full-width row through the slide side margins
//   fill-height: consume the remaining height in the current parent flow
//   fill-pad: reserve space below a fill-height row
//   after: content under the row, with the row shortened to make space
//
// Figure parameters (`img`) — what one figure looks like:
//   width: width inside its own cell
//   height: a fixed length (to fill a container, use the row's `fill-height`)
//   fit: contain | cover | stretch
//   border, border-radius, inset
//   cap-size, cap-weight, cap-color, cap-gap

== One figure with a caption

// `width` on the row is the usual way to size an ordinary centered figure.
#vboxs(
    img(workflow, [Workflow overview]),
    width: 68%,
)

== Side by side

// `widths` may emphasize one figure; `dir: rtl` reverses the display order.
// Both figures get one height, so they line up whatever their aspect ratios.
#vboxs(
    img(workflow, [System workflow], height: 250pt),
    img(baselines, [Baseline comparison], height: 250pt),
    widths: (1.25fr, 1fr),
    gap: 0.8em,
)

== Captions of different lengths

// The row measures every caption in it and reserves one band for the tallest,
// so the figures above them still end on the same line. Nothing to align by
// hand — this is what makes a caption a figure's `foot` rather than content
// the figure renders itself.
#vboxs(
    img(architecture, [Architecture]),
    img(stack-design, [A longer caption that wraps onto a second line in its column]),
    gap: 0.8em,
    fill-height: true,
)

== Framing one figure

// A frame is per figure, not per row: `border` defaults to a hairline in the
// mode's table-stroke color, and `border: none` drops it.
#vboxs(
    img(
        architecture,
        [Architecture overview],
        height: 285pt,
        border: 1pt + rgb("#737373"),
        border-radius: 4pt,
        inset: 4pt,
    ),
    width: 72%,
)

== Fill the remaining height

The design separates request routing, scheduling, and memory management.

// `fill-height` uses the remaining height in the current slide or grid cell.
// Captions stay attached below the figure, while spare slack remains above it.
// Increase `fill-pad` when later content must follow.
#vboxs(
    img(stack-design, [Layered stack design]),
    width: 78%,
    fill-height: true,
    fill-pad: 0.4em,
)

== Vertical stack

// One row with `dir: ttb`, not two rows: a filling row divides its height
// between its items, so chaining two separate rows would make each claim the
// same budget and overflow the slide.
#vboxs(
    img(architecture, [Architecture], height: 135pt),
    img(stack-design, [Software stack], height: 135pt),
    dir: ttb,
    width: 72%,
    gap: 0.5em,
)

== A figure beside a box

// Mixed rows are the reason figures are row items. The box has no caption, so
// it takes the full row height while the figure stops above its own caption.
// `after` hangs a conclusion under the row and shortens the row to fit it.
#vboxs(
    ibox([Reading])[
        Rows mix freely: a box, a figure, or a `#code` listing are all row items.
    ],
    img(workflow, [Prefill and decode differ in where the time goes]),
    widths: (1fr, 1.2fr),
    gap: 0.8em,
    fill-height: true,
    after: [The figure and the box end on the same line.],
)

== Full-width bleed

// `bleed: true` extends the row through the slide side margins. Pair it with
// `width: 100%`, which is what makes the row actually reach both page edges.
#vboxs(
    img(baselines, [Baseline comparison across the full canvas], height: 310pt),
    width: 100%,
    bleed: true,
)

== Floating placement

// Floating helpers are intended for logos and QR-sized images, not primary
// figures. `position`, `dx`, and `dy` control the anchor and offset. An explicit
// parent height gives bottom anchors a stable placement region.
#block(width: 100%, height: 330pt)[
    #place-logo(pku-logo, width: 8%)
    #place-image(
        "/examples/vstack/assets/vstack-fig03-architecture.png",
        caption: "architecture",
        width: 24%,
        position: bottom + right,
        dx: -0.5em,
        dy: -0.5em,
    )
]

== Common assets

// Commonly used figures live under `assets/logos/` and `assets/qr/` and are
// exported as plain path values from `theme/assets.typ` (`pku-logo`,
// `thu-logo`, `nsfc-logo`, `lemonade-qr`). There is no registry: ad-hoc
// figures pass a root-absolute path to the same helpers. `place-logo` and
// `place-qr` are `place-image` presets with the same API and tuned corner
// defaults; a value may carry per-mode variants ((light: ..., dark: ...))
// that `place-xx` resolves against `lemonade-theme(mode: ...)`. Those variant
// dicts are for the `place-xx` family only — `img` takes a path or `image(...)`.
For the rare inline case, wrap a sized image in a box to keep it on the text
baseline: #box(image(nsfc-logo, height: 1em), baseline: 0.2em).

#block(width: 100%, height: 330pt)[
    #place-logo(thu-logo, width: 7%)
    #place-qr(caption: "pku-lemonade")
]

// ACM artifact badges are configured at theme level rather than per figure:
//   artifact-badges: ("available", "functional", "reusable")
// Built-in names are available, functional, reusable, reproduced, replicated.
//
// Behavior notes:
// - `img(height:)` is a fixed length; filling a container is `fill-height` on
//   the row, which depends on the current flow position.
// - A row respects the slide margins unless `bleed: true` is active.
// - Fill-height inside a grid cell uses that cell's remaining vertical budget.
// - A figure is fitted to the height its row gives it (`fit: "contain"` by
//   default), so a figure whose aspect ratio does not match its slot is
//   letterboxed inside the frame rather than distorted.
// - Very wide figures can remain width-limited in vertical stacks; crop or
//   split them when the important content would otherwise become too small.
