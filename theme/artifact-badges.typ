#import "base.typ": layout-of, theme

// ACM artifact badge artwork. Prefer v1.1 PNGs when available; `replicated`
// falls back to ACM's older download image until a high-resolution v1.1 asset is available.
#let artifact-badge-assets = (
    available: "/assets/acm-artifact-badges/acm_available_1.1.png",
    functional: "/assets/acm-artifact-badges/acm_functional_1.1.png",
    reusable: "/assets/acm-artifact-badges/artifacts_evaluated_reusable_v1_1.png",
    reproduced: "/assets/acm-artifact-badges/acm_reproduced_1.1.png",
    replicated: "/assets/acm-artifact-badges/results_replicated_dl.jpg",
)

#let artifact-badge-config = (
    // Badge geometry per aspect ratio.
    layouts: (
        "16-9": (height: 92pt, gap: 0.08in, dx: 0.5em, dy: 1em),
        "4-3": (height: 80pt, gap: 0.07in, dx: -0.55em, dy: 0.5em),
    ),
)

#let _badge-path(badge) = {
    if type(badge) == str {
        artifact-badge-assets.at(badge, default: badge)
    } else {
        badge
    }
}

// Badge row, placed in a slide corner. With no positional badges the deck's
// `lemonade-theme(artifact-badges: ...)` list is used; `auto` geometry takes
// the aspect ratio's layout.
#let artifact-badges(
    ..badges,
    height: auto,
    gap: auto,
    position: top + right,
    dx: auto,
    dy: auto,
) = context {
    assert(badges.named().len() == 0, message: "artifact-badges: unknown options " + repr(badges.named().keys()))
    let items = badges.pos()
    if items.len() == 0 {
        items = theme().artifact-badges
    }
    if items.len() == 0 {
        none
    } else {
        let layout = layout-of(artifact-badge-config)
        let resolved-height = if height == auto { layout.height } else { height }
        let resolved-gap = if gap == auto { layout.gap } else { gap }
        let resolved-dx = if dx == auto { layout.dx } else { dx }
        let resolved-dy = if dy == auto { layout.dy } else { dy }

        place(position, dx: resolved-dx, dy: resolved-dy)[
            #box[
                #stack(
                    dir: ltr,
                    spacing: resolved-gap,
                    ..items.map(badge => image(_badge-path(badge), height: resolved-height)),
                )
            ]
        ]
    }
}
