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
    section: 32pt,
    code: 20pt,
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

#let fonts = (
    body: ("Inter", "Source Han Sans SC", ),
    math: "New Computer Modern Math",
    mono: ("Inconsolata", "Source Han Sans SC"),
)

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
    highlight: (fill: rgb("#fff8e1"), border: rgb("#f59e0b")),
    info: (fill: rgb("#eff6ff"), border: rgb("#3b82f6")),
    error: (fill: rgb("#fef2f2"), border: rgb("#ef4444")),
    success: (fill: rgb("#f0fdf4"), border: rgb("#22c55e")),
    neutral: (fill: rgb("#fafafa"), border: rgb("#737373")),
    purple: (fill: rgb("#f6f3ff"), border: rgb("#8b5cf6")),
)

#let dark-box-styles = (
    highlight: (fill: rgb("#0B2533"), border: dark-colors.link),
    info: (fill: rgb("#0B1220"), border: dark-colors.link),
    error: (fill: rgb("#2A0B0B"), border: rgb("#ef4444")),
    success: (fill: rgb("#0B2414"), border: rgb("#22c55e")),
    neutral: (fill: rgb("#141414"), border: dark-colors.neutral),
    purple: (fill: rgb("#1A102A"), border: rgb("#8b5cf6")),
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

// Full-bleed helper: ignore slide left/right margins.
#let bleed(body) = context {
    let margins = slide-layouts.at(cur-ar.get())
    move(dx: -margins.left)[
        #block(width: 100% + margins.left + margins.right)[#body]
    ]
}
