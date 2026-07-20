# Shared theme assets

Files here are exported as plain path values from `theme/assets.typ`
(`pku-logo`, `thu-logo`, `nsfc-logo`, `lemonade-qr`) and passed to the
`place-xx` helpers: `#place-logo(pku-logo)`, `#place-qr()`. There is no
registry — a temporary or deck-local figure passes its root-absolute path to
the same helpers with no registration. To add a shared figure: drop the file
in the matching subdirectory, export a `#let <name> = "/assets/..."` in
`theme/assets.typ`, and note its source below.

A value can also hold per-mode variants for dark decks:

```typst
#let pku-logo = (light: "/assets/logos/pku.png", dark: "/assets/logos/pku-dark.png")
```

The `place-xx` helpers resolve variants against `lemonade-theme(mode: ...)`
and fall back to `light` when a mode has no dedicated file. Name variant files
`<name>-dark.<ext>`.

## logos/

| File | Export | What it is | Source |
| --- | --- | --- | --- |
| `pku.png` | `pku-logo` | Peking University lockup (seal + 北京大学, red) | PKU visual identity |
| `thu.svg` | `thu-logo` | Tsinghua University round seal (purple) | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Tsinghua_University_Logo.svg), PD |
| `nsfc.png` | `nsfc-logo` | NSFC lockup (seal + CN/EN wordmark, blue) | [nsfc.gov.cn](https://www.nsfc.gov.cn/) official site, transparent-trimmed |

## qr/

| File | Export | What it is |
| --- | --- | --- |
| `lemonade.png` | `lemonade-qr` | pku-lemonade repo QR with mascot |

## acm-artifact-badges/

ACM artifact evaluation badges, consumed by `theme/artifact-badges.typ` via
`lemonade-theme(artifact-badges: (...))` — not exported from `theme/assets.typ`.
