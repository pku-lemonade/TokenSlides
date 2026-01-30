#import "@preview/touying:0.6.1": *
#import "@preview/theorion:0.4.0": *
#import "@preview/numbly:0.1.0": numbly

#import "base.typ": modes, fonts, font-sizes, page-spacing, slide-layouts, aspect-ratios, cur-ar, cur-colors, cur-box

#import "boxes.typ": *
#import "images.typ": *

#import "footer.typ": footer as footer-fn
#import "slide.typ": slide
#import "table.typ": apply-table-style
#import "title.typ": title-slide
#import "thank-you.typ": thank-you-slide
#import "outline.typ": outline-slide

#show: show-theorion

// Re-export footer under a stable name (avoid clashing with `lecture-theme(footer: ...)`).
#let footer = footer-fn

// Main theme entry.
#let lecture-theme(
    aspect-ratio: "16-9",
    mode: "light",
    footer: "bar",
    ..args,
    body
) = {
    assert(aspect-ratio in aspect-ratios)
    assert(mode in modes.keys())
    assert(footer in ("bar", "page", none))

    let theme = modes.at(mode)
    let spacing = page-spacing.at(aspect-ratio)
    let slide-margins = slide-layouts.at(aspect-ratio)
    let section-slide-fn = (body) => outline-slide(level: 1)

    cur-ar.update(aspect-ratio)
    cur-colors.update(theme.colors)
    cur-box.update(theme.box)

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
            primary: theme.colors.primary,
            secondary: theme.colors.secondary,
            neutral: theme.colors.neutral,
            neutral-lightest: theme.colors.neutral-lightest,
            neutral-darkest: theme.colors.neutral-darkest,
        ),
        ..args,
    )

    set text(size: font-sizes.body, font: fonts.body, weight: "medium", fill: theme.colors.fg)
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
        if type(it.dest) == str { set text(fill: theme.colors.link) }
        it
    }

    body
}
