// Shared theme configuration.
//
// Edit this file when you want to change global look & feel:
// colors, fonts, font sizes, and runtime defaults.

#let light-colors = (
    bg: white,
    fg: black,
    // primary: rgb("#94070a"),
    primary: rgb("#002676"),
    secondary: rgb("#FDB515"),
    neutral: rgb("#737373"),
    neutral-lightest: white,
    neutral-darkest: black,
    table-stroke: rgb("#d4d4d4"),
    link: rgb("#2563eb"),
    footer-bg: rgb("#002676"),
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

// Central theme “choices”: pick one of these modes in `lecture-theme(mode: ...)`.
#let modes = (
    light: (colors: light-colors, box: light-box-styles),
    dark: (colors: dark-colors, box: dark-box-styles),
)

#let fonts = (
    body: ("Inter", "Source Han Sans SC", "FZLTHProS"),
    math: "New Computer Modern Math",
    mono: ("Inconsolata", "Source Han Sans SC"),
)

#let font-sizes = (
    small: 18pt,
    body: 22pt,
    body-title: 26pt,
    title: 44pt,
    slide-title: 36pt,
    section: 36pt,
    code: 20pt,
)

#let aspect-ratios = ("16-9", "4-3")

// Runtime state (set by `lecture-theme`; other modules read it).
#let cur-ar = state("lec-ar", "16-9")
#let cur-colors = state("lec-colors", modes.light.colors)
#let cur-box = state("lec-box", modes.light.box)
