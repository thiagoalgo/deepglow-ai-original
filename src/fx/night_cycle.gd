class_name NightCycle
extends Node
## Dusk -> deep night during each phase (GDD D4). The scenery (a CanvasItem
## using night_shift.gdshader) darkens in whole palette steps at fixed points
## of the phase, each change being a short pixel dissolve. The board itself never
## darkens (readability). Resets when a phase starts.

## Fraction of the phase elapsed at which each night level begins.
@export var level_starts: PackedFloat32Array = [0.4, 0.75]
@export var transition_time: float = 2.0
@export var scenery: CanvasItem


var _level: int = 0
var _duration: float = 1.0
var _tween: Tween


func _ready() -> void:
	_setup_shader()
	Events.phase_started.connect(_on_phase_started)
	Events.phase_time_changed.connect(_on_phase_time_changed)


func _setup_shader() -> void:
	PaletteShift.setup(scenery.material as ShaderMaterial)


func _on_phase_started(_phase_number: int, duration: float) -> void:
	_duration = maxf(duration, 0.01)
	_set_level(0, false)


func _on_phase_time_changed(time_left: float) -> void:
	var elapsed := 1.0 - time_left / _duration
	var target := 0
	for start: float in level_starts:
		if elapsed >= start:
			target += 1
	if target != _level:
		_set_level(target, true)


func _set_level(level: int, animate: bool) -> void:
	_level = level
	var material := scenery.material as ShaderMaterial
	if _tween:
		_tween.kill()
	if not animate:
		material.set_shader_parameter(&"level", float(level))
		return
	_tween = create_tween()
	_tween.tween_method(func(v: float) -> void: material.set_shader_parameter(&"level", v),
		material.get_shader_parameter(&"level"), float(level), transition_time)
