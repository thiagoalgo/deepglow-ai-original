@tool
class_name BoardGridView
extends Node2D
## Placeholder board drawing (framed cells) using the palette.
## To be replaced/complemented by a TileMapLayer with Pixellab art.

@export var config: BoardConfig:
	set(value):
		config = value
		queue_redraw()

@export var cell_fill: Color = Palette.SHADOW_DEEP
@export var cell_border: Color = Palette.SHADOW_LIFTED
@export var board_fill: Color = Palette.SHADOW_BLUEBLACK
@export_range(0, 8) var gap: int = 2


func _draw() -> void:
	if config == null:
		return
	var board_rect := Rect2(Vector2.ZERO, config.get_pixel_size())
	draw_rect(board_rect.grow(6), board_fill)
	draw_rect(board_rect.grow(5), cell_border, false, 2.0)
	for y: int in config.size.y:
		for x: int in config.size.x:
			var origin := Vector2(x * config.cell_size.x, y * config.cell_size.y)
			var rect := Rect2(origin + Vector2(gap, gap), Vector2(config.cell_size) - Vector2(gap * 2, gap * 2))
			draw_rect(rect, cell_fill)
			draw_rect(rect.grow(-1), cell_border, false, 2.0)
