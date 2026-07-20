#import "base.typ": cur-ar, cur-colors, cur-font-sizes, font-config, is-zh-lang
#import "base.typ": config-page, touying-slide, touying-slide-wrapper, utils
#import "artifact-badges.typ": artifact-badges

// Shared scaffold for the deck-metadata "hero" slides: venue band on top, big
// title at the optical center, metadata/contact lines at the bottom. All
// user-tweakable values (geometry, band styles, which lines render) live in
// the per-slide configs in title.typ and thank-you.typ — edit those to
// customize; this file only holds the shared parts and renderer.

// Decorative face for Han glyphs in the bottom band.
#let hero-han-font = "FZFW ZhuZi GuDianS LH"

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

#let hero-parts = (
    author: _author,
    institution: _institution,
    date: _date,
    email: _email,
    website: _website,
    github: _github,
)

// Renderer for a hero config from title.typ / thank-you.typ:
// - `layouts`: page margins per aspect ratio
// - `placement`: `venue-dy` / `title-dy` / `bottom-dy` band offsets
// - `title`: `size-delta` on the `title` font size; `han-size-delta` enlarges
//   Han glyphs in the title (`none` keeps them at the title size)
// - `bottom`: `font`, `size` (a `font-sizes` key or a length), `weight`,
//   `leading`, `lines` (parts tuple), `min-lines` (hidden-line padding so the
//   block height stays stable), `han` (`font` + `size-delta` over `size`)
#let hero-slide(hero-config, config: (:), title: auto, extra: none) = touying-slide-wrapper(self => context {
    let aspect-ratio = cur-ar.get()
    let colors = cur-colors.get()
    let font-sizes = cur-font-sizes.get()
    let margins = hero-config.layouts.at(aspect-ratio)
    let self = utils.merge-dicts(self, config-page(footer: none, margin: margins), config)

    let display-title = if title == auto { self.info.at("title", default: none) } else { title }
    let display-venue = self.info.at("venue", default: none)
    let title-size = font-sizes.title + hero-config.title.size-delta
    let title-han-args = (font: font-config.body)
    if hero-config.title.han-size-delta != none {
        title-han-args.insert("size", title-size + hero-config.title.han-size-delta)
    }

    let bottom-cfg = hero-config.bottom
    let bottom-size = if type(bottom-cfg.size) == str { font-sizes.at(bottom-cfg.size) } else { bottom-cfg.size }
    let lines = bottom-cfg
        .lines
        .map(part => if type(part) == function { part(self) } else { part })
        .filter(it => it != none)
    let display-lines = lines + range(calc.max(0, bottom-cfg.min-lines - lines.len())).map(_ => hide[placeholder])

    let body = {
        artifact-badges(config: (aspect-ratio: aspect-ratio))
        if display-venue != none {
            place(top + center, dy: hero-config.placement.venue-dy)[
                #text(size: font-sizes.body-title, font: font-config.body, weight: "bold")[
                    #display-venue
                ]
            ]
        }
        place(horizon + center, dy: hero-config.placement.title-dy)[
            #show regex("[\p{Han}]+"): set text(..title-han-args)
            #text(size: title-size, weight: "bold", fill: colors.primary)[#display-title]
        ]
        place(bottom + center, dy: hero-config.placement.bottom-dy)[
            #set par(leading: bottom-cfg.leading)
            #show regex("[\p{Han}]+"): set text(
                size: bottom-size + bottom-cfg.han.size-delta,
                font: bottom-cfg.han.font,
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
