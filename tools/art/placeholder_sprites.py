#!/usr/bin/env python3
"""Generate temporary programmer-art sprites (palette colors only).

These are placeholders until the final Pixellab art (roadmap M4). Each sprite is an
ASCII map; every character is a palette color (see PALETTE). Outputs go to
assets/sprites/{sources,cursors,icons,upgrades}/. Re-run after editing a map:

  python3 tools/art/placeholder_sprites.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "sprites"

PALETTE = {
    ".": None,
    "k": (5, 5, 9),         # Shadow Absolute
    "o": (42, 33, 71),      # Character Outline
    "i": (37, 50, 140),     # Structure Indigo
    "x": (58, 70, 163),     # Structure Mid Blue
    "v": (86, 51, 168),     # Structure Violet
    "h": (154, 107, 222),   # Structure Highlight
    "s": (14, 48, 54),      # Vegetation Shadow
    "m": (25, 93, 80),      # Vegetation Moss
    "t": (55, 242, 194),    # Vegetation Neon Teal
    "g": (116, 232, 92),    # Vegetation Glow Green
    "d": (18, 88, 158),     # Water Midtone
    "e": (39, 116, 230),    # Water Electric Blue
    "c": (33, 200, 217),    # Water Cyan
    "y": (241, 237, 101),   # Light Sulfur Yellow
    "a": (246, 168, 74),    # Light Amber
    "r": (237, 120, 183),   # Light Pink
    "w": (217, 245, 242),   # Light Blue White
    "p": (198, 108, 156),   # Character Midtone
    "l": (244, 215, 165),   # Character Highlight
}

SPRITES: dict[str, list[str]] = {
    # --- sources (16x16) ---
    "sources/tree_pine": [
        ".......oo.......",
        "......omto......",
        ".....ommmto.....",
        "......ommo......",
        ".....ommmto.....",
        "....ommmmmto....",
        ".....ommmmo.....",
        "....ommmmmto....",
        "...ommmmmmmto...",
        "..ommmmmmmmmto..",
        "...ossmmmmsso...",
        ".....ooaaoo.....",
        ".......ao.......",
        ".......ao.......",
        "......oaao......",
        "................",
    ],
    "sources/tree_oak": [
        ".....oooooo.....",
        "...oommmmmmoo...",
        "..ommmtmmmmmmo..",
        ".ommtmmmmmtmmmo.",
        ".ommmmmmmmmmmmo.",
        "ommmmmtmmmmmmmmo",
        "ommmmmmmmmmtmmmo",
        ".osmmmmmmmmmmso.",
        ".ossmmmmmmmmsso.",
        "..ossssmmsssso..",
        "...oooaaaaooo...",
        "......oaao......",
        "......oaao......",
        ".....oaaaao.....",
        "....oaoooaao....",
        "................",
    ],
    "sources/tree_glow": [
        ".....oooooo.....",
        "...ootttcttoo...",
        "..ottwttttcwto..",
        ".otctttwtttttco.",
        ".ottttcttttwtto.",
        "ottwttttttcttwto",
        "otttttcwttttttto",
        ".omttttttttwtmo.",
        ".ommtttcttttmmo.",
        "..ommmmttmmmmo..",
        "...ooovhhvooo...",
        "......ohvo......",
        "......ohvo......",
        ".....ohhvvo.....",
        "....ohoooovo....",
        "................",
    ],
    "sources/berry_bush": [
        "................",
        "................",
        "................",
        "................",
        "................",
        "......oooo......",
        "....oommmmoo....",
        "...ommrmmmmro...",
        "..ommmmmrmmmmo..",
        "..omrmmmmmmrmo..",
        ".ommmmrmmmmmmmo.",
        ".osmmmmmmrmmmso.",
        "..ossmmmmmmsso..",
        "...ooosssooo....",
        "................",
        "................",
    ],
    "sources/fruit_tree": [
        ".....oooooo.....",
        "...oommmmmmoo...",
        "..ommmymmmmrmo..",
        ".ommmmmmmmmmmmo.",
        ".omrmmmmymmmmmo.",
        "ommmmmmmmmmmrmmo",
        "ommmymmmrmmmmmmo",
        ".osmmmmmmmmymso.",
        ".ossmrmmmmmmsso.",
        "..ossssmmsssso..",
        "...oooaaaaooo...",
        "......oaao......",
        "......oaao......",
        ".....oaaaao.....",
        "....oaoooaao....",
        "................",
    ],
    "sources/puddle": [
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        ".....oooooo.....",
        "...oodddddddo...",
        "..odeecdddeedo..",
        ".odeddddcwddedo.",
        ".odddeedddddddo.",
        "..oddddddeeddo..",
        "...ooddddddoo...",
        ".....oooooo.....",
        "................",
    ],
    "sources/spring": [
        "................",
        ".......w........",
        "......wcw.......",
        ".....c.c.c......",
        "....c..c..c.....",
        "...e...c...e....",
        "..ooo..e..ooo...",
        ".oxxxo.e.oxxxo..",
        ".oxixxoooxxixo..",
        "oxiiioddddoiixo.",
        "oxiodceecdeoixo.",
        ".ooddddcwddddoo.",
        ".odeeddddddeedo.",
        "..oodddeedddoo..",
        "....oooooooo....",
        "................",
    ],
    # --- cursors (12x12) ---
    "cursors/pointer": [
        "o...........",
        "oo..........",
        "owo.........",
        "owwo........",
        "owwwo.......",
        "owwwwo......",
        "owwwwwo.....",
        "owwwwwwo....",
        "owwwooooo...",
        "owoowo......",
        "oo..owo.....",
        ".....oo.....",
    ],
    "cursors/axe": [
        "....oooo....",
        "...owwwxo...",
        "..owwwxxo...",
        "..owwxxooo..",
        "...oxxoaao..",
        "....oooaao..",
        "......oaao..",
        ".....oaao...",
        "....oaao....",
        "...oaao.....",
        "..oaao......",
        "..ooo.......",
    ],
    "cursors/hand": [
        "....oo......",
        "...olo......",
        "...olo.oo...",
        "...oloolo.o.",
        "...ololoolo.",
        ".o.olllllo..",
        "olooollllo..",
        "ollollllllo.",
        ".ollllllllo.",
        "..olllllllo.",
        "...ollllo...",
        "....oooo....",
    ],
    "cursors/cup": [
        "............",
        "..........c.",
        ".oooooooo.c.",
        ".owwwwwwoc..",
        ".occccccoo..",
        ".oeeeeeeo...",
        ".oeceeeeoo..",
        ".oeeeeeeoxo.",
        ".oeeeeceoxo.",
        ".oeeeeeeoo..",
        "..oeeeeo....",
        "...oooo.....",
    ],
    "cursors/lock": [
        "............",
        "....oooo....",
        "...oxooxo...",
        "...ox..xo...",
        "...ox..xo...",
        "..oooooooo..",
        "..oyyyyyyo..",
        "..oyyooyyo..",
        "..oyyooyyo..",
        "..oyyyyyyo..",
        "..oooooooo..",
        "............",
    ],
    # --- icons (8x8) ---
    "icons/wood": [
        "........",
        "..oooooo",
        ".oaaaaal",
        "oaoaaaol",
        "oaaoaaal",
        ".oaaaaol",
        "..oooooo",
        "........",
    ],
    "icons/fruit": [
        "....o...",
        "...om...",
        "..oooo..",
        ".orrwro.",
        ".orrrro.",
        ".orrrro.",
        "..oooo..",
        "........",
    ],
    "icons/water": [
        "...oo...",
        "...oo...",
        "..occo..",
        ".oecwco.",
        ".oeecco.",
        ".odeeeo.",
        "..oooo..",
        "........",
    ],
    # --- M3 sources (16x16) ---
    "sources/rock_small": [
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "......oooo......",
        "....ooxxxhoo....",
        "...oxxxxxxhxo...",
        "..oixxxxxxxxxo..",
        "..oiixxxxxxxxo..",
        "..oiiixxxxxxio..",
        "...oiiiiiiiio...",
        "....oooooooo....",
        "................",
        "................",
    ],
    "sources/rock_large": [
        "................",
        "................",
        "......ooooo.....",
        "....ooxxxxhoo...",
        "...oxxxxxxxxho..",
        "..oxxxxxxxxxxxo.",
        "..oixxxxxxxxxxo.",
        ".oiixxxxoxxxxxxo",
        ".oiixxxoxxxxxxxo",
        ".oiiixxxxxxxxxio",
        ".oiiiixxxxxxxiio",
        "..oiiiiixxxiiio.",
        "..oiiiiiiiiiiio.",
        "...oooooooooooo.",
        "................",
        "................",
    ],
    "sources/pond": [
        "................",
        "................",
        "................",
        "....oooooooo....",
        "..oosdddddddsoo.",
        ".osddeeddddeedso",
        ".odeeddddddddddo",
        "osdddddpddddeedo",
        "odddddpppdddddso",
        "odeedddpddddddso",
        ".odddddddddeedo.",
        ".osdeeddddddddo.",
        "..oosdddddddsoo.",
        "....oooooooo....",
        "................",
        "................",
    ],
    "sources/boar": [
        "................",
        "................",
        "................",
        "................",
        "....ooooooo.....",
        "...opppppppoo...",
        "..oppppppppppoo.",
        ".opppppppppppwko",
        ".oppppppppppppko",
        "oppppppppppppplo",
        "opppppppppppplo.",
        ".opppppppppppo..",
        "..opo.opo.opo...",
        "..oko.oko.oko...",
        "................",
        "................",
    ],
    # --- M3 cursors (12x12) ---
    "cursors/pickaxe": [
        "..oooooo....",
        ".owwwwwwoo..",
        "owoooaaowwo.",
        "oo..oaao.oo.",
        "....oaao....",
        "...oaao.....",
        "...oaao.....",
        "..oaao......",
        "..oaao......",
        ".oaao.......",
        ".oao........",
        ".oo.........",
    ],
    "cursors/fishing_rod": [
        "..........oo",
        ".........oao",
        "........oao.",
        ".......oao.w",
        "......oao..w",
        ".....oao...w",
        "....oao....w",
        "...oao.....w",
        "..oao.....oc",
        ".oao......oc",
        "oao........o",
        "oo..........",
    ],
    "cursors/spear": [
        ".........oo.",
        "........owwo",
        ".......owwwo",
        "......owwwo.",
        ".....oaoo...",
        "....oao.....",
        "...oao......",
        "..oao.......",
        ".oao........",
        "oao.........",
        "oo..........",
        "............",
    ],
    # --- M3 icons (8x8) ---
    "icons/stone": [
        "........",
        "..oooo..",
        ".oxxxho.",
        "oixxxxxo",
        "oiixxxxo",
        "oiiiiiio",
        ".oooooo.",
        "........",
    ],
    "icons/fish": [
        "........",
        "...ooo..",
        "..oeeeo.",
        "ooewceeo",
        "oeeeeeko",
        "ooeeeeo.",
        "..ooo...",
        "........",
    ],
    "icons/meat": [
        "..oooo..",
        ".oppppo.",
        "opprppo.",
        "opppppo.",
        ".oppoo..",
        "..owwo..",
        "..owwo..",
        "..oo.oo.",
    ],
    # --- upgrade icons (10x10) ---
    "upgrades/sharp_axe": [
        "...oooo...",
        "..owwwxo..",
        "..owwxxo..",
        "...oxxoao.",
        "....ooao..",
        ".....oao..",
        "....oao...",
        "...oao....",
        "..oao.....",
        "..oo......",
    ],
    "upgrades/basket": [
        "..........",
        "...oooo...",
        "..o....o..",
        ".orrorroo.",
        ".oaaaaaao.",
        ".oaoaoaoo.",
        ".oaaaaaao.",
        "..oaoaoo..",
        "...oooo...",
        "..........",
    ],
    "upgrades/canteen": [
        "....oo....",
        "...oxxo...",
        "..oooooo..",
        ".oxxxxxxo.",
        ".oxccccxo.",
        ".oxcwccxo.",
        ".oxccccxo.",
        ".oxxxxxxo.",
        "..oooooo..",
        "..........",
    ],
    "upgrades/lumber_sense": [
        "..........",
        ".oooooooo.",
        "oaaaaaaalo",
        "oaoaaaoalo",
        "oaaoaaaalo",
        ".oooooooo.",
        "...oyo....",
        "..oyyyo...",
        "...oyo....",
        "..........",
    ],
    "upgrades/longer_days": [
        "....yy....",
        ".y..yy..y.",
        "..yoooay..",
        "..oyyyyo..",
        "yyoyyyyoyy",
        "yyoyyyyoyy",
        "..oyyyyo..",
        "..yooooy..",
        ".y..yy..y.",
        "....yy....",
    ],
    "upgrades/keen_eye": [
        "..........",
        "...oooo...",
        "..owwwwo..",
        ".owwttwwo.",
        "owwtkktwwo",
        "owwtkktwwo",
        ".owwttwwo.",
        "..owwwwo..",
        "...oooo...",
        "..........",
    ],
}


def render(rows: list[str]) -> Image.Image:
    width = max(len(r) for r in rows)
    img = Image.new("RGBA", (width, len(rows)), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row.ljust(width, ".")):
            rgb = PALETTE[ch]
            if rgb is not None:
                img.putpixel((x, y), rgb + (255,))
    return img


def main() -> None:
    for name, rows in SPRITES.items():
        lengths = {len(r) for r in rows}
        assert len(lengths) == 1, f"{name}: uneven rows {lengths}"
        path = OUT / f"{name}.png"
        path.parent.mkdir(parents=True, exist_ok=True)
        render(rows).save(path)
        print(f"{path.relative_to(ROOT)}  {len(rows[0])}x{len(rows)}")


if __name__ == "__main__":
    main()
