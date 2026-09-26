#!/usr/bin/env python3
"""Convert the icon/tool/extra-source items of concept-art-2.png and concept-art-3.png.

Each item is a crop box in its concept image (1672x941 for concept 2, 1920x1080 for concept 3)
plus the conversion settings used by concept_to_sprite.convert_object (material ramps, lit from
the top-left). Outputs go straight to assets/sprites/<category>/<id>.png.

Usage:
  python3 tools/art/concept_panel_items.py <concept-art-2.png> <concept-art-3.png> [out_root] [id ...]
"""
from __future__ import annotations

import os
import sys
import tempfile
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from concept_to_sprite import REMAP, convert_object  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
METAL = {'stone': 'metal', 'water': 'metal'}
DROP_BG = {'stone': 'drop', 'water': 'drop', 'leaf': 'drop', 'wood': 'drop', 'fruit': 'drop', 'outline': 'drop'}

# id: (concept 2|3, box, category, size, extent, inset, remap, white)
ITEMS: dict[str, tuple] = {
    # Board sources (32x32).
    'puddle': (2, (622, 267, 729, 369), 'sources', 32, 28, 8, {}, False),
    'pond': (2, (837, 478, 944, 574), 'sources', 32, 30, 5, {}, False),
    'boar': (2, (944, 472, 1051, 574), 'sources', 32, 30, 8, {'stone': 'wood', 'fruit': 'wood'}, True),
    # HUD resource icons (16x16).
    'wood': (3, (290, 305, 407, 398), 'icons', 16, 15, 8, {}, False),
    'fruit': (3, (165, 118, 282, 212), 'icons', 16, 14, 8, {}, False),
    'water': (2, (148, 105, 213, 167), 'icons', 16, 14, 6, {'stone': 'water'}, False),
    'stone': (3, (165, 398, 282, 492), 'icons', 16, 14, 8, {'stone': 'stone_light', 'water': 'stone_light'}, False),
    'fish': (2, (148, 170, 213, 232), 'icons', 16, 15, 6, {'stone': 'water', 'leaf': 'water'}, True),
    'meat': (2, (148, 235, 213, 297), 'icons', 16, 15, 6, {'wood': 'fruit'}, True),
    'copper': (2, (944, 164, 1051, 267), 'icons', 16, 15, 8, REMAP['copper_vein'], False),
    'iron': (2, (148, 300, 213, 362), 'icons', 16, 15, 6, METAL, False),
    'gold': (2, (1051, 164, 1158, 267), 'icons', 16, 15, 8, REMAP['gold_vein'], False),
    'crystal': (3, (290, 398, 407, 492), 'icons', 16, 15, 8, REMAP['crystal_teal'], False),
    # Cursors (24x24; hotspots live in data/tools/*.tres and tool_cursor.tscn).
    'pointer': (2, (148, 398, 240, 484), 'cursors', 24, 20, 14, DROP_BG, True),
    'lock': (2, (254, 398, 346, 484), 'cursors', 24, 20, 8, METAL, False),
    'axe': (2, (148, 486, 240, 572), 'cursors', 24, 22, 8, METAL, False),
    'hand': (2, (254, 486, 346, 572), 'cursors', 24, 22, 8, {'wood': 'skin', 'fruit': 'skin'}, False),
    'cup': (2, (148, 574, 240, 660), 'cursors', 24, 20, 8, METAL, False),
    'pickaxe': (2, (254, 574, 346, 660), 'cursors', 24, 22, 8, METAL, False),
    'fishing_rod': (2, (148, 662, 240, 748), 'cursors', 24, 22, 8, METAL, False),
    'spear': (2, (254, 662, 346, 748), 'cursors', 24, 22, 8, METAL, False),
    'ore_pick': (2, (148, 750, 240, 836), 'cursors', 24, 22, 8, METAL, False),
    'crystal_pick': (2, (254, 750, 346, 836), 'cursors', 24, 22, 8,
                     {'stone': 'crystal_violet', 'water': 'crystal_violet'}, False),
    # Upgrade tree icons (20x20).
    'basket': (2, (1312, 122, 1420, 232), 'upgrades', 20, 19, 10, {'stone': 'wood', 'fruit': 'wood'}, False),
    'canteen': (2, (1428, 122, 1536, 232), 'upgrades', 20, 19, 10, {}, False),
    'keen_eye': (2, (1312, 240, 1420, 350), 'upgrades', 20, 18, 10,
                 {'stone': 'white', 'leaf': 'crystal_teal', 'water': 'crystal_teal'}, True),
    'longer_days': (2, (1428, 240, 1536, 350), 'upgrades', 20, 18, 10,
                    {'wood': 'gold', 'stone': 'gold', 'fruit': 'gold', 'leaf': 'gold'}, False),
    'lumber_sense': (2, (1312, 358, 1420, 468), 'upgrades', 20, 18, 10,
                     {'leaf': 'crystal_teal', 'water': 'crystal_teal'}, False),
    'sharp_axe': (2, (1428, 358, 1536, 468), 'upgrades', 20, 18, 10, METAL, False),
}


# Stronger luminance smoothing for textured items (fewer, cleaner shading bands).
SOFTEN = {'basket': 5.0, 'canteen': 5.0}


def main() -> None:
    concepts = {2: Image.open(sys.argv[1]).convert('RGB'), 3: Image.open(sys.argv[2]).convert('RGB')}
    out_root = Path(sys.argv[3]) if len(sys.argv) > 3 else ROOT / 'assets' / 'sprites'
    wanted = sys.argv[4:] or list(ITEMS)
    with tempfile.TemporaryDirectory() as tmp:
        crop = os.path.join(tmp, 'crop.png')
        for item_id in wanted:
            source, box, category, size, extent, inset, remap, white = ITEMS[item_id]
            concepts[source].crop(box).save(crop)
            out = out_root / category / f'{item_id}.png'
            out.parent.mkdir(parents=True, exist_ok=True)
            convert_object(crop, str(out), size, extent, inset, remap, white, soften=SOFTEN.get(item_id, 1.5))
            print(out)


if __name__ == '__main__':
    main()
