"""Hand-drawn pointer cursor (24x24). Writes assets/sprites/cursors/pointer.png."""
import tempfile
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parents[3] / 'assets' / 'sprites' / 'cursors'
P = {'.': None, 'k': (5, 5, 9), 'w': (217, 245, 242), 'h': (154, 107, 222)}
ARROW = [
 "k............",
 "kk...........",
 "kwk..........",
 "kwwk.........",
 "kwwwk........",
 "kwwwwk.......",
 "kwwwwwk......",
 "kwwwwwhk.....",
 "kwwwwwwhk....",
 "kwwwwwwwhk...",
 "kwwwwwwwwhk..",
 "kwwwwwwwwwhk.",
 "kwwwwwwhkkkkk",
 "kwwwhwwhk....",
 "kwwhkkwwhk...",
 "kwhk.kwwhk...",
 "khk...kwwhk..",
 "kk....kwwhk..",
 "k......kwhk..",
 ".......kkk...",
]
OX, OY = 4, 2   # tip position inside the 24x24 cursor
im = Image.new('RGBA', (24, 24), (0, 0, 0, 0))
for y, row in enumerate(ARROW):
    for x, ch in enumerate(row):
        if P[ch]: im.putpixel((OX + x, OY + y), P[ch] + (255,))
im.save(OUT / 'pointer.png')
bg = Image.new('RGBA', (24, 24), (8, 13, 36, 255)); bg.alpha_composite(im)
bg.resize((240, 240), Image.NEAREST).save(Path(tempfile.gettempdir()) / 'pointer_new.png')
