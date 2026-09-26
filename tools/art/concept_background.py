#!/usr/bin/env python3
"""Build the 640x360 scene background from a concept painting as real pixel art.

Steps (no blending anywhere, so the result is palette-only with crisp edges):
1. Resize to 1920x1080 and soften slightly (kills generator noise).
2. Map every pixel to the nearest of the 24 palette colors.
3. Downscale by majority vote per block (each output pixel takes its block's most common color).
4. Remove isolated pixels (a pixel matching none of its 4 neighbours takes their majority).
5. The background is drawn at 320x180 and upscaled 2x (nearest): its pixels are twice the size of
   the sprites' pixels, so the scenery reads as a backdrop and the board stands out.

Usage: python3 tools/art/concept_background.py <concept.png> [out.png]
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


def nearest_indices(img: Image.Image, pal: np.ndarray) -> np.ndarray:
    a = np.asarray(img.convert('RGB')).astype(np.float32)
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
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / 'assets' / 'sprites' / 'board' / 'background.png'
    pal = palette()
    work = Image.open(sys.argv[1]).convert('RGB').resize(WORK_SIZE, Image.LANCZOS).filter(ImageFilter.GaussianBlur(0.8))
    idx = nearest_indices(work, pal)
    block = WORK_SIZE[0] // (OUT_SIZE[0] // PIXEL_SCALE)
    idx = remove_lonely(block_majority(idx, block, len(pal)), len(pal))
    img = Image.fromarray(pal[idx].astype(np.uint8)).resize(OUT_SIZE, Image.NEAREST)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print(out)


if __name__ == '__main__':
    main()
