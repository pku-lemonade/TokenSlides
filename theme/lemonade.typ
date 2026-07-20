#import "@preview/theorion:0.4.0": *
#import "@preview/numbly:0.1.0": numbly

#import "base.typ": (
    accent-config, layout-config, aspect-ratios, bleed, cur-ar, cur-artifact-badges, cur-box, cur-box-compact,
    cur-box-fill, cur-colors, cur-font-sizes, cur-footer-style, cur-mode, cur-title-align, font-config,
    mode-config, title-alignments,
)
#import "base.typ": (
    config-colors, config-common, config-info, config-page, meanwhile, pause, speaker-note, touying-slides,
)

#import "artifact-badges.typ": *
#import "assets.typ": lemonade-qr, nsfc-logo, pku-logo, thu-logo
#import "boxes.typ": *
#import "callout.typ": *
#import "emph.typ": apply-emph-style, on-primary
#import "images.typ": *
#import "images.typ": imgs-config as default-imgs-config

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
    // Deck metadata, rendered on the title/thank-you slides and in the footer.
    // `auto` means "not set"; an omitted `date` defaults to today, `date: none`
    // hides it.
    title: auto,
    subtitle: auto,
    short-title: auto,
    author: auto,
    institution: auto,
    date: auto,
    venue: auto,
    email: auto,
    website: auto,
    github: auto,
    imgs-config: (:),
    body,
) = {
    assert(aspect-ratio in aspect-ratios)
    assert(mode in mode-config.keys())
    assert(footer in ("bar", "plain", "page", none))
    assert(title-align in title-alignments)

    let theme = mode-config.at(mode)
    let colors = theme.colors + (if colors-override == none { (:) } else { colors-override })
    let layout = layout-config.at(aspect-ratio)
    let spacing = layout.spacing
    let slide-margins = layout.margins
    let slide-page-size = layout.page-size
    let resolved-font-sizes = layout.font-sizes
    let resolved-imgs-config = default-imgs-config + imgs-config
    let info = (date: if date == auto { datetime.today() } else { date })
    for (key, value) in (
        title: title,
        subtitle: subtitle,
        short-title: short-title,
        author: author,
        institution: institution,
        venue: venue,
        email: email,
        website: website,
        github: github,
    ).pairs() {
        if value != auto { info.insert(key, value) }
    }
    let section-slide-fn = body => outline-slide(level: 1)

    cur-ar.update(aspect-ratio)
    cur-mode.update(mode)
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
        config-info(..info),
    )

    set text(
        size: resolved-font-sizes.body,
        font: font-config.body,
        weight: "medium",
        fill: colors.fg,
        features: ("halt",),
    )
    set par(spacing: spacing.par)
    set heading(numbering: numbly("{1}.", default: "1.1"))
    show math.equation: set text(font: font-config.math)
    show math.equation.where(block: true): set block(
        above: spacing.math-above,
        below: spacing.math-below,
    )
    show raw: set text(font: font-config.mono, size: resolved-font-sizes.code)
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
