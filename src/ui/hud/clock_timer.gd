@tool
class_name ClockTimer
extends Control
## Round pixel-art clock for the phase timer. The face starts full and is
## "erased" clockwise from 12 o'clock as time runs out. Drawn pixel by pixel
## (grouped into horizontal runs), so it stays crisp and palette-only.

@export_range(4, 64) var radius: int = 16:
	set(v):
		radius = v
		custom_minimum_size = Vector2(radius * 2, radius * 2)
		queue_redraw()
## Remaining fraction of the phase, 1 = full, 0 = time is up.
@export_range(0.0, 1.0) var value: float = 1.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()
@export var fill_color: Color = Palette.VEGETATION_NEON_TEAL
@export var low_color: Color = Palette.LIGHT_PINK
@export var empty_color: Color = Palette.SHADOW_LIFTED
@export var rim_color: Color = Palette.STRUCTURE_INDIGO
@export var outline_color: Color = Palette.SHADOW_ABSOLUTE
## Switches the face to low_color (set by the HUD when little time is left).
@export var alert: bool = false:
	set(v):
		alert = v
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(radius * 2, radius * 2)


func _draw() -> void:
	var fill := low_color if alert else fill_color
	var elapsed := 1.0 - value
	var r := float(radius)
	for y: int in radius * 2:
		var run_color := Color.TRANSPARENT
		var run_start := 0
		for x: int in radius * 2 + 1:
			var color := Color.TRANSPARENT
			if x < radius * 2:
				color = _pixel_color(x, y, r, elapsed, fill)
			if color != run_color:
				if run_color.a > 0.0:
					draw_rect(Rect2(run_start, y, x - run_start, 1), run_color)
				run_color = color
				run_start = x


func _pixel_color(x: int, y: int, r: float, elapsed: float, fill: Color) -> Color:
	# Pixel centre relative to the clock centre.
	var dx := x + 0.5 - r
	var dy := y + 0.5 - r
	var dist := sqrt(dx * dx + dy * dy)
	if dist > r:
		return Color.TRANSPARENT
	if dist > r - 1.5:
		return outline_color
	if dist > r - 3.5:
		return rim_color
	if dist < 1.5:
		return outline_color  # centre pin
	# Angle from 12 o'clock, clockwise, as a 0..1 fraction of a turn.
	var turn := fposmod(atan2(dx, -dy) / TAU, 1.0)
	return empty_color if turn < elapsed else fill
