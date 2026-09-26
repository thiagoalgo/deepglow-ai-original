@tool
class_name NeedBar
extends Control
## Small horizontal bar (hunger/thirst). Value 0..1. Pink when low.

@export_range(0.0, 1.0) var value: float = 1.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()
@export var fill_color: Color = Palette.VEGETATION_NEON_TEAL
@export var low_color: Color = Palette.LIGHT_PINK
@export_range(0.0, 1.0) var low_threshold: float = 0.25


func _init() -> void:
	# Default size only; a size set in the scene (applied before the script) wins.
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(96, 10)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	PixelStyleBox.create(Palette.SHADOW_ABSOLUTE, Palette.SHADOW_LIFTED, 2, PackedInt32Array([2])).draw(get_canvas_item(), rect)
	var inner := rect.grow(-2)
	var color := low_color if value <= low_threshold else fill_color
	var width := floorf(inner.size.x * value)
	if width >= 1.0:
		draw_rect(Rect2(inner.position, Vector2(width, inner.size.y)), color)
