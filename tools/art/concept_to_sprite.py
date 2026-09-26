"""Concept-art cell -> 32x32 palette sprite.

1. Remove the cell background with a flood fill from the borders.
2. Classify each full-res pixel into a material by hue/saturation.
3. Map luminance onto that material's fixed ramp (percentile shares, top step smallest).
4. Downscale with a per-block majority vote (crisp pixels, no blending).
5. Close the silhouette with a 1 px outline.

Usage: python3 tools/art/concept_to_sprite.py <cell_crop.png> <out.png> [piece_id]
(piece_id selects a material remap from REMAP, e.g. tree_pine).
"""
import colorsys, sys
from collections import Counter, deque
from PIL import Image, ImageFilter

C = {
 'OUT': (42, 33, 71),
 'ST0': (16, 26, 82), 'ST1': (37, 50, 140), 'ST2': (58, 70, 163), 'ST3': (154, 107, 222),
 'WD0': (42, 33, 71), 'WD1': (86, 51, 168), 'WD2': (198, 108, 156),
 'LF0': (14, 48, 54), 'LF1': (25, 93, 80), 'LF2': (116, 232, 92),
 'WA0': (9, 42, 82), 'WA1': (18, 88, 158), 'WA2': (39, 116, 230), 'WA3': (33, 200, 217),
 'FR0': (198, 108, 156), 'FR1': (237, 120, 183), 'FR2': (244, 215, 165),
}
RAMPS = {
 'stone': (['ST0', 'ST1', 'ST2', 'ST3'], [0.22, 0.38, 0.32, 0.08]),
 'wood': (['WD0', 'WD1', 'WD2'], [0.35, 0.45, 0.20]),
 'leaf': (['LF0', 'LF1', 'LF2'], [0.40, 0.48, 0.12]),
 'water': (['WA0', 'WA1', 'WA2', 'WA3'], [0.15, 0.30, 0.35, 0.20]),
 'fruit': (['FR0', 'FR1', 'FR2'], [0.35, 0.55, 0.10]),
}

def material(c):
    h, s, v = colorsys.rgb_to_hsv(*(x / 255 for x in c))
    h *= 360
    if v < 0.13:
        return 'outline'
    if (85 <= h < 188 and s > 0.3) or (188 <= h < 200 and s > 0.5 and v < 0.45):
        return 'leaf'
    if 188 <= h < 235 and s > 0.6 and v > 0.45:
        return 'water'
    if (h >= 320 or h < 12) and s > 0.5 and v > 0.5:
        return 'fruit'
    if h >= 300 or h < 45:
        return 'wood'
    return 'stone'

def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]

def remove_bg(im, tol=34):
    w, h = im.size
    px = im.load()
    bg = set()
    q = deque((x, y) for x in range(w) for y in (0, h - 1)) 
    q.extend((x, y) for y in range(h) for x in (0, w - 1))
    ref = Counter(px[x, y] for x, y in list(q)).most_common(1)[0][0]
    while q:
        p = q.popleft()
        if p in bg:
            continue
        c = px[p]
        if sum(abs(a - b) for a, b in zip(c, ref)) > tol:
            continue
        bg.add(p)
        x, y = p
        for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= n[0] < w and 0 <= n[1] < h and n not in bg:
                q.append(n)
    return bg

def convert(src, out, side=84, size=32, dy=0, remap=None):
    remap = remap or {}
    full = Image.open(src).convert('RGB')
    w, h = full.size
    x0, y0 = (w - side) // 2, (h - side) // 2 + dy
    im = full.crop((x0, y0, x0 + side, y0 + side))
    bg = remove_bg(im)
    px = im.load()
    soft = im.filter(ImageFilter.GaussianBlur(2)).load()
    labels = {}
    for y in range(side):
        for x in range(side):
            if (x, y) not in bg:
                m = material(px[x, y])
                labels[(x, y)] = remap.get(m, m)
    colors = {k: C['OUT'] for k, m in labels.items() if m == 'outline'}
    for mat, (ramp, shares) in RAMPS.items():
        pts = sorted((lum(soft[k]), k) for k, m in labels.items() if m == mat)
        n = len(pts)
        bounds, acc = [], 0.0
        for s in shares:
            acc += s
            bounds.append(acc * n)
        for i, (_, k) in enumerate(pts):
            step = next(j for j, b in enumerate(bounds) if i < b or j == len(bounds) - 1)
            colors[k] = C[ramp[step]]
    s = side / size
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    for oy in range(size):
        for ox in range(size):
            votes = Counter()
            total = 0
            for y in range(int(oy * s), int((oy + 1) * s)):
                for x in range(int(ox * s), int((ox + 1) * s)):
                    total += 1
                    votes[colors.get((x, y))] += 1
            opaque = total - votes.pop(None, 0)
            if opaque * 2 < total or not votes:
                continue
            # Prefer non-outline colors unless the block is mostly outline.
            best, cnt = votes.most_common(1)[0]
            if best == C['OUT'] and len(votes) > 1 and cnt < opaque * 0.6:
                best = votes.most_common(2)[1][0]
            img.putpixel((ox, oy), best + (255,))
    op = {(x, y) for y in range(size) for x in range(size) if img.getpixel((x, y))[3]}
    # Drop tiny islands (frame/texture specks).
    seen = set()
    for start in list(op):
        if start in seen:
            continue
        comp, stack = [], [start]
        seen.add(start)
        while stack:
            x, y = stack.pop(); comp.append((x, y))
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if n in op and n not in seen:
                    seen.add(n); stack.append(n)
        if len(comp) < 6:
            for p in comp:
                img.putpixel(p, (0, 0, 0, 0)); op.discard(p)
    for (x, y) in op:
        for dx, dy2 in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (x + dx, y + dy2)
            if 0 <= q[0] < size and 0 <= q[1] < size and q not in op:
                img.putpixel(q, C['OUT'] + (255,))
    img.save(out)

REMAP = {
    'tree_pine': {'stone': 'leaf'},
    'fruit_tree': {'stone': 'leaf'},
    'spring': {'leaf': 'stone', 'wood': 'stone'},
}

if __name__ == '__main__':
    convert(sys.argv[1], sys.argv[2], remap=REMAP.get(sys.argv[3] if len(sys.argv) > 3 else '', {}))
