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
// text/math spacing, slide margins, and page size per aspect ratio.
#let layout-config = (
    "16-9": (
        font-sizes: (
            small: 18pt,
            body: 26pt,
            body-title: 28pt,
            title: 40pt,
            slide-title: 40pt,
            section: 44pt,
            callout: 36pt,
            code: 20pt,
            table: 20pt,
            page-number: 36pt,
        ),
        spacing: (par: 1.2em, math-above: 0.8em, math-below: 0.6em),
        margins: (top: 0.5em, bottom: 0em, left: 1.5em, right: 1em),
        // Match PowerPoint's standard slide canvas instead of Typst/Touying's smaller presentation paper.
        page-size: (width: 13.333in, height: 7.5in),
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
            page-number: 32pt,
        ),
        spacing: (par: 0.3em, math-above: 1em, math-below: auto),
        margins: (top: 0.75em, bottom: 0em, left: 1em, right: 0.75em),
        page-size: (width: 10in, height: 7.5in),
    ),
)

#let aspect-ratios = layout-config.keys()

// Font family stacks.
#let font-config = (
    body: ("Inter", "Arial", "Source Han Sans SC"),
    math: ("Inter", "New Computer Modern Math"),
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
    link: rgb("#2563eb"),
    footer-bg: auto,
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
    secondary: accent-config.california-gold,
    neutral: rgb("#5D5D5D"),
    neutral-lightest: rgb("#EDEDED"),
    neutral-darkest: rgb("#0D0D0D"),
    table-stroke: rgb("#5D5D5D"),
    link: rgb("#38BDF8"),
    footer-bg: auto,
    footer-fg: rgb("#EDEDED"),
    code-bg: rgb("#0B1220"),
    code-border: rgb("#334155"),
    code-fg: rgb("#EDEDED"),
)

// Accents sit at OKLCH L 0.52 (white title text stays >= 4.5:1 on every bar);
// fills share OKLCH L 0.955 / C 0.028 so no box reads heavier than its siblings.
#let light-box-styles = (
    highlight: (border: rgb("#915c00"), fill: rgb("#faefdc")),
    info: (border: rgb("#3a65b8"), fill: rgb("#e6f1ff")),
    error: (border: rgb("#ae3b47"), fill: rgb("#ffe9e9")),
    success: (border: rgb("#327b38"), fill: rgb("#e5f6e5")),
    neutral: (border: rgb("#585858"), fill: rgb("#f2f0ec")),
    purple: (border: rgb("#7652ac"), fill: rgb("#f3ecff")),
)

// Same accents as light mode; fills share OKLCH L 0.27 / C 0.02.
#let dark-box-styles = (
    highlight: (border: rgb("#915c00"), fill: rgb("#2c251b")),
    info: (border: rgb("#3a65b8"), fill: rgb("#212730")),
    error: (border: rgb("#ae3b47"), fill: rgb("#302323")),
    success: (border: rgb("#327b38"), fill: rgb("#202920")),
    neutral: (border: rgb("#585858"), fill: rgb("#272624")),
    purple: (border: rgb("#7652ac"), fill: rgb("#28242f")),
)

// Central theme “choices”: pick one of these modes in `lemonade-theme(mode: ...)`.
#let mode-config = (
    light: (colors: light-colors, box: light-box-styles),
    dark: (colors: dark-colors, box: dark-box-styles),
)

#let title-alignments = ("left", "center")

// Internal runtime state (set by `lemonade-theme`; other modules read it).
#let cur-ar = state("lec-ar", "16-9")
#let cur-colors = state("lec-colors", mode-config.light.colors)
#let cur-box = state("lec-box", mode-config.light.box)
#let cur-box-compact = state("lec-box-compact", false)
#let cur-box-fill = state("lec-box-fill", false)
#let cur-title-align = state("lec-title-align", "center")
#let cur-font-sizes = state("lec-font-sizes", layout-config.at("16-9").font-sizes)
#let cur-footer-style = state("lec-footer-style", "bar")
#let cur-artifact-badges = state("lec-artifact-badges", ())

// Full-bleed helper: ignore slide left/right margins.
#let bleed(body) = context {
    let margins = layout-config.at(cur-ar.get()).margins
    move(dx: -margins.left)[
        #block(width: 100% + margins.left + margins.right)[#body]
    ]
}
