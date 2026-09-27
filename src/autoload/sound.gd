extends Node
## Audio playback (autoload "Sound"): one-shot effects, music with crossfade and
## an optional "rush" layer, and the ambience loop. Volumes are per bus
## (Music / SFX / Ambience, see default_bus_layout.tres) and owned by Settings.
##
## Menu buttons get their sounds automatically: every BaseButton added to the
## tree plays "ui_click" when pressed and "ui_move" when hovered or focused
## with the keyboard/gamepad.

const SFX_VOICES := 12
const MUSIC_FADE_OUT := 2.0
const MUSIC_FADE_IN := 2.5
## The new track starts while the old one is still fading out.
const MUSIC_START_DELAY := 0.6
const RUSH_FADE := 1.5
const SILENT_DB := -60.0
const UI_SOUNDS: Dictionary[StringName, AudioStream] = {
	&"ui_move": preload("res://assets/audio/sfx/ui_move.ogg"),
	&"ui_click": preload("res://assets/audio/sfx/ui_click.ogg"),
}

var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music_players: Array[AudioStreamPlayer] = []
var _active_music: int = 0
var _ambience: AudioStreamPlayer
var _rush_on: bool = false
var _rush_tween: Tween
var _music_tween: Tween
var _keyboard_focus: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in SFX_VOICES:
		_voices.append(_make_player(&"SFX"))
	for i: int in 2:
		_music_players.append(_make_player(&"Music"))
	_ambience = _make_player(&"Ambience")
	get_tree().node_added.connect(_on_node_added)


func _exit_tree() -> void:
	stop_all()


func _input(event: InputEvent) -> void:
	# Focus changes caused by keys/gamepad make a sound; focus grabbed by code
	# when a screen opens (or following the mouse) does not.
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_keyboard_focus = true
	elif event is InputEventMouse:
		_keyboard_focus = false


## Plays a one-shot effect. `pitch_jitter` randomizes the pitch (±) so repeated
## sounds (clicks on the board) don't get tiring.
func play(stream: AudioStream, pitch_jitter: float = 0.0, volume_db: float = 0.0,
		pitch: float = 1.0) -> void:
	if stream == null:
		return
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = stream
	voice.volume_db = volume_db
	voice.pitch_scale = pitch * (1.0 + randf_range(-pitch_jitter, pitch_jitter))
	voice.play()


## Stops every stream. Call a couple of frames before quitting so the audio
## server releases the playbacks (see Main._quit()).
func stop_all() -> void:
	for child: Node in get_children():
		var player := child as AudioStreamPlayer
		if player:
			player.stop()
			player.stream = null


func play_ui(id: StringName) -> void:
	play(UI_SOUNDS[id], 0.03)


## Crossfades to `stream` (no-op when it is already playing): the old track
## fades out over MUSIC_FADE_OUT while the new one starts a moment later and
## fades in over MUSIC_FADE_IN (volumes eased in linear amplitude, which sounds
## smoother than a straight dB ramp). An AudioStreamSynchronized whose second
## stream is the rush layer starts with that layer silent (see set_rush()).
func play_music(stream: AudioStream) -> void:
	var current := _music_players[_active_music]
	if current.stream == stream and current.playing:
		return
	var old := current
	_active_music = 1 - _active_music
	var player := _music_players[_active_music]
	if _music_tween:
		_music_tween.kill()
	player.stop()
	player.stream = stream
	_rush_on = false
	if stream is AudioStreamSynchronized:
		(stream as AudioStreamSynchronized).set_sync_stream_volume(1, SILENT_DB)
	player.volume_db = SILENT_DB
	_music_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if old.playing:
		_music_tween.tween_method(_set_linear_volume.bind(old), db_to_linear(old.volume_db), 0.0,
			MUSIC_FADE_OUT)
		_music_tween.tween_callback(old.stop).set_delay(MUSIC_FADE_OUT)
	_music_tween.tween_callback(player.play).set_delay(MUSIC_START_DELAY)
	_music_tween.tween_method(_set_linear_volume.bind(player), 0.0, 1.0, MUSIC_FADE_IN) \
		.set_delay(MUSIC_START_DELAY)


func _set_linear_volume(value: float, player: AudioStreamPlayer) -> void:
	player.volume_db = linear_to_db(maxf(value, 0.001))


## Fades the rush layer (index 1 of the current synchronized track) in or out.
func set_rush(enabled: bool) -> void:
	var stream := _music_players[_active_music].stream as AudioStreamSynchronized
	if stream == null or enabled == _rush_on:
		return
	_rush_on = enabled
	if _rush_tween:
		_rush_tween.kill()
	var from := stream.get_sync_stream_volume(1)
	_rush_tween = create_tween()
	_rush_tween.tween_method(func(db: float) -> void: stream.set_sync_stream_volume(1, db),
		from, 0.0 if enabled else SILENT_DB, RUSH_FADE)


func play_ambience(stream: AudioStream) -> void:
	if _ambience.stream == stream and _ambience.playing:
		return
	_ambience.stream = stream
	_ambience.play()


func _make_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button == null or button is SettingRow:  # SettingRow plays its own sound per step.
		return
	button.pressed.connect(func() -> void: play_ui(&"ui_click"))
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			play_ui(&"ui_move"))
	button.focus_entered.connect(func() -> void:
		if _keyboard_focus:
			play_ui(&"ui_move"))
