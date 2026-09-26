#!/usr/bin/env python3
"""Deepglow palette tools.

Usage:
  python3 tools/art/palette.py png   [--out assets/palettes/deepglow_palette.png] [--swatch 1]
  python3 tools/art/palette.py check IMG [IMG ...]         # list colors outside the palette
  python3 tools/art/palette.py apply IMG [IMG ...] [--suffix _pal] [--inplace]
                                                            # quantize to the palette (nearest color)
  (--gpl PATH goes before the subcommand to use another palette)

Requires Pillow (pip install pillow). Alpha < 128 becomes fully transparent;
alpha >= 128 becomes opaque (pixel art does not use semi-transparency by default).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_GPL = ROOT / "assets" / "palettes" / "deepglow.gpl"


def load_gpl(path: Path) -> list[tuple[str, tuple[int, int, int]]]:
    colors = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or ":" in line or line == "GIMP Palette":
            continue
        parts = line.split(None, 3)
        if len(parts) >= 3 and all(p.isdigit() for p in parts[:3]):
            name = parts[3] if len(parts) > 3 else ""
            colors.append((name, (int(parts[0]), int(parts[1]), int(parts[2]))))
    return colors


def _pil():
    try:
        from PIL import Image  # noqa: F401
        return Image
    except ImportError:
        sys.exit("Pillow is not installed: pip install pillow")


def cmd_png(args) -> None:
    Image = _pil()
    colors = load_gpl(Path(args.gpl))
    cols = 6
    rows = (len(colors) + cols - 1) // cols
    img = Image.new("RGBA", (cols * args.swatch, rows * args.swatch), (0, 0, 0, 0))
    for i, (_, rgb) in enumerate(colors):
        x, y = (i % cols) * args.swatch, (i // cols) * args.swatch
        for dx in range(args.swatch):
            for dy in range(args.swatch):
                img.putpixel((x + dx, y + dy), rgb + (255,))
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print(f"{len(colors)} colors -> {out}")


def _pixels(img) -> list[tuple[int, int, int, int]]:
    raw = img.tobytes()
    return [tuple(raw[i:i + 4]) for i in range(0, len(raw), 4)]


def _nearest(rgb, palette):
    return min(palette, key=lambda p: (p[0] - rgb[0]) ** 2 + (p[1] - rgb[1]) ** 2 + (p[2] - rgb[2]) ** 2)


def cmd_check(args) -> None:
    Image = _pil()
    palette = {rgb for _, rgb in load_gpl(Path(args.gpl))}
    bad_total = 0
    for f in args.images:
        img = Image.open(f).convert("RGBA")
        pixels = _pixels(img)
        off = {px[:3] for px in pixels if px[3] >= 128 and px[:3] not in palette}
        semi = sum(1 for px in pixels if 0 < px[3] < 255)
        bad_total += len(off)
        status = "OK" if not off and not semi else "OFF"
        print(f"[{status}] {f}: {len(off)} colors outside the palette, {semi} semi-transparent pixels")
    sys.exit(1 if bad_total else 0)


def cmd_apply(args) -> None:
    Image = _pil()
    palette = [rgb for _, rgb in load_gpl(Path(args.gpl))]
    for f in args.images:
        src = Path(f)
        img = Image.open(src).convert("RGBA")
        cache: dict = {}
        out_px = []
        for r, g, b, a in _pixels(img):
            if a < 128:
                out_px.append((0, 0, 0, 0))
                continue
            key = (r, g, b)
            if key not in cache:
                cache[key] = _nearest(key, palette)
            out_px.append(cache[key] + (255,))
        img.putdata(out_px)
        dst = src if args.inplace else src.with_name(src.stem + args.suffix + src.suffix)
        img.save(dst)
        print(f"{src} -> {dst}")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--gpl", default=str(DEFAULT_GPL))
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("png", help="generate a palette swatch PNG")
    p.add_argument("--out", default=str(ROOT / "assets" / "palettes" / "deepglow_palette.png"))
    p.add_argument("--swatch", type=int, default=1, help="swatch size in px")
    p.set_defaults(func=cmd_png)

    p = sub.add_parser("check", help="check that images only use the palette")
    p.add_argument("images", nargs="+")
    p.set_defaults(func=cmd_check)

    p = sub.add_parser("apply", help="quantize images to the palette")
    p.add_argument("images", nargs="+")
    p.add_argument("--suffix", default="_pal")
    p.add_argument("--inplace", action="store_true")
    p.set_defaults(func=cmd_apply)

    args = ap.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
