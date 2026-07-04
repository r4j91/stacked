#!/usr/bin/env python3
"""Sincroniza ícones carvão e arredonda cantos dos favicons (aba do navegador)."""

from __future__ import annotations

import shutil
from io import BytesIO
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parent
SOURCE = REPO / "assets" / "stacked-icones-web" / "carvao"
VARIANT = ROOT / "public" / "icons" / "variants" / "carvao"
APP = ROOT / "app"

# Raio estilo iOS (~22%) — remove o quadrado visível na aba
CORNER_RATIO = 0.223

ALL_FILES = [
    "favicon.ico",
    "favicon-16.png",
    "favicon-32.png",
    "favicon-48.png",
    "apple-touch-icon.png",
    "icon-192.png",
    "icon-512.png",
    "icon-1024.png",
]

FAVICON_ROUND = {"favicon-16.png", "favicon-32.png", "favicon-48.png"}


def _round_corners(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    radius = max(2, int(min(w, h) * CORNER_RATIO))
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, w - 1, h - 1), radius=radius, fill=255)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def _save_png(path: Path, im: Image.Image) -> None:
    im.save(path, optimize=True)


def _save_ico(path: Path, sizes: list[int]) -> None:
    frames = []
    for size in sizes:
        src = SOURCE / f"favicon-{size}.png"
        frames.append(_round_corners(Image.open(src)).resize((size, size), Image.Resampling.LANCZOS))
    frames[0].save(
        path,
        format="ICO",
        sizes=[(s, s) for s in sizes],
        append_images=frames[1:],
    )


def main() -> None:
    if not SOURCE.is_dir():
        raise SystemExit(f"Missing {SOURCE}")

    VARIANT.mkdir(parents=True, exist_ok=True)
    APP.mkdir(parents=True, exist_ok=True)

    for name in ALL_FILES:
        src = SOURCE / name
        if not src.is_file():
            raise SystemExit(f"Missing {src}")
        dst = VARIANT / name
        if name in FAVICON_ROUND:
            _save_png(dst, _round_corners(Image.open(src)))
        elif name == "favicon.ico":
            _save_ico(dst, [16, 32, 48])
        else:
            shutil.copy2(src, dst)
        print(f"✓ {dst.relative_to(ROOT)}")

    _save_ico(APP / "favicon.ico", [16, 32, 48])
    _save_png(APP / "icon.png", _round_corners(Image.open(SOURCE / "icon-512.png")))
    shutil.copy2(SOURCE / "apple-touch-icon.png", APP / "apple-icon.png")
    print("✓ app/favicon.ico, app/icon.png (cantos arredondados), app/apple-icon.png")


if __name__ == "__main__":
    main()
