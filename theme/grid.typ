// Grid styling: gives deck-level layout grids default breathing room.
//
// Applied theme-wide, so it matches EVERY grid — including grids inside
// components (boxes, footer, vtable measurement). That stays harmless because
// `above`/`below` collapse when the grid is the only child of a component's
// own block; keep wrapping component-internal grids in their own `block(..)`
// so only content grids pick up this spacing.

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
