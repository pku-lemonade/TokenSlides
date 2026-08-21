#import "base.typ": cur-ar, cur-colors, cur-font-sizes, font-config, is-zh-lang
#import "base.typ": config-page, touying-slide, touying-slide-wrapper, utils
#import "artifact-badges.typ": artifact-badges

// The deck-metadata slide: venue band on top, big title at the optical
// center, metadata/contact lines at the bottom. The thank-you slide is this
// slide with the overrides in thank-you.typ (`title-slide(preset: ...)`).

#let _date-format(lang) = {
    if is-zh-lang(lang) {
        "[year]年[month padding:none]月[day padding:none]日"
    } else {
        "[month repr:long] [day], [year]"
    }
}

// PARTS
// Building blocks for the bottom band's `lines:` tuple. Each part is
// `self => content`, returning `none` when the underlying info is absent so
// empty lines drop out (the renderer pads back up to `min-lines`).
#let _author(self) = self.info.at("author", default: none)

#let _institution(self) = self.info.at("institution", default: none)

#let _date(self) = {
    let date = self.info.at("date", default: datetime.today())
    if date == none {
        none
    } else if type(date) == datetime {
        date.display(_date-format(text.lang))
    } else {
        date
    }
}

#let _email(self) = {
    let email = self.info.at("email", default: none)
    if email != none { link("mailto:" + email)[#email] }
}

#let _website(self) = {
    let website = self.info.at("website", default: none)
    if website != none { link(website)[#website] }
}

#let _github(self) = {
    let github = self.info.at("github", default: none)
    if github != none { link("https://github.com/" + github)[github.com/#github] }
}

#let title-parts = (
    author: _author,
    institution: _institution,
    date: _date,
    email: _email,
    website: _website,
    github: _github,
)

// CONFIG
#let title-config = (
    // Title-slide page margins per aspect ratio.
    layouts: (
        "16-9": (top: 0em, bottom: 0em, left: 1em, right: 1em),
        "4-3": (top: 0em, bottom: 0em, left: 1em, right: 1em),
    ),
    placement: (
        venue-dy: 2em,
        title-dy: 0em,
        bottom-dy: -2em,
    ),
    // Han glyph handling, stated once: the decorative face for the bottom
    // band, and the size compensation for Han reading smaller than Latin at
    // the same size (applied in both bands unless a band opts out).
    han: (font: "FZFW ZhuZi GuDianS LH", size-delta: 6pt),
    // `size-delta` adds to the aspect ratio's `title` font size.
    // `han-size-delta`: `auto` = the shared `han.size-delta`, `none` keeps Han
    // glyphs at the title size, a length overrides per band.
    title: (size-delta: 0pt, han-size-delta: auto),
    // Metadata lines under the title. `lines` renders like footer slots:
    // parts resolve against the deck info, absent ones drop out, and the
    // block pads with hidden lines up to `min-lines` so its height (and the
    // title's optical center) stays stable.
    bottom: (
        font: font-config.body,
        size: "body-title",
        weight: "medium",
        leading: 0.75em,
        min-lines: 3,
        lines: (title-parts.author, title-parts.institution, title-parts.date),
    ),
)

// Use `config-info(venue: ...)` for the visible venue line above the title.
// Examples: [arXiv:2510.18586v2], [MICRO 2025], [OSDI 2025], [PKU LEMONADE Seminar].
//
// `config` is the touying page config; `preset` picks the full style config
// (thank-you.typ passes `thank-you-config`).
#let title-slide(
    config: (:),
    preset: title-config,
    title: auto,
    extra: none,
) = touying-slide-wrapper(self => context {
    let cfg = preset
    let aspect-ratio = cur-ar.get()
    let colors = cur-colors.get()
    let font-sizes = cur-font-sizes.get()
    let margins = cfg.layouts.at(aspect-ratio)
    let self = utils.merge-dicts(self, config-page(footer: none, margin: margins), config)

    let display-title = if title == auto { self.info.at("title", default: none) } else { title }
    let display-venue = self.info.at("venue", default: none)
    let title-size = font-sizes.title + cfg.title.size-delta
    let title-han-delta = if cfg.title.han-size-delta == auto { cfg.han.size-delta } else { cfg.title.han-size-delta }
    let title-han-args = (font: font-config.body)
    if title-han-delta != none {
        title-han-args.insert("size", title-size + title-han-delta)
    }

    let bottom-cfg = cfg.bottom
    let bottom-size = if type(bottom-cfg.size) == str { font-sizes.at(bottom-cfg.size) } else { bottom-cfg.size }
    let lines = bottom-cfg
        .lines
        .map(part => if type(part) == function { part(self) } else { part })
        .filter(it => it != none)
    let display-lines = lines + range(calc.max(0, bottom-cfg.min-lines - lines.len())).map(_ => hide[placeholder])

    let body = {
        artifact-badges(config: (aspect-ratio: aspect-ratio))
        if display-venue != none {
            place(top + center, dy: cfg.placement.venue-dy)[
                #text(size: font-sizes.body-title, font: font-config.body, weight: "bold")[
                    #display-venue
                ]
            ]
        }
        place(horizon + center, dy: cfg.placement.title-dy)[
            #show regex("[\p{Han}]+"): set text(..title-han-args)
            #text(size: title-size, weight: "bold", fill: colors.primary)[#display-title]
        ]
        place(bottom + center, dy: cfg.placement.bottom-dy)[
            #set par(leading: bottom-cfg.leading)
            #show regex("[\p{Han}]+"): set text(
                size: bottom-size + cfg.han.size-delta,
                font: cfg.han.font,
            )
            #{
                display-lines
                    .map(line => text(size: bottom-size, font: bottom-cfg.font, weight: bottom-cfg.weight)[#line])
                    .join(linebreak())
            }
        ]
        if extra != none { extra }
    }

    touying-slide(self: self, body)
})
