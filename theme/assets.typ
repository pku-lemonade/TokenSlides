#import "base.typ": theme

// Common figures as plain paths for the `place-xx` helpers: `#place-logo(pku-logo)`,
// `#place-qr()`. Ad-hoc figures take a root-absolute path directly. A value may
// also be per-mode: `(light: "/assets/x.png", dark: "/assets/x-dark.png")`.
// See `assets/README.md` for provenance.
#let pku-logo = "/assets/logos/pku.png" // Peking University lockup: seal + 北京大学, red
#let thu-logo = "/assets/logos/thu.svg" // Tsinghua University round seal, purple
#let nsfc-logo = "/assets/logos/nsfc.png" // NSFC lockup: seal + CN/EN wordmark, blue
#let lemonade-qr = "/assets/qr/lemonade.png" // pku-lemonade repo QR

// Resolve per-mode variants to the current mode's path; plain sources pass
// through. Needs `context` when given a variant dict.
#let asset-path(source) = {
    if type(source) == dictionary { source.at(theme().mode, default: source.light) } else { source }
}
