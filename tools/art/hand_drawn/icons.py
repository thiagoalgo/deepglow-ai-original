"""Deepglow HUD resource icons, hand-drawn as 16x16 ASCII maps.

Each map holds the FILL of the icon ('.' = transparent). The 1-px outline in
Shadow Absolute is added automatically on every transparent pixel that touches
the fill 4-neighbour-wise (clean, single-width, rounded corners).
Light comes from the top-left.
Run:  python3 tools/art/hand_drawn/icons.py   (writes assets/sprites/icons/<name>.png;
      preview sheet in the system temp dir)
"""
import os
from PIL import Image

import tempfile
HERE = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'assets', 'sprites', 'icons')

P = {
    '.': None,
    'k': (5, 5, 9),        # Shadow Absolute (outline / pupil)
    'o': (42, 33, 71),     # Character Outline
    'v': (86, 51, 168),    # Structure Violet
    'p': (198, 108, 156),  # Character Midtone
    'l': (244, 215, 165),  # Character Highlight
    'a': (246, 168, 74),   # Light Amber
    'y': (241, 237, 101),  # Light Sulfur Yellow
    'r': (237, 120, 183),  # Light Pink
    'w': (217, 245, 242),  # Light Blue White
    'D': (16, 26, 82),     # Structure Deep Blue
    'i': (37, 50, 140),    # Structure Indigo
    'x': (58, 70, 163),    # Structure Mid Blue
    'h': (154, 107, 222),  # Structure Highlight
    'q': (9, 42, 82),      # Water Abyss
    'd': (18, 88, 158),    # Water Midtone
    'e': (39, 116, 230),   # Water Electric Blue
    'c': (33, 200, 217),   # Water Cyan
    'm': (25, 93, 80),     # Vegetation Moss
    't': (55, 242, 194),   # Vegetation Neon Teal
    'g': (116, 232, 92),   # Vegetation Glow Green
}
OUTLINE = P['k']

ICONS = {
 # log lying on its side, cut face (rings) toward the viewer on the left
 'wood': [
  "................",
  "................",
  "................",
  "..lllllppppppp..",
  ".llaaallppppppp.",
  ".lalllalvvvvvvv.",
  ".lalllalvvvoooo.",
  ".lalalalvvvvvvv.",
  ".lalalaloooovvv.",
  ".lalalalvvvvvvv.",
  ".lalllapvvvvooo.",
  ".lalllapooooooo.",
  ".llaaapoooooooo.",
  "..lllppooooooo..",
  "................",
  "................"],
 # apple with stem and leaf
 'fruit': [
  "................",
  "..........gg....",
  "........oggm....",
  "........om......",
  "...rrrr.orrrp...",
  "..rrrrrrrrrrrp..",
  ".rrllrrrrrrrrpp.",
  ".rlllrrrrrrrrpp.",
  ".rllrrrrrrrrppp.",
  ".rrrrrrrrrrpppp.",
  ".rrrrrrrrrppppp.",
  ".prrrrrrrpppppp.",
  "..pprrrpppppppp.",
  "...pppppppppp...",
  "....pppp.ppp....",
  "................"],
 # water drop
 'water': [
  "................",
  ".......ce.......",
  ".......ce.......",
  "......ceed......",
  "......ceed......",
  ".....cceeed.....",
  "....cceeeedd....",
  "...cweeeeeedd...",
  "...cweeeeeedd...",
  "..ccweeeeeeddd..",
  "..cceeeeeeeddd..",
  "..deeeeeeeddqd..",
  "...ddeeeeddqq...",
  "....ddddddqq....",
  ".....qqqqqq.....",
  "................"],
 # rounded boulder with a lit top plane
 'stone': [
  "................",
  "................",
  "................",
  "......hhhx......",
  "....hhxxxxxi....",
  "...hxxxxxxxxi...",
  "..hxxxxxxxxxii..",
  ".hxxxxxxxxxxiii.",
  ".hxxxxxxxxxiiii.",
  ".xxxxxxxxiiiiii.",
  ".xxxxxxiiiiiiDD.",
  ".ixxiiiiiiiiDDD.",
  "..iiiiiiiiDDDD..",
  "...DDDDDDDDDD...",
  "................",
  "................"],
 # fish swimming left
 'fish': [
  "................",
  "................",
  "................",
  ".....ccc........",
  "...ccccccc...cc.",
  "..ccccceeee.cce.",
  ".ccwkeeeeee.ced.",
  ".ceeeedeeeeee...",
  ".keeeedeeeeed...",
  "..deeedeeeeed...",
  "..ddeeeeeeed.dd.",
  "...dddddddd.ddd.",
  ".....dddddd..dd.",
  "................",
  "................",
  "................"],
 # drumstick: meat lower-left, bone up-right
 'meat': [
  "................",
  "...........ww...",
  "..........wwwww.",
  ".........wwl.wl.",
  "........wwl.....",
  "......rrwl......",
  "....rrrrrrp.....",
  "...rrllrrrpp....",
  "..rllrrrrppo....",
  ".rrlrrrrrppo....",
  ".rrrrrrrppo.....",
  ".prrrrrpppo.....",
  ".pprrpppoo......",
  "..pppppoo.......",
  "...oooo.........",
  "................"],
 # copper ore chunk cluster
 'copper': [
  "................",
  "................",
  "..........aaa...",
  ".........aaapp..",
  "...aaa...aaappo.",
  "..aaaap..aapppo.",
  ".aaaappp.appooo.",
  ".aappppo..pooo..",
  ".appppoo........",
  ".appppoo..aaap..",
  ".pppppoo.aaappo.",
  ".ppppooo.apppoo.",
  "..ppooo..ppoooo.",
  "...ooo....oooo..",
  "................",
  "................"],
 # iron ingot / bar, top-front-right view
 'iron': [
  "................",
  "................",
  "................",
  "....hhhhhhhh....",
  "...xhwwhhhhhi...",
  "...xhhwwhhhhi...",
  "..xxhhhwwhhhii..",
  "..xxxxxxxxxxii..",
  "..xwxxxxxxxxii..",
  ".xxwxxxxxxxxxii.",
  ".xxxxxxxxxxxxii.",
  ".xxxxxxxxxxxxii.",
  ".iiiiiiiiiiiiii.",
  "................",
  "................",
  "................"],
 # lumpy gold nugget
 'gold': [
  "................",
  "................",
  "................",
  ".....yyyy.......",
  "...yyywyyya.....",
  "..yywyyyyyyaa...",
  ".yyyyaaayyyyyaa.",
  ".yyyyyyyyyyyaaa.",
  ".yyyyyyyyyyyyaa.",
  ".ayyyyyaaayyyaa.",
  ".aayyyyyyyyaaaa.",
  "..aaayyyyaaaaa..",
  "...aaaaaaaaaa...",
  ".....aaaaaa.....",
  "................",
  "................"],
 # single tall crystal (hex prism, pointed ends)
 'crystal': [
  "................",
  ".......wc.......",
  "......wtcc......",
  ".....wttccm.....",
  "....wtttcccm....",
  "...wttttcccmm...",
  "...twtttcccmm...",
  "...twtttcccmm...",
  "...tttttcccmm...",
  "...tttttcccmm...",
  "...tttttcccmm...",
  "...tttttcccmm...",
  "....ttttccmm....",
  ".....tttcmm.....",
  "......ttmm......",
  "................"],
}

ORDER = ['wood', 'fruit', 'water', 'stone', 'fish', 'meat', 'copper', 'iron', 'gold', 'crystal']


def render(rows):
    assert len(rows) == 16 and all(len(r) == 16 for r in rows), [len(r) for r in rows]
    filled = [[P[ch] is not None for ch in row] for row in rows]
    im = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    for y in range(16):
        for x in range(16):
            c = P[rows[y][x]]
            if c:
                im.putpixel((x, y), c + (255,))
            elif any(0 <= x + dx < 16 and 0 <= y + dy < 16 and filled[y + dy][x + dx]
                     for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                im.putpixel((x, y), OUTLINE + (255,))
    return im


def main():
    imgs = []
    for name in ORDER:
        im = render(ICONS[name])
        im.save(os.path.join(HERE, f'{name}.png'))
        imgs.append(im)
    s, gap, pad = 8, 16, 16
    cell = 16 * s
    w = pad * 2 + len(imgs) * cell + (len(imgs) - 1) * gap
    small_y = pad + cell + pad
    h = small_y + 16 + pad
    sheet = Image.new('RGBA', (w, h), (8, 13, 36, 255))
    for i, im in enumerate(imgs):
        x = pad + i * (cell + gap)
        sheet.alpha_composite(im.resize((cell, cell), Image.NEAREST), (x, pad))
        sheet.alpha_composite(im, (x + cell // 2 - 8, small_y))
    sheet.convert('RGB').save(os.path.join(tempfile.gettempdir(), 'icons_preview.png'))


if __name__ == '__main__':
    main()
