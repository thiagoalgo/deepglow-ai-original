class_name BoardGround
extends Resource
## Look of the board cells in one biome (like a tile of ground under each
## source): flat fill, a 1 px bevel lit from the top-left, and small grass
## tufts / specks scattered per cell. Palette colors only.

## Cell fill.
@export var fill: Color = Palette.VEGETATION_SHADOW
## Top and left inner edge (lit side).
@export var light_edge: Color = Palette.VEGETATION_MOSS
## Bottom and right inner edge (shadow side).
@export var dark_edge: Color = Palette.SHADOW_DEEP
## Outer 1 px outline of each cell.
@export var outline: Color = Palette.SHADOW_BLUEBLACK
## Tufts drawn in every cell (grass, pebbles, ash…).
@export var tuft: Color = Palette.VEGETATION_MOSS
## How many tufts per cell (random between x and y).
@export var tufts: Vector2i = Vector2i(4, 7)
## Soft shadow under each source (lit from the top-left, so it falls down-right).
@export var shadow: Color = Palette.SHADOW_DEEP
## Rare accent specks (glowing moss, crystals, embers, snow). Transparent = none.
@export var accent: Color = Color.TRANSPARENT
## Chance of one accent speck per cell.
@export_range(0.0, 1.0) var accent_chance: float = 0.3
