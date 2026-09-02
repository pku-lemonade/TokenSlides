#import "@preview/numbly:0.1.0": numbly

#import "base.typ": (
    accent-config, aspect-ratios, bleed, cur-theme, font-config, layout-config, merge-config, mode-config,
    resolve-theme, theme, title-alignments,
)
// `appendix` freezes Touying's last-slide counter, so backup slides kept after
// the closing slide stop inflating the `n / total` the footer shows on the
// slides that are actually presented.
#import "base.typ": (
    appendix, config-colors, config-common, config-info, config-page, meanwhile, pause, speaker-note,
    touying-slides,
)

#import "artifact-badges.typ": *
#import "arrows.typ": *
#import "assets.typ": lemonade-qr, nsfc-logo, pku-logo, thu-logo
#import "boxes.typ": *
#import "callout.typ": *
#import "code.typ": code, code-config, code-lang, python-lang
#import "emph.typ": apply-emph-style, on-primary
#import "images.typ": *
#import "images.typ": img-config as default-img-config
#import "boxes.typ": vboxs-config as default-vboxs-config

#import "footer.typ": footer as footer-fn, footer-band, footer-parts, footer-presets, resolve-footer
#import "slide.typ": slide
#import "table.typ": apply-table-style, vtable, vtable-colors, vtable-styles
#import "title.typ": han-config, title-slide
#import "thank-you.typ": thank-you-slide
#import "outline.typ": outline-slide

// Re-export footer under a stable name (avoid clashing with `lemonade-theme(footer: ...)`).
#let footer = footer-fn

// Main theme entry.
#let lemonade-theme(
    aspect-ratio: "16-9",
    mode: "light",
    colors-override: none,
    // Preset name from `footer-presets` ("bar", "plain", "page"), `none`, or a
    // dict of `footer-config` overrides, e.g. `(middle: footer-parts.heading)`
    // or `footer-presets.page + (left: [CC BY 4.0])`.
    footer: "bar",
    // File-level default for all `hbox/ibox/...`; per-box `compact:` still overrides it.
    box-compact: false,
    // Use soft filled backgrounds for `hbox/ibox/...` instead of outline-only boxes.
    box-fill: false,
    // Horizontal alignment for content slide titles (`== ...`): `left`, `center`
    // or `right`. Not the title/thank-you slides.
    title-align: center,
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
    // Shared row-caption typography plus image-only frame/fit defaults.
    img-config: (:),
    // Defaults for `#vboxs`, which lays out every equal-height row in the theme
    // — figures and listings as well as boxes (`gap`, `fill-height`, ...).
    vboxs-config: (:),
    // Language specs for `#code`, keyed by the fence tag they answer to, e.g.
    // `(tdsl: code-lang(("comment", "#.*"), ("keyword", ("kernel", "tile"))))`.
    // Merges over `code-config.langs`, so a name that is already there (such as
    // `python`) is replaced, and `(python: none)` hands it back to syntect.
    code-langs: (:),
    body,
) = {
    assert(aspect-ratio in aspect-ratios)
    assert(mode in mode-config.keys())
    assert(
        title-align in title-alignments,
        message: "lemonade-theme: `title-align` must be left, center or right, got " + repr(title-align),
    )

    let resolved = resolve-theme(
        aspect-ratio: aspect-ratio,
        mode: mode,
        colors-override: if colors-override == none { (:) } else { colors-override },
        box-compact: box-compact,
        box-fill: box-fill,
        title-align: title-align,
        artifact-badges: artifact-badges,
    ) + (
        img: merge-config("img-config", default-img-config, img-config),
        vboxs: merge-config("vboxs-config", default-vboxs-config, vboxs-config),
        code-langs: code-config.langs + code-langs,
    )
    let colors = resolved.colors
    let layout = layout-config.at(aspect-ratio)
    let spacing = layout.spacing
    let footer-cfg = resolve-footer(footer)
    // Reserve the footer band as real bottom margin so slide content (incl.
    // anything after a fill-height row) always stops above the footer.
    let slide-margins = layout.margins + (
        bottom: layout.margins.bottom + footer-band(aspect-ratio, footer-cfg),
    )
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
    let section-slide-fn = body => outline-slide(level: 1, body: body)

    cur-theme.update(resolved)

    show: apply-box-style
    show: apply-table-style.with(colors)
    show: touying-slides.with(
        config-page(
            paper: "presentation-" + aspect-ratio,
            width: layout.page-size.width,
            height: layout.page-size.height,
            fill: colors.bg,
            margin: slide-margins,
            header: none,
            footer: if footer-cfg == none { none } else { footer-fn.with(config: footer-cfg) },
            // Let the footer fill the reserved band exactly instead of floating
            // 30% into it (the Typst default).
            footer-descent: 0pt,
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
        size: layout.font-sizes.body,
        font: font-config.body,
        weight: "medium",
        fill: colors.fg,
        features: ("halt",),
    )
    // Uniform vertical rhythm: block-level elements (block math, tables,
    // grids, code boxes, ...) default their outer spacing to `par.spacing`,
    // so setting it here is what makes every flow gap equal `flow`.
    set par(leading: spacing.leading, spacing: spacing.flow)
    set heading(numbering: numbly("{1}.", default: "1.1"))
    show math.equation: set text(font: font-config.math)
    show raw: set text(font: font-config.mono, size: layout.font-sizes.code)
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
