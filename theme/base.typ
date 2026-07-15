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
#let font-size-presets = (
    "16-9": (
        small: 18pt,
        body: 26pt,
        body-title: 28pt,
        title: 40pt,
        slide-title: 38pt,
        section: 44pt,
        code: 20pt,
        table: 20pt,
        page-number: 36pt,
    ),
    "4-3": (
        small: 18pt,
        body: 24pt,
        body-title: 28pt,
        title: 40pt,
        slide-title: 34pt,
        section: 34pt,
        code: 18pt,
        table: 18pt,
        page-number: 32pt,
    ),
)

// Backwards-compatible default. Runtime rendering uses `cur-font-sizes`,
// which `lemonade-theme(aspect-ratio: ...)` updates from `font-size-presets`.
#let font-sizes = font-size-presets.at("16-9")

#let imgs-config = (
    fill-height: true,
    fill-pad: 0.5em,
    cap-size: font-sizes.small,
    cap-weight: "bold",
)

// Global text/math spacing per aspect ratio.
#let page-spacing = (
    "16-9": (
        par: 1.2em,
        math-above: 0.8em,
        math-below: 0.6em,
    ),
    "4-3": (
        par: 0.3em,
        math-above: 1em,
        math-below: auto,
    ),
)

// Default slide margins per aspect ratio.
#let slide-layouts = (
    "16-9": (top: 0.5em, bottom: 0em, left: 1.5em, right: 1em),
    "4-3": (top: 0.75em, bottom: 0em, left: 1.25em, right: 1em),
)

// Match PowerPoint's standard slide canvases instead of Typst/Touying's smaller presentation papers.
#let slide-page-sizes = (
    "16-9": (width: 13.333in, height: 7.5in),
    "4-3": (width: 10in, height: 7.5in),
)

#let fonts = (
    body: ("Inter", "Arial", "Source Han Sans SC"),
    math: "New Computer Modern Math",
    mono: ("Inconsolata", "Source Han Sans SC"),
)

#let is-zh-lang(lang) = type(lang) == str and (lang == "zh" or lang.starts-with("zh-"))

// CONFIG (colors)
#let light-colors = (
    bg: white,
    fg: black,
    // primary: rgb("#94070a"),
    primary: rgb("#990000"),
    // primary: rgb("#002676"),
    // secondary: rgb("#FDB515"),
    secondary: rgb("#FFCC00"),
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

// Airtable-inspired Dark1 accents with Light2 body fills.
#let light-box-styles = (
    highlight: (border: rgb("#b87503"), fill: rgb("#ffeab6")),
    info: (border: rgb("#2750ae"), fill: rgb("#cfdfff")),
    error: (border: rgb("#ba1e45"), fill: rgb("#ffdce5")),
    success: (border: rgb("#338a17"), fill: rgb("#d1f7c4")),
    neutral: (border: rgb("#444444"), fill: rgb("#eeeeee")),
    purple: (border: rgb("#6b1cb0"), fill: rgb("#ede2fe")),
)

#let dark-box-styles = (
    highlight: (border: rgb("#b87503"), fill: rgb("#2f2412")),
    info: (border: rgb("#2750ae"), fill: rgb("#151c38")),
    error: (border: rgb("#ba1e45"), fill: rgb("#3a161f")),
    success: (border: rgb("#338a17"), fill: rgb("#183411")),
    neutral: (border: rgb("#444444"), fill: rgb("#1f1f1f")),
    purple: (border: rgb("#6b1cb0"), fill: rgb("#241b3a")),
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
#let cur-box-fill = state("lec-box-fill", false)
#let cur-title-align = state("lec-title-align", "center")
#let cur-font-sizes = state("lec-font-sizes", font-sizes)
#let cur-imgs-config = state("lec-imgs-config", imgs-config)
#let cur-footer-style = state("lec-footer-style", "bar")
#let cur-artifact-badges = state("lec-artifact-badges", ())

// Full-bleed helper: ignore slide left/right margins.
#let bleed(body) = context {
    let margins = slide-layouts.at(cur-ar.get())
    move(dx: -margins.left)[
        #block(width: 100% + margins.left + margins.right)[#body]
    ]
}
