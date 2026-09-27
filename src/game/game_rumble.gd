class_name GameRumble
extends Node
## Controller vibration driven by the Events bus: a short light buzz on every
## hit and a stronger one when the hit collects the source. Only when the player
## is using a gamepad (the last button pressed came from one).

@export_group("Hit")
@export_range(0.0, 1.0) var hit_weak: float = 0.35
@export_range(0.0, 1.0) var hit_strong: float = 0.0
@export var hit_duration: float = 0.08
## Weak motor while the hunger bar is empty (weak hits barely buzz).
@export_range(0.0, 1.0) var weak_hit_weak: float = 0.15
@export_group("Collect")
@export_range(0.0, 1.0) var collect_weak: float = 0.5
@export_range(0.0, 1.0) var collect_strong: float = 0.45
@export var collect_duration: float = 0.16

## Gamepad that pressed last, or -1 when the player is on mouse/keyboard.
var _device: int = -1
var _hungry: bool = false


func _ready() -> void:
	Events.source_hit.connect(_on_source_hit)
	Events.needs_changed.connect(_on_needs_changed)


func _exit_tree() -> void:
	if _device >= 0:
		Input.stop_joy_vibration(_device)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.is_pressed():
		_device = event.device
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5:
		_device = event.device
	elif (event is InputEventMouseButton or event is InputEventKey) and event.is_pressed():
		_device = -1


func _on_source_hit(_source: SourceType, _cell: Vector2i, depleted: bool) -> void:
	if _device < 0:
		return
	if depleted:
		Input.start_joy_vibration(_device, collect_weak, collect_strong, collect_duration)
	else:
		Input.start_joy_vibration(_device, weak_hit_weak if _hungry else hit_weak, hit_strong,
			hit_duration)


func _on_needs_changed(hunger: float, _thirst: float) -> void:
	_hungry = hunger <= 0.0
