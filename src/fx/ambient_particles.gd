class_name AmbientParticles
extends Node2D
## Ambient particles of the current biome (drawn behind the board): one or more
## AmbientEffect layers (fireflies, spores, embers, snow, bubbles…). Blocks of
## whole pixels snapped to the 2 px art grid of the backgrounds; colors change
## in palette steps. Deterministic (fixed seed) so it looks the same every run.

## Positions snap to this grid (one art pixel of the 2x backgrounds).
const GRID := 2.0
## Seconds the end-of-life burst stays on screen.
const POP_TIME := 0.12

## Layers to draw. Setting it restarts the particles.
@export var effects: Array[AmbientEffect] = []:
	set(value):
		effects = value
		_restart()

var _time: float = 0.0
var _rng := RandomNumberGenerator.new()
## One array of particle dictionaries per effect.
var _layers: Array[Array] = []


func _ready() -> void:
	_restart()


func _process(delta: float) -> void:
	_time += delta
	for i: int in _layers.size():
		var effect := effects[i]
		for particle: Dictionary in _layers[i]:
			_step(effect, particle, delta)
	queue_redraw()


func _draw() -> void:
	for i: int in _layers.size():
		var effect := effects[i]
		for particle: Dictionary in _layers[i]:
			match effect.motion:
				AmbientEffect.Motion.WANDER:
					_draw_wander(effect, particle)
				_:
					_draw_life(effect, particle)


func _restart() -> void:
	_rng.seed = 42
	_layers.clear()
	for effect: AmbientEffect in effects:
		var layer: Array[Dictionary] = []
		for i: int in effect.count:
			var particle := {}
			_spawn(effect, particle)
			if effect.motion != AmbientEffect.Motion.WANDER:
				# Start mid-life so the screen is already populated.
				var skip := _rng.randf_range(0.0, particle["life"])
				_step(effect, particle, skip)
			layer.append(particle)
		_layers.append(layer)


func _spawn(effect: AmbientEffect, particle: Dictionary) -> void:
	var area := effect.spawn_area
	particle["pos"] = Vector2(_rng.randf_range(area.position.x, area.end.x),
		_rng.randf_range(area.position.y, area.end.y))
	particle["phase"] = _rng.randf_range(0.0, TAU)
	particle["age"] = 0.0
	particle["life"] = _rng.randf_range(effect.life.x, effect.life.y)
	particle["wait"] = _rng.randf_range(effect.rest.x, effect.rest.y)
	particle["vel"] = Vector2(_rng.randf_range(effect.velocity_min.x, effect.velocity_max.x),
		_rng.randf_range(effect.velocity_min.y, effect.velocity_max.y))
	if effect.motion == AmbientEffect.Motion.WANDER:
		particle["radius"] = Vector2(_rng.randf_range(12, 40), _rng.randf_range(8, 24))
		particle["speed"] = Vector2(_rng.randf_range(0.15, 0.35), _rng.randf_range(0.2, 0.45))
		particle["blink"] = _rng.randf_range(0.4, 0.9)


func _step(effect: AmbientEffect, particle: Dictionary, delta: float) -> void:
	if effect.motion == AmbientEffect.Motion.WANDER:
		return
	if particle["wait"] > 0.0:
		particle["wait"] -= delta
		return
	particle["age"] += delta
	if effect.motion == AmbientEffect.Motion.FLOW:
		particle["vel"] += effect.gravity * delta
		particle["pos"] += (particle["vel"] as Vector2) * delta
	if particle["age"] >= particle["life"] + (POP_TIME if effect.pop else 0.0):
		_spawn(effect, particle)


func _draw_wander(effect: AmbientEffect, particle: Dictionary) -> void:
	var phase: float = particle["phase"]
	var speed: Vector2 = particle["speed"]
	var offset := Vector2(sin(_time * speed.x * TAU + phase), cos(_time * speed.y * TAU + phase * 1.3))
	var pos := (particle["pos"] as Vector2) + offset * (particle["radius"] as Vector2)
	# Blink: 0..1 wave -> palette step (off at the bottom of the wave).
	var wave := 0.5 + 0.5 * sin(_time * (particle["blink"] as float) * TAU + phase)
	var step := int((1.0 - wave) * (effect.colors.size() + 1))
	if step < effect.colors.size():
		_block(pos, effect.block, effect.colors[step])


func _draw_life(effect: AmbientEffect, particle: Dictionary) -> void:
	if particle["wait"] > 0.0:
		return
	var age: float = particle["age"]
	var life: float = particle["life"]
	var pos: Vector2 = particle["pos"]
	if effect.sway != Vector2.ZERO:
		pos.x += sin(age * effect.sway.y * TAU + (particle["phase"] as float)) * effect.sway.x
	if age >= life:
		# Burst: four blocks around the last position (a ring one step wider
		# than RING particles), the center left empty.
		var color := effect.pop_color if effect.pop_color.a > 0.0 else effect.colors[0]
		var reach := 2 if effect.shape == AmbientEffect.Shape.RING else 1
		_ring(pos, effect.block, reach, color)
		return
	var index := mini(int(age / life * effect.colors.size()), effect.colors.size() - 1)
	var color := effect.colors[index]
	if effect.shape == AmbientEffect.Shape.RING:
		_ring(pos, effect.block, 1, color)
		return
	_block(pos, effect.block, color)
	if effect.shape == AmbientEffect.Shape.GLINT and index == effect.colors.size() / 2:
		var b := Vector2(effect.block)
		for dir: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			_block(pos + dir * b, effect.block, effect.colors[maxi(index - 1, 0)])


## Four blocks `reach` blocks away from `pos` (left, right, up, down).
func _ring(pos: Vector2, size: Vector2i, reach: int, color: Color) -> void:
	for dir: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		_block(pos + dir * Vector2(size) * reach, size, color)


func _block(pos: Vector2, size: Vector2i, color: Color) -> void:
	var snapped := (pos / GRID).floor() * GRID
	draw_rect(Rect2(snapped, Vector2(size)), color)
