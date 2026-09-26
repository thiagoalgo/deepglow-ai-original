@tool
class_name BoardGridView
extends Node2D
## Board drawing: framed cells with pixel-rounded corners (PixelStyleBox), palette only.

@export var config: BoardConfig:
	set(value):
		config = value
		queue_redraw()

@export var cell_fill: Color = Palette.SHADOW_DEEP
@export var cell_border: Color = Palette.SHADOW_LIFTED
@export var board_fill: Color = Palette.SHADOW_BLUEBLACK
@export_range(0, 8) var gap: int = 2
@export_range(0, 16) var frame_margin: int = 10


func _draw() -> void:
	if config == null:
		return
	var board_rect := Rect2(Vector2.ZERO, config.get_pixel_size())
	# The frame also covers the concept-art board baked into the background.
	var frame := PixelStyleBox.create(board_fill, cell_border, 2, PackedInt32Array([4, 2]))
	frame.draw(get_canvas_item(), board_rect.grow(frame_margin))
	var cell := PixelStyleBox.create(cell_fill, cell_border, 2, PackedInt32Array([2]))
	for y: int in config.size.y:
		for x: int in config.size.x:
			var origin := Vector2(x * config.cell_size.x, y * config.cell_size.y)
			var rect := Rect2(origin + Vector2(gap, gap), Vector2(config.cell_size) - Vector2(gap * 2, gap * 2))
			cell.draw(get_canvas_item(), rect)
