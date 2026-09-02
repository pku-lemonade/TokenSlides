// Shared theme configuration.
//
// Most module-specific configs live in their module files under `theme/`.
// This file holds the few global knobs users tweak often.
//
// Naming convention (machine-exported; see AGENTS.md "Config convention"):
// every user-tweakable style dict is a top-level `#let <feature>-config` in the
// module it styles; aspect-ratio variants ("16-9" / "4-3") sit under a
// `layouts:` key inside it. Unsuffixed dicts (e.g. `light-colors`) are
// internal building blocks.

// Central Touying import: theme modules can import Touying APIs from `base.typ`
// so we only pin the package version once.
#import "@preview/touying:0.6.1": *

// CONFIG (frequently tweaked)
//
// Everything `lemonade-theme(aspect-ratio: ...)` controls: font sizes,
// vertical rhythm, slide margins, and page size per aspect ratio.
// `margins.bottom` excludes the footer band: lemonade-theme adds the band
// height on top when a footer style is active.
//
// Vertical rhythm is two tokens, resolved against the body text size:
// - `leading`: line spacing inside paragraphs (and tight list items).
// - `flow`: THE gap between any two flow blocks — paragraphs, boxes, vboxs
//   rows, callouts, block math, tables, grids, code boxes. Components default
//   their outer spacing to this token, so the rhythm stays uniform; keep
//   `flow` >= `leading` so paragraph breaks read looser than line breaks.
#let layout-config = (
    "16-9": (
        font-sizes: (
            small: 18pt,
            body: 24pt,
            body-title: 32pt,
            title: 48pt,
            slide-title: 40pt,
            section: 44pt,
            callout: 36pt,
            code: 20pt,
            table: 20pt,
            table-header: 24pt,
            page-number: 36pt,
        ),
        spacing: (leading: 0.65em, flow: 0.3em),
        margins: (top: 0.75em, bottom: 0em, left: 1.5em, right: 1em),
        page-size: (width: 960pt, height: 540pt),
    ),
    "4-3": (
        font-sizes: (
            small: 14pt,
            body: 22pt,
            body-title: 24pt,
            title: 40pt,
            slide-title: 32pt,
            section: 34pt,
            callout: 30pt,
            code: 18pt,
            table: 18pt,
            table-header: 22pt,
            page-number: 32pt,
        ),
        spacing: (leading: 0.65em, flow: 0.5em),
        margins: (top: 0.75em, bottom: 0em, left: 1em, right: 0.75em),
        page-size: (width: 10in, height: 7.5in),
    ),
)

#let aspect-ratios = layout-config.keys()

// Font family stacks.
#let font-config = (
    body: ("Inter", "Arial", "Source Han Sans SC"),
    math: "New Computer Modern Math",
    mono: ("Inconsolata", "Source Han Sans SC"),
)

#let is-zh-lang(lang) = type(lang) == str and (lang == "zh" or lang.starts-with("zh-"))

// CONFIG (colors)
//
// Accent presets: alternate `primary`/`secondary` choices. Use them in the
// color dicts below, or per deck via
// `lemonade-theme(colors-override: (primary: accent-config.tsinghua-purple))`.
#let accent-config = (
    berkeley-blue: rgb("#002676"),
    dark-red: rgb("#94070a"),
    crimson: rgb("#990000"),
    tsinghua-purple: rgb("#660874"),
    california-gold: rgb("#FDB515"),
    golden-yellow: rgb("#FFCC00"),
)

#let light-colors = (
    bg: white,
    fg: black,
    primary: accent-config.berkeley-blue,
    secondary: accent-config.golden-yellow,
    neutral: rgb("#737373"),
    neutral-lightest: white,
    neutral-darkest: black,
    table-stroke: rgb("#d4d4d4"),
    // Links wear the primary accent; dark mode already equates the two.
    link: accent-config.berkeley-blue,
    // Text placed on primary-filled surfaces (footer bar, vtable headers,
    // primary callouts).
    on-primary: white,
    // Elevation shadow for floating surfaces (callouts).
    shadow: black.transparentize(70%),
    footer-bg: auto,
    footer-fg: white,
    // Code listings carry their own per-mode palette (surface plus syntax
    // colors) in `light-code-palette` / `dark-code-palette` in code.typ.
)

// Based on the Codex CLI TUI dark theme.
#let dark-colors = (
    bg: rgb("#0D0D0D"),
    fg: rgb("#EDEDED"),
    primary: rgb("#38BDF8"),
    secondary: accent-config.california-gold,
    neutral: rgb("#5D5D5D"),
    neutral-lightest: rgb("#EDEDED"),
    neutral-darkest: rgb("#0D0D0D"),
    table-stroke: rgb("#5D5D5D"),
    link: rgb("#38BDF8"),
    on-primary: rgb("#0D0D0D"),
    // Dark shadows vanish on a dark page; use a light glow instead.
    shadow: white.transparentize(70%),
    footer-bg: auto,
    // The bar footer fills with `primary` (#38BDF8); near-black text keeps
    // contrast on it, where light text would wash out.
    footer-fg: rgb("#0D0D0D"),
)

// Glass look: saturated accents carry white title ink; fills are near-white
// panes at OKLCH L 0.975 / C 0.013 so the hue is felt more than seen. Frame
// hairlines take the accent at low alpha (see `frame-tint` in boxes.typ), which
// is what sells the tinted-glass edge. Highlight runs a little brighter and
// cleaner than before while keeping white large-title text at 3:1 contrast.
//
// Every style declares every key: `border` is the accent, `fill` the body pane
// (used when `box-fill` is on), `title-text-fill: auto` takes the box-config
// default ink, and `title-emph-fill: auto` gives emphasis in the title the
// shared on-primary treatment; a color pins it instead.
#let _box-style(border, fill, title-text-fill: auto, title-emph-fill: auto) = (
    border: border,
    fill: fill,
    title-text-fill: title-text-fill,
    title-emph-fill: title-emph-fill,
)

#let light-box-styles = (
    highlight: _box-style(rgb("#C58900"), rgb("#fbf6ed"), title-emph-fill: white),
    info: _box-style(accent-config.berkeley-blue, rgb("#f2f7ff")),
    error: _box-style(accent-config.dark-red, rgb("#fff3f3")),
    success: _box-style(rgb("#327b38"), rgb("#f2f9f1")),
    neutral: _box-style(rgb("#585858"), rgb("#f7f7f4")),
    purple: _box-style(accent-config.tsinghua-purple, rgb("#f8f5ff")),
)

// Same accents as light mode; fills share OKLCH L 0.235 / C 0.014.
#let dark-box-styles = (
    highlight: _box-style(rgb("#C58900"), rgb("#221d17"), title-emph-fill: white),
    info: _box-style(accent-config.berkeley-blue, rgb("#1a1e25")),
    error: _box-style(accent-config.dark-red, rgb("#241c1c")),
    success: _box-style(rgb("#327b38"), rgb("#1a201a")),
    neutral: _box-style(rgb("#585858"), rgb("#1f1e1c")),
    purple: _box-style(accent-config.tsinghua-purple, rgb("#1f1d24")),
)

// Central theme “choices”: pick one of these modes in `lemonade-theme(mode: ...)`.
#let mode-config = (
    light: (colors: light-colors, box: light-box-styles),
    dark: (colors: dark-colors, box: dark-box-styles),
)

// Horizontal alignments a content-slide title may take (`lemonade-theme(title-align:)`).
#let title-alignments = (left, center, right)

// Merge `overrides` over `defaults`, rejecting keys the defaults do not have.
#let merge-config(name, defaults, overrides) = {
    for key in overrides.keys() {
        assert(
            key in defaults,
            message: name + ": unknown key `" + key + "`; known keys are " + repr(defaults.keys()),
        )
    }
    defaults + overrides
}

// The theme as `lemonade-theme` resolves it: aspect ratio, mode, colors, box
// styles, font sizes, spacing and margins. lemonade.typ adds the deck-level
// component defaults (`img`, `vboxs`, `code-langs`); each module reads those
// with a fallback to its own config.
#let resolve-theme(
    aspect-ratio: "16-9",
    mode: "light",
    colors-override: (:),
    box-compact: false,
    box-fill: false,
    title-align: center,
    artifact-badges: (),
) = {
    let layout = layout-config.at(aspect-ratio)
    let mode-cfg = mode-config.at(mode)
    (
        aspect-ratio: aspect-ratio,
        mode: mode,
        colors: merge-config("colors-override", mode-cfg.colors, colors-override),
        box-styles: mode-cfg.box,
        box-compact: box-compact,
        box-fill: box-fill,
        title-align: title-align,
        font-sizes: layout.font-sizes,
        spacing: layout.spacing,
        margins: layout.margins,
        artifact-badges: artifact-badges,
    )
}

// Runtime state, set once by `lemonade-theme`. Modules read it with `theme()`
// inside `context`. The default must be a complete theme: Typst's layout loop
// consults it before the update is visible, and a placeholder keeps the loop
// from converging.
#let cur-theme = state("lemonade-theme", resolve-theme())

#let theme() = cur-theme.get()

// The active aspect ratio's entry of a config's `layouts:` dict. Requires context.
#let layout-of(config) = config.layouts.at(theme().aspect-ratio)

// Slot parts, shared by the title slide's metadata lines and the footer slots.
// A part is `self => content` (called with Touying's `self`), literal content,
// or an array of those; parts resolving to `none` drop out.
#let resolve-parts(slot, self) = {
    let items = if type(slot) == array { slot } else { (slot,) }
    items.map(part => if type(part) == function { part(self) } else { part }).filter(it => it != none)
}

#let info-part(key) = self => self.info.at(key, default: none)

// Full-bleed helper: ignore slide left/right margins.
#let bleed(body) = context {
    let margins = theme().margins
    move(dx: -margins.left)[
        #block(width: 100% + margins.left + margins.right)[#body]
    ]
}
