"""Hand-drawn hand cursor (24x24). Writes assets/sprites/cursors/hand.png."""
import tempfile
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parents[3] / 'assets' / 'sprites' / 'cursors'
K = (5, 5, 9); L = (244, 215, 165); M = (198, 108, 156); D = (86, 51, 168)
W, H = 24, 24
fill = {}
def rect(x0, y0, x1, y1):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            fill[(x, y)] = True
# fingers (2 px wide each, 1 px gap for the outline between them)
rect(6, 4, 7, 12)    # index
rect(9, 2, 10, 12)   # middle
rect(12, 3, 13, 12)  # ring
rect(15, 5, 16, 12)  # pinky
# palm
rect(6, 12, 16, 18)
rect(7, 19, 15, 20)
# thumb, angled out to the left
for (x, y) in [(2, 8), (3, 8), (2, 9), (3, 9), (3, 10), (4, 10), (3, 11), (4, 11), (5, 11), (4, 12), (5, 12), (4, 13), (5, 13), (5, 14), (5, 15)]:
    fill[(x, y)] = True
img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
for (x, y) in fill:
    # light from the top-left: left column of each shape light, right column/bottom mid, deepest shadow bottom-right
    right_edge = (x + 1, y) not in fill
    bottom_edge = (x, y + 1) not in fill
    c = L
    if right_edge or bottom_edge: c = M
    if right_edge and bottom_edge: c = D
    img.putpixel((x, y), c + (255,))
# knuckle creases: short mid-tone lines at the base of the fingers
for x in (7, 10, 13, 16):
    if (x, 12) in fill: img.putpixel((x, 12), M + (255,))
# 1 px black outline around the whole silhouette (4-neighbourhood)
for y in range(H):
    for x in range(W):
        if (x, y) in fill: continue
        if any((x + dx, y + dy) in fill for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            img.putpixel((x, y), K + (255,))
img.save(OUT / 'hand.png')
bg = Image.new('RGBA', (W, H), (8, 13, 36, 255)); bg.alpha_composite(img)
bg.resize((240, 240), Image.NEAREST).save(Path(tempfile.gettempdir()) / 'hand_new.png')
