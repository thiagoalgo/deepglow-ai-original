#!/usr/bin/env python3
"""Deepglow upgrade-tree icons (20x20), hand-drawn as ASCII pixel maps.

Each character is one pixel; '.' is transparent. Light comes from the top-left.
Run from anywhere: writes assets/sprites/upgrades/<name>.png (preview sheet in the temp dir).
"""
from pathlib import Path
from PIL import Image

import tempfile
HERE = Path(__file__).resolve().parents[3] / 'assets' / 'sprites' / 'upgrades'
PAL = {
    'k': (5, 5, 9),        # Shadow Absolute (outline)
    'n': (19, 26, 69),     # Shadow Lifted (empty glass)
    'i': (37, 50, 140),    # Structure Indigo (metal shadow)
    'm': (58, 70, 163),    # Structure Mid Blue (metal)
    'h': (154, 107, 222),  # Structure Highlight (metal light, eye-white shade)
    'w': (217, 245, 242),  # Light Blue White (shine, eye white, sparkle)
    'o': (42, 33, 71),     # Character Outline (basket/bark dark)
    'v': (86, 51, 168),    # Structure Violet (wood)
    'p': (198, 108, 156),  # Character Midtone (wood / basket)
    'c': (244, 215, 165),  # Character Highlight (basket light, cork, log face)
    'a': (246, 168, 74),   # Light Amber (sun shadow)
    'y': (241, 237, 101),  # Light Sulfur Yellow (sun, sparkle core)
    'b': (18, 88, 158),    # Water Midtone
    'e': (39, 116, 230),   # Water Electric Blue
    'q': (33, 200, 217),   # Water Cyan
    't': (55, 242, 194),   # Vegetation Neon Teal (rune glow)
}

SPRITES = {
    'basket': [
        ".........kk.........",
        ".......kkcckk.......",
        "......kccppppk......",
        ".....kcppkkoopk.....",
        "....kcpkk..kkopk....",
        "....kcpk....kopk....",
        "...kcpk......kopk...",
        "...kcpk......kopk...",
        ".kkkppkkkkkkkkopkkk.",
        "kcccccccccccccccccpk",
        ".kccpcccpcccpcccpok.",
        ".kppopppopppopppook.",
        ".kpcccpcccpcccpccok.",
        "..kpppopppopppopok..",
        "..kcpcccpcccpcccok..",
        "..kpopppopppopppok..",
        "...kccpcccpcccpok...",
        "...kppopppopppook...",
        "....kooooooooook....",
        ".....kkkkkkkkkk.....",
    ],
    'canteen': [
        "........kkkk........",
        ".......kcccpk.......",
        "......kcppppvkk.....",
        ".......khnnnkpvk....",
        ".......khnnnkkpvk...",
        "......kknnnnkkkpvk..",
        ".....knnnnnnnnkkpvk.",
        "....knnnnnnnnnnkpvk.",
        "...knwnnnnnnnnnnkvk.",
        "...kwqqqqqqqqqqbkk..",
        "..keqeeeeeeeeeeebk..",
        "..keqeeeeeeeeeeebk..",
        "..keqeeeeeeeeeeebk..",
        "..keeqeeeeeeeeebbk..",
        "...keeeeeeeeeeebk...",
        "...keeeeeeeeeebbk...",
        "....keeeeeeeebbk....",
        ".....keeeeebbbk.....",
        "......kkbbbbkk......",
        "........kkkk........",
    ],
    'keen_eye': [
        ".........kk.........",
        "........kqqk........",
        "...kk...kqek...kk...",
        "..kqqk...kk...kqqk..",
        "..kqek........kqek..",
        "...kk..kkkkkk..kk...",
        ".....kkwwwwwwkk.....",
        "...kkwwweeeewwwkk...",
        "..kwwwwewqqqewwwwk..",
        ".kwwwwweqkkqqwwwwwk.",
        ".kwwwwwqqkkqewwwwhk.",
        "..kwwwwqqqqqewwwhk..",
        "...kkwwwqqqewwhkk...",
        ".....kkwhhhhhkk.....",
        "...kk..kkkkkk..kk...",
        "..kqek...kk...kqek..",
        "..kqek..kqek..kqek..",
        "...kk...kqek...kk...",
        ".........kk.........",
        "....................",
    ],
    'longer_days': [
        ".........kk.........",
        "..kk....kyak....kk..",
        ".kyak...kaak...kyak.",
        ".kaak...kkkk...kaak.",
        "..kk..kkyyyykk..kk..",
        ".....kywwyyyyak.....",
        "....kywyyyyyyyak....",
        "....kyyyyyyyyyak....",
        ".kkkyyyyyyyyyyyakkk.",
        "kyakyyyyyyyyyyyakyak",
        "kaakyyyyyyyyyyaakaak",
        ".kkkyyyyyyyyyyaakkk.",
        "....kyyyyyyyyaak....",
        "....kyyyyyyyaaak....",
        ".....kyyyaaaaak.....",
        "..kk..kkaaaakk..kk..",
        ".kyak...kkkk...kyak.",
        ".kaak...kyak...kaak.",
        "..kk....kaak....kk..",
        ".........kk.........",
    ],
    'lumber_sense': [
        "....................",
        "....................",
        ".....kkkkkkkkkkkkk..",
        "....kvvvvccccccccck.",
        "...kvvccvvpppppppppk",
        "..kvccttccvppppppppk",
        ".kvccttttccvvvvvvvvk",
        ".kvctcccctcvoooovvvk",
        ".kvctcccctcvvvvvvvvk",
        ".kvctcqqctcvvvvvvvvk",
        ".kvctcqqctcvvvvooovk",
        ".kvctcccctcvoovvvvvk",
        ".kvctcccctcvvvvvvvvk",
        ".kvccttttccvvvvvvvvk",
        "..kvccttccvooooooook",
        "...kvvccvvoooooooook",
        "....kvvvvoooooooook.",
        ".....kkkkkkkkkkkkk..",
        "....................",
        "....................",
    ],
    'sharp_axe': [
        ".................k..",
        "................kwk.",
        "...............kwywk",
        ".............kk.kwk.",
        "............khwk.k..",
        ".......kkk.khmhwk...",
        "......khhhkhmmhwk...",
        ".....khmmmhmmmmhwk..",
        ".....kmmmmmmmmmhwk..",
        ".....kmmmmmmmmmhwk..",
        ".....kimmmimmmmhwk..",
        "......kiiikimmmhwk..",
        ".......kpvkkimmmwk..",
        "......kpvk..kimwk...",
        ".....kpvk....kiwk...",
        "....kpvk......kk....",
        "...kpvk.............",
        "..kpvk..............",
        ".kpvk...............",
        "..kk................",
    ],
}


def draw(rows, size=20):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != '.':
                img.putpixel((x, y), PAL[ch] + (255,))
    return img


def preview(imgs, path, scale=8, bg=(8, 13, 36, 255)):
    w = imgs[0].size[0]
    pad = scale
    sheet = Image.new('RGBA', (pad + len(imgs) * (w * scale + pad), pad + w * scale + pad + w + pad), bg)
    for i, im in enumerate(imgs):
        sheet.alpha_composite(im.resize((w * scale, w * scale), Image.NEAREST), (pad + i * (w * scale + pad), pad))
        sheet.alpha_composite(im, (pad + i * (w * scale + pad), pad + w * scale + pad))
    sheet.save(path)


if __name__ == '__main__':
    imgs = []
    for name, rows in SPRITES.items():
        assert len(rows) == 20 and all(len(r) == 20 for r in rows), name
        im = draw(rows)
        im.save(HERE / f'{name}.png')
        imgs.append(im)
    preview(imgs, Path(tempfile.gettempdir()) / 'upgrades_preview.png')
