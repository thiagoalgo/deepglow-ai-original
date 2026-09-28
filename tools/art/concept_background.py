#!/usr/bin/env python3
"""Build the 640x360 scene background from a concept painting as real pixel art.

Steps (no blending anywhere, so the result is palette-only with crisp edges):
1. Resize to 1920x1080 and soften slightly (kills generator noise).
2. Map every pixel to the nearest of the 24 palette colors.
3. Downscale by majority vote per block (each output pixel takes its block's most common color).
4. Remove isolated pixels (a pixel matching none of its 4 neighbours takes their majority).
5. The background is drawn at 320x180 and upscaled 2x (nearest): its pixels are twice the size of
   the sprites' pixels, so the scenery reads as a backdrop and the board stands out.

Usage: python3 tools/art/concept_background.py <concept.png> [out.png] [--lab] [--warm-boost K]
  --lab           match colors in CIELAB (perceptual) instead of RGB: keeps pale ice/snow
                  from turning lilac (used for the biome backgrounds).
  --warm-boost K  brighten reds/oranges by K before matching, so embers and lava land on
                  the palette's amber/pink instead of dark violet (the palette has no red).
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
GPL = ROOT / 'assets' / 'palettes' / 'deepglow.gpl'
OUT_SIZE = (640, 360)
PIXEL_SCALE = 2          # background pixel = 2x2 screen pixels
WORK_SIZE = (1920, 1080)


def palette() -> np.ndarray:
    rows = [line.split()[:3] for line in GPL.read_text().splitlines() if line.strip()[:1].isdigit()]
    return np.array([[int(v) for v in r] for r in rows], np.float32)


def to_lab(rgb: np.ndarray) -> np.ndarray:
    c = rgb / 255.0
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]], np.float32)
    xyz = c @ m.T / np.array([0.95047, 1.0, 1.08883], np.float32)
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def warm_boost(a: np.ndarray, k: float) -> np.ndarray:
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    warmth = np.clip((r - np.maximum(g, b)) / 80.0, 0.0, 1.0)[..., None]
    return np.clip(a * (1.0 + (k - 1.0) * warmth), 0, 255)


def nearest_indices(img: Image.Image, pal: np.ndarray, lab: bool = False, warm: float = 1.0) -> np.ndarray:
    a = np.asarray(img.convert('RGB')).astype(np.float32)
    if warm != 1.0:
        a = warm_boost(a, warm)
    if lab:
        a, pal = to_lab(a), to_lab(pal)
    out = np.empty(a.shape[:2], np.uint8)
    for y0 in range(0, a.shape[0], 64):
        blk = a[y0:y0 + 64]
        out[y0:y0 + 64] = ((blk[:, :, None, :] - pal[None, None]) ** 2).sum(-1).argmin(-1)
    return out


def block_majority(idx: np.ndarray, block: int, n: int) -> np.ndarray:
    h, w = idx.shape[0] // block, idx.shape[1] // block
    blocks = idx[:h * block, :w * block].reshape(h, block, w, block).transpose(0, 2, 1, 3).reshape(h, w, -1)
    counts = np.stack([(blocks == k).sum(-1) for k in range(n)], -1)
    return counts.argmax(-1).astype(np.uint8)


def remove_lonely(idx: np.ndarray, n: int, passes: int = 1) -> np.ndarray:
    for _ in range(passes):
        p = np.pad(idx, 1, mode='edge')
        nb = np.stack([p[:-2, 1:-1], p[2:, 1:-1], p[1:-1, :-2], p[1:-1, 2:]])
        lonely = (nb != idx[None]).all(0)
        counts = np.stack([(nb == k).sum(0) for k in range(n)], -1)
        idx = np.where(lonely, counts.argmax(-1), idx).astype(np.uint8)
    return idx


def main() -> None:
    args = [a for a in sys.argv[1:]]
    lab = '--lab' in args
    warm = 1.0
    if '--warm-boost' in args:
        i = args.index('--warm-boost')
        warm = float(args[i + 1])
        del args[i:i + 2]
    args = [a for a in args if a != '--lab']
    out = Path(args[1]) if len(args) > 1 else ROOT / 'assets' / 'sprites' / 'board' / 'background.png'
    pal = palette()
    work = Image.open(args[0]).convert('RGB').resize(WORK_SIZE, Image.LANCZOS).filter(ImageFilter.GaussianBlur(0.8))
    idx = nearest_indices(work, pal, lab, warm)
    block = WORK_SIZE[0] // (OUT_SIZE[0] // PIXEL_SCALE)
    idx = remove_lonely(block_majority(idx, block, len(pal)), len(pal))
    img = Image.fromarray(pal[idx].astype(np.uint8)).resize(OUT_SIZE, Image.NEAREST)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print(out)


if __name__ == '__main__':
    main()
