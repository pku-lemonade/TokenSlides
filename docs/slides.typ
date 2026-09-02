#import "/lemonade.typ": *

// Slide shells: title and closing slides, outline variants, section slides,
// footer slots, artifact badges, speaker notes and stepped reveals. Deck-level
// colors and box styling are in theme.typ.

#set text(lang: "en")
#show: lemonade-theme.with(
    aspect-ratio: "16-9",
    // A footer dict merges over `footer-config`; `footer-presets` holds the
    // named arrangements ("bar", "plain", "page") a string picks.
    footer: (middle: footer-parts.title-with-heading, right: footer-parts.page),
    // Names from `artifact-badge-assets`, drawn on the title and closing slides.
    artifact-badges: ("available", "functional", "reproduced"),
    title: [Slide Shells],
    subtitle: [Title, outline, sections, closing],
    short-title: [Slides],
    author: [Lemonade],
    institution: [Theme Reference],
    venue: [docs/slides.typ],
    email: "hi0f1j@pku.edu.cn",
    github: "pku-lemonade",
)

// Deck metadata from `lemonade-theme` fills the venue band, title and bottom lines.
#title-slide()

// Sections only (the default variant).
#outline-slide()

// Sections and their slides in columns.
#outline-slide(variant: "subsections")

= Section slides
#speaker-note[A level-1 heading becomes an outline slide with the current section highlighted.]

== What a section slide is

A `= Heading` renders as an outline slide with the current section in the
primary color and the rest faded. Content directly under the heading (such as
a `speaker-note`) travels with it.

== Stepped reveals

- `#pause` between flow items reveals them one subslide at a time.
#pause
- Inside a `vboxs` row use `step:` instead (see boxes.typ).
#pause
- The footer counter counts slides, not subslides.

= Title and closing slides

== Title slide variants

`#title-slide()` reads the deck metadata. `title:` replaces the title text and
`extra:` places anything else on the slide, such as logos or a QR code.

#title-slide(
    title: [A title slide later in the deck],
    extra: [#place(bottom + left, dx: 1em, dy: -1em)[Extra content goes in `extra:`]],
)

== Closing slide

`#thank-you-slide()` is the title slide with contact lines (author,
institution, email, website, github) in place of the metadata. Positional
extras land on the slide.

#thank-you-slide(title: [Questions?])[
    #place-qr(caption: "pku-lemonade")
]
