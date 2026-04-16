// Shared theme configuration.
//
// Most module-specific configs live in their module files under `theme/`.
// This file holds the few global knobs users tweak often.

// Central Touying import: theme modules can import Touying APIs from `base.typ`
// so we only pin the package version once.
#import "@preview/touying:0.6.1": *
#import "@preview/touying:0.6.1": config-info as touying-config-info

// Keep Touying's `config-info` API, but default omitted `date:` to today.
#let config-info(..args) = {
    assert(args.pos().len() == 0, message: "Unexpected positional arguments.")
    let named = args.named()
    if not ("date" in named) {
        named.insert("date", datetime.today())
    }
    touying-config-info(..named)
}

// CONFIG (frequently tweaked)
#let font-sizes = (
    small: 18pt,
    body: 24pt,
    body-title: 32pt,
    title: 44pt,
    slide-title: 36pt,
    section: 40pt,
    code: 20pt,
)

#let imgs-config = (
    fill-height: true,
    fill-pad: 0.5em,
    cap-size: 18pt,
    cap-weight: "bold",
)

// Global text/math spacing per aspect ratio.
#let page-spacing = (
    "16-9": (
        par: 1em,
        math-above: 0.8em,
        math-below: 0.6em,
    ),
    "4-3": (
        par: 1em,
        math-above: 1em,
        math-below: auto,
    ),
)

// Default slide margins per aspect ratio.
#let slide-layouts = (
    "16-9": (top: 0.75em, bottom: 0em, left: 2em, right: 1.5em),
    "4-3": (top: 0.75em, bottom: 0em, left: 1.5em, right: 1.5em),
)

// Match PowerPoint's standard slide canvases instead of Typst/Touying's smaller presentation papers.
#let slide-page-sizes = (
    "16-9": (width: 13.333in, height: 7.5in),
    "4-3": (width: 10in, height: 7.5in),
)

#let fonts = (
    body: ("Inter", "Arial", "Source Han Sans SC", ),
    math: "New Computer Modern Math",
    mono: ("Inconsolata", "Source Han Sans SC"),
)

#let is-zh-lang(lang) = type(lang) == str and (lang == "zh" or lang.starts-with("zh-"))

// CONFIG (colors)
#let light-colors = (
    bg: white,
    fg: black,
    primary: rgb("#94070a"),
    // primary: rgb("#002676"),
    secondary: rgb("#FDB515"),
    neutral: rgb("#737373"),
    neutral-lightest: white,
    neutral-darkest: black,
    table-stroke: rgb("#d4d4d4"),
    link: rgb("#2563eb"),
    // footer-bg: rgb("#002676"),
    footer-bg: rgb("#94070a"),
    footer-fg: white,
    code-bg: rgb("#f5f5f5"),
    code-border: rgb("#d4d4d4"),
    code-fg: black,
)

// Based on the Codex CLI TUI dark theme.
#let dark-colors = (
    bg: rgb("#0D0D0D"),
    fg: rgb("#EDEDED"),
    primary: rgb("#38BDF8"),
    secondary: rgb("#FDB515"),
    neutral: rgb("#5D5D5D"),
    neutral-lightest: rgb("#EDEDED"),
    neutral-darkest: rgb("#0D0D0D"),
    table-stroke: rgb("#5D5D5D"),
    link: rgb("#38BDF8"),
    footer-bg: rgb("#002676"),
    footer-fg: rgb("#EDEDED"),
    code-bg: rgb("#0B1220"),
    code-border: rgb("#334155"),
    code-fg: rgb("#EDEDED"),
)

#let light-box-styles = (
    highlight: (fill: none, border: rgb("#f59e0b")),
    info: (fill: none, border: rgb("#3b82f6")),
    error: (fill: none, border: rgb("#ef4444")),
    success: (fill: none, border: rgb("#22c55e")),
    neutral: (fill: none, border: rgb("#737373")),
    purple: (fill: none, border: rgb("#8b5cf6")),
)

#let dark-box-styles = (
    highlight: (fill: none, border: rgb("#F59E0B")),
    info: (fill: none, border: dark-colors.link),
    error: (fill: none, border: rgb("#ef4444")),
    success: (fill: none, border: rgb("#22c55e")),
    neutral: (fill: none, border: dark-colors.neutral),
    purple: (fill: none, border: rgb("#8b5cf6")),
)

// Central theme “choices”: pick one of these modes in `lemonade-theme(mode: ...)`.
#let modes = (
    light: (colors: light-colors, box: light-box-styles),
    dark: (colors: dark-colors, box: dark-box-styles),
)

// Central aspect-ratio “choices”: pick one in `lemonade-theme(aspect-ratio: ...)`.
#let aspect-ratios = ("16-9", "4-3")
#let title-alignments = ("left", "center")

// Internal runtime state (set by `lemonade-theme`; other modules read it).
#let cur-ar = state("lec-ar", "16-9")
#let cur-colors = state("lec-colors", modes.light.colors)
#let cur-box = state("lec-box", modes.light.box)
#let cur-box-compact = state("lec-box-compact", false)
#let cur-title-align = state("lec-title-align", "center")
#let cur-imgs-config = state("lec-imgs-config", imgs-config)

// Full-bleed helper: ignore slide left/right margins.
#let bleed(body) = context {
    let margins = slide-layouts.at(cur-ar.get())
    move(dx: -margins.left)[
        #block(width: 100% + margins.left + margins.right)[#body]
    ]
}
