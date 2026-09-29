class_name GameAudio
extends Node
## Game sounds driven by the Events bus: music per state (phase track with a
## "rush" layer near the end, calm track between phases), board hits (the
## tool's hit_sound), collection, the last-seconds countdown and purchases.

@export var phase_music: AudioStream
@export var camp_music: AudioStream
@export var collect_sound: AudioStream
@export var phase_start_sound: AudioStream
@export var phase_end_sound: AudioStream
@export var tick_sound: AudioStream
@export var tick_last_sound: AudioStream
@export var buy_sound: AudioStream
## Seconds left when the rush layer fades in.
@export var rush_time: float = 10.0
## Countdown ticks during the last N seconds.
@export var countdown_seconds: int = 5

## Hit sounds play lower while the hunger bar is empty (weak hits).
@export var weak_hit_pitch: float = 0.8
## Each hit plays the same sound on one of these pitches (semitones from the
## original, never the same one twice in a row): "po, pa, pum" instead of a
## machine-gun of identical clicks.
@export var hit_pitch_steps: Array[int] = [-3, 0, 2]

var _last_second: int = -1
var _hungry: bool = false
var _last_hit_step: int = -1


func _ready() -> void:
	Events.phase_started.connect(_on_phase_started)
	Events.phase_time_changed.connect(_on_phase_time_changed)
	Events.phase_ended.connect(_on_phase_ended)
	Events.source_hit.connect(_on_source_hit)
	Events.source_collected.connect(_on_source_collected)
	Events.needs_changed.connect(_on_needs_changed)
	Sound.play_music(camp_music)


## Called by Game when an upgrade is bought.
func play_purchase() -> void:
	Sound.play(buy_sound)


func _on_phase_started(_phase_number: int, _duration: float) -> void:
	_last_second = -1
	Sound.play(phase_start_sound)
	Sound.play_music(phase_music)


func _on_phase_time_changed(time_left: float) -> void:
	Sound.set_rush(time_left <= rush_time)
	var second := ceili(time_left)
	if second != _last_second and second >= 1 and second <= countdown_seconds:
		Sound.play(tick_last_sound if second == 1 else tick_sound)
	_last_second = second


func _on_phase_ended(_phase_number: int) -> void:
	Sound.play(phase_end_sound)
	Sound.play_music(camp_music)


func _on_source_hit(source: SourceType, _cell: Vector2i, depleted: bool) -> void:
	if depleted and source.collect_sound:
		Sound.play(source.collect_sound, 0.05)
		return
	var pitch := _next_hit_pitch() * (weak_hit_pitch if _hungry else 1.0)
	Sound.play(source.hit_sound if source.hit_sound else source.tool.hit_sound, 0.0, 0.0, pitch)


## Picks a pitch step different from the previous hit's.
func _next_hit_pitch() -> float:
	if hit_pitch_steps.is_empty():
		return 1.0
	var index := randi() % hit_pitch_steps.size()
	if hit_pitch_steps.size() > 1 and index == _last_hit_step:
		index = (index + 1 + randi() % (hit_pitch_steps.size() - 1)) % hit_pitch_steps.size()
	_last_hit_step = index
	return pow(2.0, hit_pitch_steps[index] / 12.0)


func _on_source_collected(source: SourceType, _amount: int, _cell: Vector2i) -> void:
	var rare := source.rarity != null and not source.rarity.is_baseline
	Sound.play(collect_sound, 0.02, 0.0, 1.12 if rare else 1.0)


func _on_needs_changed(hunger: float, _thirst: float) -> void:
	_hungry = hunger <= 0.0
