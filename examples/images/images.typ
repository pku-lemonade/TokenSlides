// Compilable reference for theme/images.typ and theme/assets.typ.
//
// Compile from the repository root:
//   typst compile --root . examples/images/images.typ /tmp/images.pdf
//
// `imgs` accepts image sources in three forms:
//   1. A preloaded image content value: `imgs(image("assets/a.png"))`
//   2. A flat source/caption pair: `imgs(image-a, [Caption])`
//   3. A legacy tuple: `imgs((image-a, [Caption]))`
//
// Prefer preloaded `image(...)` content for deck-relative paths. A string path
// passed into the shared helper is resolved from the theme module; root-absolute
// strings such as "/examples/images/assets/a.png" are also safe.
//
// Flat captions bind to the immediately preceding image source. Bare sources
// remain valid and receive no caption. Captions render when at least one item
// provides one.

#import "/lemonade.typ": *

// These assets already live in the repository, so this example adds no copied
// binaries. Each `image(...)` path resolves relative to this source file.
#let workflow = image("../vstack/assets/vstack-fig01-workflow.png")
#let baselines = image("../vstack/assets/vstack-fig02-baselines.png")
#let architecture = image("../vstack/assets/vstack-fig03-architecture.png")
#let stack-design = image("../vstack/assets/vstack-fig04-stack-design.png")

#set text(lang: "en")

// Deck-wide image defaults belong in `imgs-config`. Per-call arguments override
// these values.
#show: lemonade-theme.with(
    aspect-ratio: "16-9",
    footer: "plain",
    imgs-config: (
        fill-height: false,
        fill-pad: 0.5em,
        cap-size: 18pt,
        cap-weight: "bold",
    ),
    title: [Image Layout Examples],
    short-title: [Image Layouts],
    author: [Lemonade],
    institution: [Theme Examples],
)

= Image Layouts

// Common layout parameters:
//   dir: ltr | rtl | ttb | btt
//   width: overall block width
//   bleed: extend a full-width block through slide side margins
//   widths: per-item tracks for horizontal multi-image layouts
//   gap: row or column gap
//   valign: vertical alignment inside horizontal cells
//
// Common sizing parameters:
//   img-width: width passed to each image in normal mode
//   img-height: fixed image height
//   img-fit: contain | cover | stretch
//   fill-height: consume the remaining height in the current parent flow
//   fill-pad: reserve space below a fill-height image block
//
// Caption parameters:
//   cap-size, cap-weight, cap-color, cap-gap
//
// Framing parameters:
//   border, border-radius, inset

== Single image with a flat caption

// Use explicit block width for an ordinary centered figure.
#imgs(
    workflow,
    [Workflow overview],
    width: 68%,
)

== Side-by-side comparison

// `widths` may emphasize one image. The same flat input form works for any
// number of images, and `rtl` reverses their display order when needed.
#imgs(
    workflow,
    [System workflow],
    baselines,
    [Baseline comparison],
    widths: (1.25fr, 1fr),
    gap: 0.8em,
    img-height: 250pt,
)

== Legacy tuple input and framing

// Tuple input remains supported for compatibility and for arbitrary content
// cells where a flat source/caption pair would be ambiguous.
#imgs(
    (architecture, [Architecture overview]),
    width: 72%,
    img-height: 285pt,
    border: 1pt + rgb("#737373"),
    border-radius: 4pt,
    inset: 4pt,
)

== Fill the remaining height

The design separates request routing, scheduling, and memory management.

// Fill-height is dynamic: it uses the remaining height in the current slide or
// grid cell. Captions stay attached below the rendered image, while spare slack
// remains above it. Increase `fill-pad` when later content must follow.
#imgs(
    stack-design,
    [Layered stack design],
    width: 78%,
    fill-height: true,
    fill-pad: 0.4em,
)

== Vertical evidence stack

// Use one `imgs(dir: ttb, ...)` call for a vertical stack. When fill-height is
// enabled, the helper divides available height across the items. Chaining
// separate fill-height `imgs` calls would make each claim the same budget.
#imgs(
    architecture,
    [Architecture],
    stack-design,
    [Software stack],
    dir: ttb,
    width: 72%,
    gap: 0.5em,
    img-height: 135pt,
)

== Full-width bleed

// `bleed: true` only takes effect when the image block occupies the available
// slide-body width. It intentionally extends through the side margins.
#imgs(
    baselines,
    [Baseline comparison across the full canvas],
    width: 100%,
    bleed: true,
    img-height: 310pt,
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
// that `place-xx` resolves against `lemonade-theme(mode: ...)`.
For the rare inline case, wrap a sized image in a box to keep it on the text
baseline: #box(image(nsfc-logo, height: 1em), baseline: 0.2em).

#block(width: 100%, height: 330pt)[
    #place-logo(thu-logo, width: 7%)
    #place-qr(caption: "pku-lemonade")
]

// ACM artifact badges are configured at theme level rather than through imgs:
//   artifact-badges: ("available", "functional", "reusable")
// Built-in names are available, functional, reusable, reproduced, replicated.
//
// Behavior notes:
// - `img-height` is fixed; `fill-height` depends on current flow position.
// - `imgs` respects slide margins unless `bleed: true` is active.
// - Fill-height inside a grid cell uses that cell's remaining vertical budget.
// - Very wide figures can remain width-limited in vertical layouts; crop or
//   split them when the important content would otherwise become too small.
