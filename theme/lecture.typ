#import "@preview/touying:0.6.1": *
#import "@preview/theorion:0.4.0": *
#import "@preview/numbly:0.1.0": numbly

#import "base.typ": modes, layouts, fonts, font-sizes
#import "state.typ": cur-colors, cur-box, cur-layout

#import "boxes.typ": *
#import "images.typ": *
#import "text.typ": *

#import "footer.typ": footer as footer-fn
#import "slide.typ": slide
#import "title.typ": title-slide
#import "thank-you.typ": thank-you-slide
#import "outline.typ": outline-slide, new-section-slide

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
    assert(aspect-ratio in layouts.keys())
    assert(mode in modes.keys())
    assert(footer in ("bar", "page", none))

    let layout = layouts.at(aspect-ratio)
    let m = modes.at(mode)

    cur-layout.update(layout)
    cur-colors.update(m.colors)
    cur-box.update(m.box)

    show: touying-slides.with(
        config-page(
            paper: "presentation-" + aspect-ratio,
            fill: m.colors.bg,
            margin: (
                top: layout.slide-top-margin,
                bottom: layout.slide-bottom-margin,
                left: layout.slide-left-margin,
                right: layout.slide-right-margin,
            ),
            header: none,
            footer: footer-fn.with(style: footer),
        ),
        config-common(
            slide-fn: slide,
            new-section-slide-fn: new-section-slide,
        ),
        config-colors(
            primary: m.colors.primary,
            secondary: m.colors.secondary,
            neutral: m.colors.neutral,
            neutral-lightest: m.colors.neutral-lightest,
            neutral-darkest: m.colors.neutral-darkest,
        ),
        ..args,
    )

    set text(size: font-sizes.body, font: fonts.body, weight: "medium", fill: m.colors.fg)
    set par(spacing: layout.par-spacing)
    set heading(numbering: numbly("{1}.", default: "1.1"))
    show table: set table(stroke: (paint: m.colors.table-stroke, thickness: 0.6pt))
    show math.equation: set text(font: fonts.math)
    show math.equation.where(block: true): set block(
        above: layout.math-block-spacing-above,
        below: layout.math-block-spacing-below,
    )
    show raw: set text(font: fonts.mono, size: font-sizes.code)
    show link: set text(fill: m.colors.link)

    body
}

