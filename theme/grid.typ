// Grid styling.

// CONFIG
#let grid-config = (
    spacing-above: 1em,
    spacing-below: 1em,
)

#let apply-grid-style(body) = {
    show grid: it => block(
        above: grid-config.spacing-above,
        below: grid-config.spacing-below,
        spacing: 0pt,
    )[#it]
    body
}
