class_name PixelBurst
extends Node2D
## A one-shot burst of square pixel particles (chips, sparkles). Each particle
## steps through `colors` (bright -> dark) as it ages and then disappears:
## no alpha fading, so everything stays inside the palette. Frees itself.

const SIZE := 2

var colors: PackedColorArray = []
var lifetime: float = 0.4
var gravity: float = 420.0

var _positions: PackedVector2Array = []
var _velocities: PackedVector2Array = []
var _ages: PackedFloat32Array = []


## Spawns `count` particles around `at` (parent coordinates) flying upwards/outwards.
## `start_radius` makes them appear already that far from the centre (so they
## are not hidden under the cursor).
static func spawn(parent: Node, at: Vector2, p_colors: PackedColorArray, count: int,
		speed: float = 90.0, p_gravity: float = 420.0, p_lifetime: float = 0.4,
		spread: float = PI * 0.8, start_radius: float = 0.0) -> PixelBurst:
	var burst := PixelBurst.new()
	burst.colors = p_colors
	burst.gravity = p_gravity
	burst.lifetime = p_lifetime
	burst.position = at.floor()
	for i: int in count:
		var angle := -PI / 2.0 + randf_range(-spread, spread)
		var direction := Vector2.from_angle(angle)
		burst._positions.append(direction * start_radius * randf_range(0.8, 1.2))
		burst._velocities.append(direction * speed * randf_range(0.6, 1.0))
		# Staggered ages so the particles don't all change color in the same frame.
		burst._ages.append(randf_range(0.0, p_lifetime * 0.25))
	parent.add_child(burst)
	return burst


func _process(delta: float) -> void:
	var alive := false
	for i: int in _positions.size():
		_ages[i] += delta
		if _ages[i] >= lifetime:
			continue
		alive = true
		_velocities[i].y += gravity * delta
		_positions[i] += _velocities[i] * delta
	if not alive:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if colors.is_empty():
		return
	for i: int in _positions.size():
		if _ages[i] >= lifetime:
			continue
		var step := mini(int(_ages[i] / lifetime * colors.size()), colors.size() - 1)
		draw_rect(Rect2(_positions[i].floor(), Vector2(SIZE, SIZE)), colors[step])
