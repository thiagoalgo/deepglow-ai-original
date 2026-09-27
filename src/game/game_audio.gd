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

var _last_second: int = -1


func _ready() -> void:
	Events.phase_started.connect(_on_phase_started)
	Events.phase_time_changed.connect(_on_phase_time_changed)
	Events.phase_ended.connect(_on_phase_ended)
	Events.source_hit.connect(_on_source_hit)
	Events.source_collected.connect(_on_source_collected)
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


func _on_source_hit(source: SourceType, _cell: Vector2i) -> void:
	Sound.play(source.tool.hit_sound, 0.08)


func _on_source_collected(source: SourceType, _amount: int, _cell: Vector2i) -> void:
	var rare := source.rarity != null and not source.rarity.is_baseline
	Sound.play(collect_sound, 0.02, 0.0, 1.12 if rare else 1.0)
