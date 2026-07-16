#import "@preview/theorion:0.4.0": *
#import "@preview/numbly:0.1.0": numbly

#import "base.typ": (
    accent-presets, aspect-ratios, bleed, cur-ar, cur-artifact-badges, cur-box, cur-box-compact, cur-box-fill,
    cur-colors, cur-font-sizes, cur-footer-style, cur-imgs-config, cur-title-align, font-size-presets, fonts,
    imgs-config as default-imgs-config, modes, page-spacing, slide-layouts, slide-page-sizes, title-alignments,
)
#import "base.typ": (
    config-colors, config-common, config-info, config-page, meanwhile, pause, speaker-note, touying-slides,
)

#import "artifact-badges.typ": *
#import "boxes.typ": *
#import "callout.typ": *
#import "emph.typ": apply-emph-style, on-primary
#import "images.typ": *

#import "footer.typ": footer as footer-fn
#import "grid.typ": apply-grid-style
#import "slide.typ": slide
#import "table.typ": apply-table-style, vtable
#import "title.typ": title-slide
#import "thank-you.typ": thank-you-slide
#import "outline.typ": outline-slide

#show: show-theorion

// Re-export footer under a stable name (avoid clashing with `lemonade-theme(footer: ...)`).
#let footer = footer-fn

// Explicit LaTeX-style text helpers. Normal `_emph_` / `#emph[...]` is themed as bold.
#let textbf(body) = text(weight: "black")[#body]
#let textit(body) = text(style: "italic")[#body]

// Main theme entry.
#let lemonade-theme(
    aspect-ratio: "16-9",
    mode: "light",
    colors-override: none,
    footer: "bar",
    // File-level default for all `hbox/ibox/...`; per-box `compact:` still overrides it.
    box-compact: false,
    // Use soft filled backgrounds for `hbox/ibox/...` instead of outline-only boxes.
    box-fill: false,
    // Alignment for content slide titles (`== ...`), not the title/thank-you slides.
    title-align: "center",
    // ACM artifact badges shown on title and thank-you slides. Use names such as
    // ("available", "functional", "reusable", "reproduced", "replicated").
    artifact-badges: (),
    imgs-config: (:),
    // Backwards-compat shims; prefer `imgs-config: (...)`.
    imgs-fill-height: auto,
    imgs-fill-pad: auto,
    imgs-cap-size: auto,
    imgs-cap-weight: auto,
    ..args,
    body,
) = {
    assert(aspect-ratio in aspect-ratios)
    assert(mode in modes.keys())
    assert(footer in ("bar", "plain", "page", none))
    assert(title-align in title-alignments)

    let theme = modes.at(mode)
    let colors = theme.colors + (if colors-override == none { (:) } else { colors-override })
    let spacing = page-spacing.at(aspect-ratio)
    let slide-margins = slide-layouts.at(aspect-ratio)
    let slide-page-size = slide-page-sizes.at(aspect-ratio)
    let resolved-font-sizes = font-size-presets.at(aspect-ratio)
    let legacy-imgs-config = (
        fill-height: imgs-fill-height,
        fill-pad: imgs-fill-pad,
        cap-size: imgs-cap-size,
        cap-weight: imgs-cap-weight,
    )
    let resolved-imgs-config = default-imgs-config + imgs-config
    for (key, value) in legacy-imgs-config.pairs() {
        if value != auto { resolved-imgs-config.insert(key, value) }
    }
    let section-slide-fn = body => outline-slide(level: 1)

    cur-ar.update(aspect-ratio)
    cur-colors.update(colors)
    cur-box.update(theme.box)
    cur-box-compact.update(box-compact)
    cur-box-fill.update(box-fill)
    cur-title-align.update(title-align)
    cur-font-sizes.update(resolved-font-sizes)
    cur-footer-style.update(footer)
    cur-artifact-badges.update(artifact-badges)
    cur-imgs-config.update(resolved-imgs-config)

    show: apply-grid-style
    show: apply-box-style
    show: apply-table-style.with(theme.colors)
    show: touying-slides.with(
        config-page(
            paper: "presentation-" + aspect-ratio,
            width: slide-page-size.width,
            height: slide-page-size.height,
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

    set text(
        size: resolved-font-sizes.body,
        font: fonts.body,
        weight: "medium",
        fill: colors.fg,
        features: ("halt",),
    )
    set par(spacing: spacing.par)
    set heading(numbering: numbly("{1}.", default: "1.1"))
    show math.equation: set text(font: fonts.math)
    show math.equation.where(block: true): set block(
        above: spacing.math-above,
        below: spacing.math-below,
    )
    show raw: set text(font: fonts.mono, size: resolved-font-sizes.code)
    show: apply-emph-style.with(strong-fill: colors.primary)
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
