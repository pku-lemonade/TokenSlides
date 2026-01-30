#import "@preview/touying:0.6.1": *
#import "base.typ": fonts, font-sizes
#import "base.typ": cur-ar, cur-colors

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
    config: (:),
) = touying-slide-wrapper(self => context {
    let margins = thank-you-layouts.at(cur-ar.get())

    let default-config = config-page(
        margin: margins,
    )

    let self = utils.merge-dicts(self, default-config, config)

    let colors = cur-colors.get()

    let display-author = self.info.at("author", default: none)
    let display-email = self.info.at("email", default: none)
    let display-website = self.info.at("website", default: none)
    let display-github = self.info.at("github", default: none)

    let contact-items = ()
    if display-email != none {
        contact-items.push(link("mailto:" + display-email)[text(fill: colors.link)[display-email]])
    }
    if display-website != none {
        contact-items.push(link(display-website)[text(fill: colors.link)[display-website]])
    }
    if display-github != none {
        contact-items.push(link("https://github.com/" + display-github)[text(fill: colors.link)[github.com/#display-github]])
    }
    if content != none { contact-items.push(content) }

    let body = {
        place(center + horizon)[
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
        v(4em)
        // place-bottom-right(assets.qr-code, caption: "pku-lemonade")
    }

    touying-slide(self: self, body)
})
