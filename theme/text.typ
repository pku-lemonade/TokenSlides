#import "base.typ": font-sizes

// CONFIG
// Small title-ish text helper.

#let tbox(
    body,
    size: font-sizes.body-title,
    weight: "bold",
    alignment: left,
    leading: 1em,
) = {
    set par(leading: leading)
    align(alignment)[
        #text(size: size, weight: weight)[#body]
    ]
}

