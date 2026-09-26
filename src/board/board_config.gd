@tool
class_name BoardConfig
extends Resource
## Board layout configuration. Instances live in data/board/*.tres.

## Number of cells (columns x rows).
@export var size: Vector2i = Vector2i(8, 8)
## Cell size in pixels (includes the cell frame).
@export var cell_size: Vector2i = Vector2i(40, 40)
## Expected source sprite size (art is generated/authored at this size).
@export var source_sprite_size: Vector2i = Vector2i(32, 32)


func get_pixel_size() -> Vector2i:
	return size * cell_size
