#import "base.typ": cur-artifact-badges

// ACM artifact badge artwork. Prefer v1.1 PNGs when available; `replicated`
// falls back to ACM's older download image until a high-resolution v1.1 asset is available.
#let artifact-badge-assets = (
    available: "../assets/acm-artifact-badges/acm_available_1.1.png",
    functional: "../assets/acm-artifact-badges/acm_functional_1.1.png",
    reusable: "../assets/acm-artifact-badges/artifacts_evaluated_reusable_v1_1.png",
    reproduced: "../assets/acm-artifact-badges/acm_reproduced_1.1.png",
    replicated: "../assets/acm-artifact-badges/results_replicated_dl.jpg",
)

#let artifact-badge-layouts = (
    "16-9": (height: 0.62in, gap: 0.08in, dx: -0.6em, dy: 0.5em),
    "4-3": (height: 0.58in, gap: 0.07in, dx: -0.55em, dy: 0.5em),
)

#let _badge-path(badge) = {
    if type(badge) == str {
        artifact-badge-assets.at(badge, default: badge)
    } else {
        badge
    }
}

#let artifact-badges(
    ..badges,
    height: auto,
    gap: auto,
    position: top + right,
    dx: auto,
    dy: auto,
    config: (:),
) = context {
    let items = badges.pos()
    if items.len() == 0 {
        items = cur-artifact-badges.get()
    }
    if items.len() == 0 {
        none
    } else {
        let layout = artifact-badge-layouts.at(config.at("aspect-ratio", default: "16-9"))
        let resolved-height = if height == auto { config.at("height", default: layout.height) } else { height }
        let resolved-gap = if gap == auto { config.at("gap", default: layout.gap) } else { gap }
        let resolved-dx = if dx == auto { config.at("dx", default: layout.dx) } else { dx }
        let resolved-dy = if dy == auto { config.at("dy", default: layout.dy) } else { dy }

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
