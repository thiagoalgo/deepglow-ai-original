@tool
class_name NeedBar
extends Control
## Small horizontal bar (hunger/thirst). Value 0..1. Pink when low; when empty
## its frame blinks pink (the empty-bar penalty is active).

@export_range(0.0, 1.0) var value: float = 1.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()
@export var fill_color: Color = Palette.VEGETATION_NEON_TEAL
@export var low_color: Color = Palette.LIGHT_PINK
@export_range(0.0, 1.0) var low_threshold: float = 0.25
## Full blink cycle of the empty bar's frame, in seconds.
@export var blink_period: float = 0.5

var _blink_on: bool = false
var _blink_time: float = 0.0


func _init() -> void:
	# Default size only; a size set in the scene (applied before the script) wins.
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(96, 10)


func _process(delta: float) -> void:
	if value > 0.0 or Engine.is_editor_hint():
		_blink_time = 0.0
		if _blink_on:
			_blink_on = false
			queue_redraw()
		return
	_blink_time += delta
	var on := fmod(_blink_time, blink_period) < blink_period / 2.0
	if on != _blink_on:
		_blink_on = on
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var border := low_color if _blink_on else Palette.SHADOW_LIFTED
	PixelStyleBox.create(Palette.SHADOW_ABSOLUTE, border, 2, PackedInt32Array([2])).draw(get_canvas_item(), rect)
	var inner := rect.grow(-2)
	var color := low_color if value <= low_threshold else fill_color
	var width := floorf(inner.size.x * value)
	if width >= 1.0:
		draw_rect(Rect2(inner.position, Vector2(width, inner.size.y)), color)
