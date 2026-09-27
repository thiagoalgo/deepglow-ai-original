class_name Fireflies
extends Node2D
## Ambient fireflies drifting over the scene (drawn behind the board).
## Whole 2x2 blocks at integer positions; blinking steps through palette
## colors instead of fading. Positions follow smooth Lissajous paths.

const SIZE := 2
const COLORS: Array[Color] = [
	Palette.LIGHT_SULFUR_YELLOW, Palette.VEGETATION_GLOW_GREEN, Palette.VEGETATION_MOSS,
]

@export var count: int = 14
@export var area: Rect2 = Rect2(0, 0, 640, 360)

var _time: float = 0.0
var _flies: Array[Dictionary] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i: int in count:
		_flies.append({
			"base": Vector2(rng.randf_range(area.position.x, area.end.x),
				rng.randf_range(area.position.y + area.size.y * 0.25, area.end.y)),
			"radius": Vector2(rng.randf_range(12, 40), rng.randf_range(8, 24)),
			"speed": Vector2(rng.randf_range(0.15, 0.35), rng.randf_range(0.2, 0.45)),
			"phase": rng.randf_range(0.0, TAU),
			"blink": rng.randf_range(0.4, 0.9),
		})


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	for fly: Dictionary in _flies:
		var phase: float = fly["phase"]
		var speed: Vector2 = fly["speed"]
		var radius: Vector2 = fly["radius"]
		var offset := Vector2(sin(_time * speed.x * TAU + phase), cos(_time * speed.y * TAU + phase * 1.3))
		var pos := ((fly["base"] as Vector2) + offset * radius).floor()
		# Blink: 0..1 wave -> palette step (off at the bottom of the wave).
		var wave := 0.5 + 0.5 * sin(_time * (fly["blink"] as float) * TAU + phase)
		var step := int((1.0 - wave) * (COLORS.size() + 1))
		if step >= COLORS.size():
			continue
		draw_rect(Rect2(pos, Vector2(SIZE, SIZE)), COLORS[step])
