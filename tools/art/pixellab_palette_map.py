#!/usr/bin/env python3
"""Map a Pixellab /image-to-pixelart result onto the 24-color palette without losing its drawing.

Pixellab returns natural colors on a grey background. This script removes the background and
maps EACH DISTINCT COLOR (not each pixel) to a palette color: colors are grouped by material
(hue), sorted by luminance and spread over that material's ramp (concept_to_sprite.RAMPS).
Near-black becomes Shadow Absolute (crisp outline); stray lines/specks are dropped.
Per-item material remaps live in CFG (keys are the item ids, "icon_<resource>" for HUD icons).

Usage: python3 tools/art/pixellab_palette_map.py <item_id> <pixellab_image.png> <out.png>

Pipeline (M4, board sources): crop the item from the concept art without background, 4x the
target size -> Pixellab /image-to-pixelart (fixer=false, init_image_strength=0, seed 11) via
tools/pixellab/pixellab.py -> this script -> assets/sprites/sources/<id>.png.
"""
import sys, colorsys, json
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent))
from collections import Counter
from PIL import Image
from concept_to_sprite import remove_bg_multi, material, lum, RAMPS, C, REMAP
BLACK = (5, 5, 9)
METAL = {'stone': 'metal', 'water': 'metal'}
CFG = {
 'tree_glow': REMAP['tree_glow'], 'iron_vein': REMAP['iron_vein'], 'copper_vein': REMAP['copper_vein'],
 'gold_vein': REMAP['gold_vein'], 'crystal_violet': REMAP['crystal_violet'], 'crystal_teal': REMAP['crystal_teal'],
 'boar': {'stone': 'wood', 'fruit': 'wood'},
 'icon_water': {'stone': 'water'}, 'icon_stone': {'stone': 'stone_light', 'water': 'stone_light'},
 'icon_fish': {'stone': 'water', 'leaf': 'water'}, 'icon_meat': {'wood': 'fruit'},
 'icon_copper': REMAP['copper_vein'], 'icon_gold': REMAP['gold_vein'], 'icon_crystal': REMAP['crystal_teal'],
 'icon_iron': METAL, 'lock': METAL, 'axe': METAL, 'cup': METAL, 'pickaxe': METAL, 'fishing_rod': METAL,
 'spear': METAL, 'ore_pick': METAL, 'sharp_axe': METAL,
 'crystal_pick': {'stone': 'crystal_violet', 'water': 'crystal_violet'},
 'hand': {'wood': 'skin', 'fruit': 'skin'}, 'basket': {'stone': 'wood', 'fruit': 'wood'},
 'keen_eye': {'stone': 'white', 'leaf': 'crystal_teal', 'water': 'crystal_teal'},
 'longer_days': {'wood': 'gold', 'stone': 'gold', 'fruit': 'gold', 'leaf': 'gold'},
 'lumber_sense': {'leaf': 'crystal_teal', 'water': 'crystal_teal'},
 'pointer': {'stone': 'white', 'water': 'white', 'wood': 'white'},
}
WHITE = {'boar', 'icon_fish', 'icon_meat', 'keen_eye', 'sharp_axe', 'pointer', 'spring', 'puddle', 'pond'}

def map_item(name, src, dst):
    remap = CFG.get(name, {})
    im = Image.open(src).convert('RGBA'); w, h = im.size
    rgb = im.convert('RGB'); px = rgb.load(); al = im.load()
    bg = {(x, y) for y in range(h) for x in range(w) if al[x, y][3] < 128} if min(al[x, y][3] for y in range(h) for x in range(w)) < 128 else remove_bg_multi(rgb, 40, ring=1)
    counts = Counter(px[x, y] for y in range(h) for x in range(w) if (x, y) not in bg)
    table, by_mat = {}, {}
    for col, n in counts.items():
        hh, ss, vv = colorsys.rgb_to_hsv(*(c / 255 for c in col))
        m = material(col)
        if name in WHITE and ss < 0.15 and vv > 0.85:
            m = 'white'
        m = remap.get(m, m)
        if m == 'outline':
            table[col] = BLACK
        else:
            by_mat.setdefault(m, []).append((lum(col), col, n))
    for m, cols in by_mat.items():
        ramp, shares = RAMPS[m]
        cols.sort(); total = sum(n for *_, n in cols); acc = 0; bounds = []; a = 0
        for s in shares: a += s; bounds.append(a * total)
        for l, col, n in cols:
            mid = acc + n / 2; acc += n
            table[col] = C[ramp[next(j for j, b in enumerate(bounds) if mid < b or j == len(bounds) - 1)]]
    out = Image.new('RGBA', (w, h), (0, 0, 0, 0)); o = out.load()
    for y in range(h):
        for x in range(w):
            if (x, y) not in bg: o[x, y] = table[px[x, y]] + (255,)
    op = {(x, y) for y in range(h) for x in range(w) if o[x, y][3]}
    comps, seen = [], set()
    for s0 in op:
        if s0 in seen: continue
        comp, st = [], [s0]; seen.add(s0)
        while st:
            x, y = st.pop(); comp.append((x, y))
            for q in ((x+1,y),(x-1,y),(x,y+1),(x,y-1),(x+1,y+1),(x-1,y-1),(x+1,y-1),(x-1,y+1)):
                if q in op and q not in seen: seen.add(q); st.append(q)
        comps.append(comp)
    big = max(len(c) for c in comps)
    for c in comps:
        # drop stray lines/specks, but keep small deliberate details (sparkles, reeds)
        xs = [p[0] for p in c]; ys = [p[1] for p in c]
        thin_line = (max(ys) - min(ys) <= 1 and max(xs) - min(xs) >= w // 3) or (max(xs) - min(xs) <= 1 and max(ys) - min(ys) >= h // 3)
        if thin_line or len(c) < 2:
            for q in c: o[q] = (0, 0, 0, 0)
    out.save(dst)



if __name__ == '__main__':
    map_item(sys.argv[1], sys.argv[2], sys.argv[3])
