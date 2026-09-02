#!/usr/bin/env python3
"""Every name a deck author can reach through `#import "/lemonade.typ": *` must
appear in at least one reference deck under docs/. Run via scripts/check.sh --coverage."""
import pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
THEME = ROOT / "theme"

# Exported for the theme's own wiring or as Touying passthroughs, not something
# a deck author calls; a docs deck need not show them.
PLUMBING = {
    "config-colors", "config-common", "config-info", "config-page", "touying-slides", "meanwhile", "appendix",
    "box-item", "apply-box-style", "apply-table-style", "apply-emph-style", "resolve-footer", "footer-band",
    "footer-fn", "footer", "slide", "caption-foot", "asset-path", "merge-config", "resolve-theme", "cur-theme",
    "layout-of", "resolve-parts", "info-part", "theme", "artifact-badge-assets", "artifact-badge-config",
    "vtable-colors", "vtable-styles", "default-img-config", "default-vboxs-config", "aspect-ratios",
    "title-alignments", "layout-config", "mode-config", "font-config", "bleed", "numbly", "python-lang",
    # Config dicts are edited in their module, not called from decks; the ones a
    # deck passes to lemonade-theme (img-config, vboxs-config) are checked.
    "box-config", "code-config", "callout-config", "callout-colors", "arrow-config", "han-config",
}

def public_lets(module):
    return re.findall(r"^#let ([a-z][a-z0-9-]*)", (THEME / f"{module}.typ").read_text(), re.M)

src = (THEME / "lemonade.typ").read_text()
src = re.sub(r"//[^\n]*", "", src)
names = set(public_lets("lemonade"))
for module, spec in re.findall(r'#import "([a-z-]+)\.typ":\s*(\*|\([^)]*\)|[^\n]+)', src):
    if spec.strip() == "*":
        names.update(public_lets(module))
    else:
        for item in spec.strip("()").split(","):
            item = item.strip()
            if not item:
                continue
            names.add(item.split(" as ")[-1].strip())
names -= PLUMBING

docs = "\n".join(p.read_text() for p in sorted((ROOT / "docs").glob("*.typ")))
missing = sorted(n for n in names if not re.search(rf"(?<![a-z0-9-]){re.escape(n)}(?![a-z0-9-])", docs))
print(f"{len(names)} public names, {len(names) - len(missing)} covered by docs/")
for n in missing:
    print(f"  uncovered: {n}")
sys.exit(1 if missing else 0)
