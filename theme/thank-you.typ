#import "base.typ": fonts, font-sizes, cur-ar
#import "base.typ": touying-slide-wrapper, touying-slide, utils, config-page

// CONFIG
#let thank-you-layouts = (
    "16-9": (top: 0em, bottom: 2em, left: 1em, right: 1em),
    "4-3": (top: 0em, bottom: 2em, left: 1em, right: 1em),
)

#let thanks-han = (
    font: "FZFW ZhuZi GuDianS LH",
    size-delta: 6pt,
)

#let thank-you-slide(
    title: [Thank You],
    content: none,
    decoration: none,
    config: (:),
    ..extras,
) = touying-slide-wrapper(self => context {
    let extra = extras.pos().sum(default: none)
    let margins = thank-you-layouts.at(cur-ar.get())

    let default-config = config-page(
        margin: margins,
    )

    let self = utils.merge-dicts(self, default-config, config)

    let display-author = self.info.at("author", default: none)
    let display-email = self.info.at("email", default: none)
    let display-website = self.info.at("website", default: none)
    let display-github = self.info.at("github", default: none)

    let contact-items = ()
    if display-email != none {
        contact-items.push(link("mailto:" + display-email)[#display-email])
    }
    if display-website != none {
        contact-items.push(link(display-website)[#display-website])
    }
    if display-github != none {
        contact-items.push(link("https://github.com/" + display-github)[github.com/#display-github])
    }
    if content != none { contact-items.push(content) }

    let body = {
        place(horizon + center)[
            #text(size: font-sizes.title + 8pt, weight: "bold")[#title]
        ]
        align(bottom + center)[
            #set par(leading: 1em)
            #show regex("[\p{Han}]+"): set text(
                size: font-sizes.body-title + thanks-han.size-delta,
                font: thanks-han.font,
            )
            #text(size: font-sizes.body-title, font: fonts.mono, weight: "medium")[
                #if display-author != none [#display-author]
            ]\
            #if contact-items.len() > 0 [
                #text(size: font-sizes.body-title, font: fonts.mono, weight: "medium")[
                    #contact-items.join(linebreak())
                ]
            ]
        ]
        if decoration != none { decoration }
        if extra != none { extra }
    }

    touying-slide(self: self, body)
})
