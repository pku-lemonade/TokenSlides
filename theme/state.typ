// Shared runtime state (kept short on purpose).
#import "base.typ": modes, layout-16-9

#let cur-colors = state("lec-colors", modes.light.colors)
#let cur-box = state("lec-box", modes.light.box)
#let cur-layout = state("lec-layout", layout-16-9)

