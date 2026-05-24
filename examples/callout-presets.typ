#import "/lemonade.typ": *

#show: lemonade-theme.with(
    aspect-ratio: "16-9",
    footer: none,
    config-info(
        title: [Callout Presets],
        author: [Lemonade],
        date: none,
    ),
)

#title-slide()

== Callout colors

#callout[*White* is the default callout color]

#bcallout[*Blue* uses Berkeley blue and California gold]

#rcallout[*Red* uses theme primary and secondary colors]

#callout(color: "white", emph-fill: rgb("#003262"))[*Overrides* still work]
