#import "base.typ": theme

// Common figures as plain exported values — no registry, no lookup. Pass them
// wherever a `place-xx` helper takes a source: `#place-logo(pku-logo)`,
// `#place-qr()`. Ad-hoc figures need no registration: pass a root-absolute
// path directly, e.g. `#place-logo("/out/mydeck/figs/lab-logo.png")`.
//
// A value is either a single path used in every mode, or per-mode variants
// resolved by the `place-xx` helpers against `lemonade-theme(mode: ...)` with
// fallback to `light`:
//   #let pku-logo = (light: "/assets/logos/pku.png", dark: "/assets/logos/pku-dark.png")
// See `assets/README.md` for file provenance notes.
#let pku-logo = "/assets/logos/pku.png" // Peking University lockup: seal + 北京大学, red
#let thu-logo = "/assets/logos/thu.svg" // Tsinghua University round seal, purple
#let nsfc-logo = "/assets/logos/nsfc.png" // NSFC lockup: seal + CN/EN wordmark, blue
#let lemonade-qr = "/assets/qr/lemonade.png" // pku-lemonade repo QR

// Resolve per-mode variants to the current mode's path; plain sources pass
// through. Needs `context` when given a variant dict.
#let asset-path(source) = {
    if type(source) == dictionary { source.at(theme().mode, default: source.light) } else { source }
}
