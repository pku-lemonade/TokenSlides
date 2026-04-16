// Grid styling.

// CONFIG
#let grid-config = (
    spacing-above: 0em,
    spacing-below: 0em,
)

#let apply-grid-style(body) = {
    show grid: it => block(
        above: grid-config.spacing-above,
        below: grid-config.spacing-below,
        spacing: 0pt,
    )[#it]
    body
}
