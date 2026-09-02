// Compilable reference for theme/arrows.typ.
//
// Compile from the repository root:
//   typst compile --root . docs/arrows.typ /tmp/arrows.pdf

#import "/lemonade.typ": *
#import "@preview/cetz:0.3.4"

#show: lemonade-theme.with(
    aspect-ratio: "16-9",
    footer: none,
    title: [Arrows],
    author: [Lemonade],
    institution: [Theme Reference],
)

= Arrows

== Solid process arrow

#grid(
    columns: (1fr, 52pt, 1fr, 52pt, 1fr),
    rows: (90pt,),
    align: center + horizon,
    ibox[Input],
    solid-arrow(),
    hbox[Transform],
    solid-arrow(fill: rgb("#AE3B47")),
    sbox[Output],
)

#v(18pt)

#align(center)[
    #grid(
        columns: (74pt, 74pt, 74pt, 74pt),
        rows: (58pt,),
        align: center + horizon,
        solid-arrow(dir: ltr),
        solid-arrow(dir: rtl),
        solid-arrow(dir: ttb),
        solid-arrow(dir: btt),
    )
]

== Thin CeTZ connector

#context {
    let colors = theme().colors
    let normal = connector-arrow(colors.primary)
    let failed = connector-arrow(
        rgb("#AE3B47"),
        dash: "dashed",
    )

    block(width: 100%)[
        #align(center)[
            #cetz.canvas(length: 1cm, {
                import cetz.draw: *

                rect((0, 0), (4, 1.8), fill: colors.bg, stroke: colors.primary + 1pt)
                rect((7, 0), (11, 1.8), fill: colors.bg, stroke: colors.primary + 1pt)
                content((2, 0.9), text(weight: "bold")[Source])
                content((9, 0.9), text(weight: "bold")[Target])
                line((4, 1.2), (7, 1.2), ..normal)
                bezier((4, 0.55), (7, 0.55), (5.5, -1.1), ..failed)
            })
        ]
    ]
}
