#import "@preview/theorion:0.4.0": *
#import "@preview/numbly:0.1.0": numbly

#import "base.typ": modes, fonts, font-sizes, page-spacing, slide-layouts, aspect-ratios, title-alignments, cur-ar, cur-colors, cur-box, cur-box-compact, cur-title-align, bleed
#import "base.typ": touying-slides, config-page, config-common, config-colors, config-info

#import "boxes.typ": *
#import "images.typ": *

#import "footer.typ": footer as footer-fn
#import "slide.typ": slide
#import "table.typ": apply-table-style
#import "title.typ": title-slide
#import "thank-you.typ": thank-you-slide
#import "outline.typ": outline-slide

#show: show-theorion

// Re-export footer under a stable name (avoid clashing with `lemonade-theme(footer: ...)`).
#let footer = footer-fn

// Main theme entry.
#let lemonade-theme(
    aspect-ratio: "16-9",
    mode: "light",
    colors-override: none,
    footer: "bar",
    // File-level default for all `hbox/ibox/...`; per-box `compact:` still overrides it.
    box-compact: false,
    // Alignment for content slide titles (`== ...`), not the title/thank-you slides.
    title-align: "center",
    ..args,
    body
) = {
    assert(aspect-ratio in aspect-ratios)
    assert(mode in modes.keys())
    assert(footer in ("bar", "page", none))
    assert(title-align in title-alignments)

    let theme = modes.at(mode)
    let colors = (:)
    for (key, value) in theme.colors.pairs() {
        colors.insert(key, value)
    }
    if colors-override != none {
        for (key, value) in colors-override.pairs() {
            colors.insert(key, value)
        }
    }
    let spacing = page-spacing.at(aspect-ratio)
    let slide-margins = slide-layouts.at(aspect-ratio)
    let section-slide-fn = (body) => outline-slide(level: 1)

    cur-ar.update(aspect-ratio)
    cur-colors.update(colors)
    cur-box.update(theme.box)
    cur-box-compact.update(box-compact)
    cur-title-align.update(title-align)

    show: touying-slides.with(
        config-page(
            paper: "presentation-" + aspect-ratio,
            fill: theme.colors.bg,
            margin: slide-margins,
            header: none,
            footer: footer-fn.with(style: footer),
        ),
        config-common(
            slide-fn: slide,
            new-section-slide-fn: section-slide-fn,
        ),
        config-colors(
            primary: colors.primary,
            secondary: colors.secondary,
            neutral: colors.neutral,
            neutral-lightest: colors.neutral-lightest,
            neutral-darkest: colors.neutral-darkest,
        ),
        ..args,
    )

    set text(size: font-sizes.body, font: fonts.body, weight: "medium", fill: colors.fg)
    set par(spacing: spacing.par)
    set heading(numbering: numbly("{1}.", default: "1.1"))
    apply-table-style(theme.colors)
    show math.equation: set text(font: fonts.math)
    show math.equation.where(block: true): set block(
        above: spacing.math-above,
        below: spacing.math-below,
    )
    show raw: set text(font: fonts.mono, size: font-sizes.code)
    // Only color external links; keep internal navigation links (e.g. outline) inheriting
    // surrounding text color so progressive fading works.
    show link: it => {
        if type(it.dest) == str {
            // `set text(fill: ...)` may not override already-styled text in Touying slides,
            // so wrap the link in a local text style.
            text(fill: colors.link)[#it]
        } else {
            it
        }
    }

    body
}

// Backwards-compat: keep the old name around.
#let lecture-theme = lemonade-theme
