#!/usr/bin/env python3
"""Deepglow tool cursors (24x24), hand-drawn as ASCII pixel maps.

Each character is one pixel; '.' is transparent. Light comes from the top-left.
Run from anywhere: writes assets/sprites/cursors/<name>.png (preview sheet in the temp dir).
"""
from pathlib import Path
from PIL import Image

import tempfile
HERE = Path(__file__).resolve().parents[3] / 'assets' / 'sprites' / 'cursors'
PAL = {
    'k': (5, 5, 9),        # Shadow Absolute (outline)
    'n': (19, 26, 69),     # Shadow Lifted (cup interior)
    'i': (37, 50, 140),    # Structure Indigo (metal shadow)
    'm': (58, 70, 163),    # Structure Mid Blue (metal)
    'h': (154, 107, 222),  # Structure Highlight (metal light / crystal)
    'w': (217, 245, 242),  # Light Blue White (shine, fishing line)
    'v': (86, 51, 168),    # Structure Violet (wood shadow / crystal shadow)
    'p': (198, 108, 156),  # Character Midtone (wood / amber shadow)
    'c': (244, 215, 165),  # Character Highlight (rod grip)
    'a': (246, 168, 74),   # Light Amber (copper head)
    'y': (241, 237, 101),  # Light Sulfur Yellow (copper light)
    'r': (237, 120, 183),  # Light Pink (bobber)
}
# hotspot = working tip of each tool (x, y)
HOTSPOT = {
    'lock': (11, 15), 'axe': (22, 7), 'cup': (9, 3), 'pickaxe': (6, 4),
    'fishing_rod': (21, 2), 'spear': (22, 1), 'ore_pick': (4, 5), 'crystal_pick': (4, 5),
}

SPRITES = {
    'lock': [
        "........................",
        ".........kkkkkk.........",
        "........khhhhhhk........",
        ".......khmmmmmmik.......",
        "......khmkkkkkkmik......",
        "......khmk....kmik......",
        "......khmk....kmik......",
        "......khmk....kmik......",
        "......khmk....kmik......",
        "......khmk....kmik......",
        ".....kkhmkkkkkkmikk.....",
        "....kwwwwhhhhhhhhhhk....",
        "...khwmmmmmmmmmmmmmik...",
        "...khmmmmmmmmmmmmmmik...",
        "...khmmmmmmkkmmmmmmik...",
        "...khmmmmmkkkkmmmmmik...",
        "...khmmmmmmkkmmmmmmik...",
        "...khmmmmmmkkmmmmmmik...",
        "...khmmmmmmkkmmmmmmik...",
        "...khmmmmmmmmmmmmmmik...",
        "...khmmmmmmmmmmmmmmik...",
        "....kiiiiiiiiiiiiiik....",
        ".....kkkkkkkkkkkkkk.....",
        "........................",
    ],
    'axe': [
        "...................kk...",
        "..................khwk..",
        ".................khmmwk.",
        "............kkk.khmmhwk.",
        "...........khhhkhmmmmhwk",
        "..........khmmmhmmmmmhwk",
        "..........kmmmmmmmmmmhwk",
        "..........kmmmmmmmmmmhwk",
        "..........kmmmmimmmmmhwk",
        "..........kiiiikimmmmhwk",
        "...........kpvk.kimmmhwk",
        "..........kpvk...kimmmwk",
        ".........kpvk.....kimwk.",
        "........kpvk.......kiwk.",
        ".......kpvk.........kk..",
        "......kpvk..............",
        ".....kpvk...............",
        "....kpvk................",
        "...kpvk.................",
        "..kpvk..................",
        ".kpvk...................",
        "kpvk....................",
        ".kk.....................",
        "........................",
    ],
    'cup': [
        "........................",
        "........................",
        "....kkkkkkkkkkk.........",
        "...khhhhhhhhhhhk........",
        "..khnnnnnnnnnnnmk.......",
        "..khnnnnnnnnnnnmk.......",
        "..khwhhhhhhhhmmmk.......",
        "..khwhmmmmmmmiiikkkk....",
        "..khwhmmmmmmmiiihhhhk...",
        "..khwhmmmmmmmiiimmmmik..",
        "..khwhmmmmmmmiiikkkmik..",
        "..khwhmmmmmmmiiik.kmik..",
        "..khwhmmmmmmmiiik.kmik..",
        "..khwhmmmmmmmiiik.kmik..",
        "..khwhmmmmmmmiiikkkmik..",
        "..khwhmmmmmmmiiimmmmik..",
        "..khwhmmmmmmmiiiiiiik...",
        "..khwhmmmmmmmiiikkkk....",
        "..khwhmmmmmmmiiik.......",
        "..khwhmmmmmmmiiik.......",
        "...kiiiiiiiiiiik........",
        "....kkkkkkkkkkk.........",
        "........................",
        "........................",
    ],
    'pickaxe': [
        ".........kkkkkk.........",
        "......kkkhhwwhhkkkk.....",
        ".....khhhiiimmmhhwhk....",
        "....khiiikkkiimmmmmhk...",
        "....kiikk...kkiimmmmmk..",
        ".....kk.......kkiimmmik.",
        "................kpmmmik.",
        "...............kpvmmmik.",
        "..............kpvkkhmik.",
        ".............kpvk.khmmik",
        "............kpvk...khmik",
        "...........kpvk....khmik",
        "..........kpvk......khik",
        ".........kpvk.......khik",
        "........kpvk........khik",
        ".......kpvk........khik.",
        "......kpvk.........khik.",
        ".....kpvk.........khmik.",
        "....kpvk..........khik..",
        "...kpvk............kk...",
        "..kpvk..................",
        ".kpvk...................",
        "..kk....................",
        "........................",
    ],
    'fishing_rod': [
        "........................",
        ".....................k..",
        "....................kpk.",
        "...................kpwk.",
        "..................kpkwk.",
        ".................kpkkwk.",
        "................kpk.kwk.",
        "...............kpk..kwk.",
        "..............kpk...kwk.",
        ".............kpk....kwk.",
        "............kpk.....kwk.",
        "...........kpk......kwk.",
        "..........kpk.......kwk.",
        ".........kpk........krk.",
        "........kpvk.......krrpk",
        ".......kpvhmk......kwwhk",
        "......kpvkmik.......khk.",
        ".....kpvk.kk.........k..",
        "....kcpk................",
        "...kcpk.................",
        "..kcpk..................",
        ".kcpk...................",
        "..kk....................",
        "........................",
    ],
    'spear': [
        ".....................kk.",
        "...................kkhwk",
        ".................kkhhwik",
        "................khhhwik.",
        "...............khhhwmik.",
        "...............khhwmik..",
        "...............khwmmik..",
        "..............khwiiik...",
        "..............kwikkk....",
        ".............kyak.......",
        "............kyak........",
        "...........kpvk.........",
        "..........kpvk..........",
        ".........kpvk...........",
        "........kpvk............",
        ".......kpvk.............",
        "......kpvk..............",
        ".....kpvk...............",
        "....kpvk................",
        "...kpvk.................",
        "..kpvk..................",
        ".kpvk...................",
        "..kk....................",
        "........................",
    ],
    'ore_pick': [
        ".........kkkkkk.........",
        "......kkkyyyyyykkkk.....",
        ".....kyyyaaaaaayyyyk....",
        "....kyaapppaaaaaaaayk...",
        "...kyappkkkppaaaaaaaak..",
        "...kppkk...kkppaaaaaapk.",
        "....kk.......kkpppaaapk.",
        "...............kpvaaapk.",
        "..............kpvyaaapk.",
        ".............kpvkkyaaapk",
        "............kpvk.kyaaapk",
        "...........kpvk...kyaapk",
        "..........kpvk....kyaapk",
        ".........kpvk......kyapk",
        "........kpvk.......kyapk",
        ".......kpvk........kypk.",
        "......kpvk........kyapk.",
        ".....kpvk.........kyapk.",
        "....kpvk.........kyapk..",
        "...kpvk..........kapk...",
        "..kpvk............kk....",
        ".kpvk...................",
        "..kk....................",
        "........................",
    ],
    'crystal_pick': [
        ".........kkkkkk.........",
        "......kkkhwwhhhkkkk.....",
        ".....khwhhhhvhhhwwhk....",
        "....khhhvvvhhvhhhhhhk...",
        "...kwhvvkkkvvhvhhhhhhk..",
        "...kvvkk...kkvvhhhhhhvk.",
        "....kk.......kkvvphhhvk.",
        "...............kpvhhhvk.",
        "..............kpvwhhhvk.",
        ".............kpvkkwvhhvk",
        "............kpvk.kwhvhvk",
        "...........kpvk...kwhvvk",
        "..........kpvk....khhhvk",
        ".........kpvk......khhvk",
        "........kpvk.......kwhvk",
        ".......kpvk........khvk.",
        "......kpvk........khhvk.",
        ".....kpvk.........khhvk.",
        "....kpvk.........kwhvk..",
        "...kpvk..........khvk...",
        "..kpvk............kk....",
        ".kpvk...................",
        "..kk....................",
        "........................",
    ],
}


def draw(rows, size=24):
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
        assert len(rows) == 24 and all(len(r) == 24 for r in rows), name
        im = draw(rows)
        im.save(HERE / f'{name}.png')
        imgs.append(im)
        print(name, 'hotspot', HOTSPOT[name])
    preview(imgs, Path(tempfile.gettempdir()) / 'cursors_preview.png')
