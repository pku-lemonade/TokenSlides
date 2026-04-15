#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from dataclasses import asdict, dataclass
from pathlib import Path

from PIL import Image, ImageChops, ImageColor, ImageDraw, ImageFont, ImageOps, ImageStat


RESAMPLING = Image.Resampling.LANCZOS

PRESETS = {
    "wide": (1600, 900),
    "standard": (1400, 1050),
    "square": (1200, 1200),
}

ANCHORS = {
    "center": (0.5, 0.5),
    "top": (0.5, 0.0),
    "bottom": (0.5, 1.0),
    "left": (0.0, 0.5),
    "right": (1.0, 0.5),
    "top-left": (0.0, 0.0),
    "top-right": (1.0, 0.0),
    "bottom-left": (0.0, 1.0),
    "bottom-right": (1.0, 1.0),
}


@dataclass
class FigureSummary:
    input: str
    output: str
    preview: str | None
    mode_requested: str
    mode_applied: str
    target_size: tuple[int, int]
    original_size: tuple[int, int]
    trimmed_size: tuple[int, int]
    trim_bbox: tuple[int, int, int, int]
    required_crop_fraction: float
    max_crop_fraction: float
    anchor: str
    background: str
    allow_upscale: bool


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Prepare a slide-ready figure by trimming outer margins, adding breathing "
            "room, and then padding or cropping to a target canvas."
        )
    )
    parser.add_argument("input", help="Source image path")
    parser.add_argument(
        "--output",
        help="Output image path. Defaults to <input>-prepared.png next to the input.",
    )
    parser.add_argument(
        "--preview",
        action="store_true",
        help="Write a three-panel preview sheet beside the output image.",
    )
    parser.add_argument(
        "--summary-json",
        help="Optional path to write a JSON summary.",
    )
    parser.add_argument(
        "--preset",
        choices=sorted(PRESETS),
        default="wide",
        help="Named target canvas preset. Default: wide (1600x900).",
    )
    parser.add_argument(
        "--size",
        help="Override preset with WIDTHxHEIGHT, for example 1600x900.",
    )
    parser.add_argument(
        "--mode",
        choices=("smart", "pad", "fit", "none"),
        default="smart",
        help=(
            "smart trims first, then uses fit only when the required crop is small; "
            "otherwise it pads. Default: smart."
        ),
    )
    parser.add_argument(
        "--anchor",
        choices=sorted(ANCHORS),
        default="center",
        help="Bias the crop/pad placement. Useful when labels sit near one edge.",
    )
    parser.add_argument(
        "--background",
        default="auto",
        help="Padding background: auto, transparent, white, black, or #RRGGBB.",
    )
    parser.add_argument(
        "--tolerance",
        type=int,
        default=18,
        help="Trim tolerance against the corner background color. Default: 18.",
    )
    parser.add_argument(
        "--margin-ratio",
        type=float,
        default=0.03,
        help="Margin added back after trim, as a fraction of max dimension. Default: 0.03.",
    )
    parser.add_argument(
        "--margin-px",
        type=int,
        default=12,
        help="Extra fixed pixels added back after trim. Default: 12.",
    )
    parser.add_argument(
        "--max-crop",
        type=float,
        default=0.12,
        help=(
            "In smart mode, use crop-to-fit only when the required crop fraction is at "
            "most this value. Default: 0.12."
        ),
    )
    parser.add_argument(
        "--bleed",
        type=float,
        default=0.0,
        help="Optional Pillow fit bleed value. Default: 0.",
    )
    parser.add_argument(
        "--allow-upscale",
        action="store_true",
        help="Allow the script to enlarge raster content to hit the target canvas.",
    )
    return parser.parse_args()


def parse_size(text: str) -> tuple[int, int]:
    try:
        width_text, height_text = text.lower().split("x", 1)
        width = int(width_text)
        height = int(height_text)
    except Exception as exc:  # pragma: no cover - defensive
        raise SystemExit(f"invalid size '{text}'; expected WIDTHxHEIGHT") from exc
    if width <= 0 or height <= 0:
        raise SystemExit(f"invalid size '{text}'; width and height must be positive")
    return (width, height)


def sample_corners(image: Image.Image, sample_size: int = 8) -> list[tuple[int, int, int, int]]:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    span = max(1, min(sample_size, width, height))
    boxes = [
        (0, 0, span, span),
        (width - span, 0, width, span),
        (0, height - span, span, height),
        (width - span, height - span, width, height),
    ]
    samples = []
    for box in boxes:
        stat = ImageStat.Stat(rgba.crop(box))
        values = tuple(int(round(channel)) for channel in stat.mean)
        samples.append(values)
    return samples


def median_channel(values: list[int]) -> int:
    ordered = sorted(values)
    return ordered[len(ordered) // 2]


def resolve_background(image: Image.Image, background: str) -> tuple[str, tuple[int, int, int, int] | None]:
    if background == "transparent":
        return ("transparent", None)
    if background != "auto":
        rgb = ImageColor.getrgb(background)
        return (background, (rgb[0], rgb[1], rgb[2], 255))

    corners = sample_corners(image)
    alpha_values = [sample[3] for sample in corners]
    if max(alpha_values) < 32:
        return ("transparent", None)

    rgba = tuple(median_channel([sample[index] for sample in corners]) for index in range(4))
    if rgba[3] < 64:
        return ("transparent", None)
    return ("auto", (rgba[0], rgba[1], rgba[2], 255))


def union_bbox(
    first: tuple[int, int, int, int] | None,
    second: tuple[int, int, int, int] | None,
) -> tuple[int, int, int, int] | None:
    if first is None:
        return second
    if second is None:
        return first
    return (
        min(first[0], second[0]),
        min(first[1], second[1]),
        max(first[2], second[2]),
        max(first[3], second[3]),
    )


def compute_trim_bbox(
    image: Image.Image,
    tolerance: int,
    margin_ratio: float,
    margin_px: int,
    background_rgba: tuple[int, int, int, int] | None,
) -> tuple[int, int, int, int]:
    rgba = image.convert("RGBA")
    alpha_channel = rgba.getchannel("A")
    alpha_min, alpha_max = alpha_channel.getextrema()
    alpha_bbox = None
    if alpha_min < 250 or background_rgba is None:
        alpha_bbox = alpha_channel.point(lambda value: 255 if value > 8 else 0).getbbox()

    color_bbox = None
    if background_rgba is not None:
        solid_bg = Image.new("RGB", rgba.size, background_rgba[:3])
        diff = ImageChops.difference(rgba.convert("RGB"), solid_bg)
        diff = diff.convert("L").point(lambda value: 255 if value > tolerance else 0)
        color_bbox = diff.getbbox()

    bbox = union_bbox(alpha_bbox, color_bbox)
    if bbox is None:
        bbox = (0, 0, rgba.width, rgba.height)

    x0, y0, x1, y1 = bbox
    margin = int(round(max(x1 - x0, y1 - y0) * margin_ratio)) + margin_px
    x0 = max(0, x0 - margin)
    y0 = max(0, y0 - margin)
    x1 = min(rgba.width, x1 + margin)
    y1 = min(rgba.height, y1 + margin)
    return (x0, y0, x1, y1)


def required_crop_fraction(source_size: tuple[int, int], target_size: tuple[int, int]) -> float:
    source_w, source_h = source_size
    target_w, target_h = target_size
    source_ar = source_w / source_h
    target_ar = target_w / target_h
    if source_ar > target_ar:
        return max(0.0, 1.0 - (target_ar / source_ar))
    return max(0.0, 1.0 - (source_ar / target_ar))


def contain_without_upscale(image: Image.Image, target_size: tuple[int, int], allow_upscale: bool) -> Image.Image:
    target_w, target_h = target_size
    width, height = image.size
    if not allow_upscale and width <= target_w and height <= target_h:
        return image.copy()
    return ImageOps.contain(image, target_size, method=RESAMPLING)


def anchor_offset(
    canvas_size: tuple[int, int],
    content_size: tuple[int, int],
    centering: tuple[float, float],
) -> tuple[int, int]:
    free_x = max(0, canvas_size[0] - content_size[0])
    free_y = max(0, canvas_size[1] - content_size[1])
    offset_x = int(round(free_x * centering[0]))
    offset_y = int(round(free_y * centering[1]))
    return (offset_x, offset_y)


def new_canvas(
    size: tuple[int, int],
    background_rgba: tuple[int, int, int, int] | None,
) -> Image.Image:
    if background_rgba is None:
        return Image.new("RGBA", size, (255, 255, 255, 0))
    return Image.new("RGBA", size, background_rgba)


def pad_to_canvas(
    image: Image.Image,
    target_size: tuple[int, int],
    centering: tuple[float, float],
    background_rgba: tuple[int, int, int, int] | None,
    allow_upscale: bool,
) -> Image.Image:
    contained = contain_without_upscale(image, target_size, allow_upscale)
    canvas = new_canvas(target_size, background_rgba)
    canvas.alpha_composite(contained, anchor_offset(target_size, contained.size, centering))
    return canvas


def fit_to_canvas(
    image: Image.Image,
    target_size: tuple[int, int],
    centering: tuple[float, float],
    bleed: float,
    allow_upscale: bool,
    background_rgba: tuple[int, int, int, int] | None,
) -> tuple[Image.Image, str]:
    scale = max(target_size[0] / image.width, target_size[1] / image.height)
    if scale > 1.0 and not allow_upscale:
        return (pad_to_canvas(image, target_size, centering, background_rgba, allow_upscale), "pad-no-upscale")
    fitted = ImageOps.fit(
        image,
        target_size,
        method=RESAMPLING,
        bleed=bleed,
        centering=centering,
    )
    return (fitted, "fit")


def choose_mode(
    requested_mode: str,
    trimmed_size: tuple[int, int],
    target_size: tuple[int, int],
    max_crop_fraction: float,
    allow_upscale: bool,
) -> tuple[str, float]:
    crop_fraction = required_crop_fraction(trimmed_size, target_size)
    if requested_mode != "smart":
        return (requested_mode, crop_fraction)

    scale = max(target_size[0] / trimmed_size[0], target_size[1] / trimmed_size[1])
    if scale > 1.0 and not allow_upscale:
        return ("pad", crop_fraction)
    if crop_fraction <= max_crop_fraction:
        return ("fit", crop_fraction)
    return ("pad", crop_fraction)


def label_tile(image: Image.Image, label: str, tile_size: tuple[int, int]) -> Image.Image:
    tile = Image.new("RGBA", tile_size, (248, 248, 248, 255))
    framed = ImageOps.pad(image.convert("RGBA"), (tile_size[0] - 24, tile_size[1] - 56), color=(255, 255, 255, 255))
    tile.alpha_composite(framed, (12, 12))
    draw = ImageDraw.Draw(tile)
    draw.rectangle((0, tile_size[1] - 36, tile_size[0], tile_size[1]), fill=(238, 238, 238, 255))
    draw.text((12, tile_size[1] - 28), label, fill=(0, 0, 0, 255), font=ImageFont.load_default())
    return tile


def save_preview(
    original: Image.Image,
    trimmed: Image.Image,
    output: Image.Image,
    output_path: Path,
    mode_applied: str,
) -> Path:
    tile_size = (420, 260)
    gutter = 16
    labels = (
        ("original", original),
        ("trimmed", trimmed),
        (mode_applied, output),
    )
    tiles = [label_tile(image, label, tile_size) for label, image in labels]
    canvas = Image.new(
        "RGBA",
        (len(tiles) * tile_size[0] + (len(tiles) - 1) * gutter, tile_size[1]),
        (255, 255, 255, 255),
    )
    for index, tile in enumerate(tiles):
        canvas.alpha_composite(tile, (index * (tile_size[0] + gutter), 0))

    preview_path = output_path.with_name(output_path.stem + "-preview.jpg")
    canvas.convert("RGB").save(preview_path, quality=92)
    return preview_path


def default_output_path(input_path: Path) -> Path:
    return input_path.with_name(input_path.stem + "-prepared.png")


def save_image(image: Image.Image, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if output_path.suffix.lower() in (".jpg", ".jpeg"):
        image.convert("RGB").save(output_path, quality=95)
    else:
        image.save(output_path)


def main() -> None:
    args = parse_args()
    input_path = Path(args.input).expanduser().resolve()
    if not input_path.is_file():
        raise SystemExit(f"input not found: {input_path}")

    target_size = parse_size(args.size) if args.size else PRESETS[args.preset]
    output_path = Path(args.output).expanduser().resolve() if args.output else default_output_path(input_path)

    source = ImageOps.exif_transpose(Image.open(input_path)).convert("RGBA")
    background_name, background_rgba = resolve_background(source, args.background)
    trim_bbox = compute_trim_bbox(
        source,
        tolerance=args.tolerance,
        margin_ratio=args.margin_ratio,
        margin_px=args.margin_px,
        background_rgba=background_rgba,
    )
    trimmed = source.crop(trim_bbox)
    centering = ANCHORS[args.anchor]
    mode, crop_fraction = choose_mode(
        requested_mode=args.mode,
        trimmed_size=trimmed.size,
        target_size=target_size,
        max_crop_fraction=args.max_crop,
        allow_upscale=args.allow_upscale,
    )

    if mode == "none":
        output = contain_without_upscale(trimmed, target_size, args.allow_upscale)
        mode_applied = "none"
    elif mode == "pad":
        output = pad_to_canvas(trimmed, target_size, centering, background_rgba, args.allow_upscale)
        mode_applied = "pad"
    else:
        output, mode_applied = fit_to_canvas(
            trimmed,
            target_size,
            centering,
            args.bleed,
            args.allow_upscale,
            background_rgba,
        )

    save_image(output, output_path)
    preview_path = save_preview(source, trimmed, output, output_path, mode_applied) if args.preview else None

    summary = FigureSummary(
        input=str(input_path),
        output=str(output_path),
        preview=str(preview_path) if preview_path else None,
        mode_requested=args.mode,
        mode_applied=mode_applied,
        target_size=target_size,
        original_size=source.size,
        trimmed_size=trimmed.size,
        trim_bbox=trim_bbox,
        required_crop_fraction=round(crop_fraction, 4),
        max_crop_fraction=args.max_crop,
        anchor=args.anchor,
        background=background_name,
        allow_upscale=args.allow_upscale,
    )

    if args.summary_json:
        summary_path = Path(args.summary_json).expanduser().resolve()
        summary_path.parent.mkdir(parents=True, exist_ok=True)
        summary_path.write_text(json.dumps(asdict(summary), indent=2) + "\n")

    print(json.dumps(asdict(summary), indent=2))


if __name__ == "__main__":
    main()
