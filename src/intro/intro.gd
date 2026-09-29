class_name Intro
extends Control
## Animated intro: plays the IntroSequence shot by shot with the narration typed
## letter by letter in a caption panel. Every change of picture (between shots,
## inside the biome montage, in from and out to black) is the same pixel
## dissolve (src/fx/pixel_dissolve.gdshader); a shot that shows the same
## picture as the previous one only changes the line. Tap (click / Space / Enter / A)
## completes the line or goes to the next shot; hold to skip it all (the
## "Hold to skip" hint is always on screen; its bar fills while holding).
## Each shot plays its narration (IntroSequence.get_voice, current locale) on the
## Voice bus; the shot lasts the line plus a short pause, and the
## music is lowered while the intro runs.
## Pixel-art rules: no continuous zoom (close-ups are cuts), no alpha.

signal finished

## Seconds a confirm button must be held to skip the whole intro.
const HOLD_TO_SKIP := 0.6
## Minimum typing speed (characters per second); long lines type faster so
## they finish at ~75% of the shot.
const TYPE_SPEED := 30.0
const TYPE_SHARE := 0.75
## Pixel dissolve between shots / between montage pictures (seconds).
const DISSOLVE_TIME := 0.8
const MONTAGE_DISSOLVE_TIME := 0.4
## FLICKER: darkening levels cycled while the flame flickers, then it fades out.
const FLICKER_LEVELS: PackedFloat32Array = [0.0, 1.0, 0.0, 2.0, 0.0, 1.0, 0.0, 3.0]
const FLICKER_SPEED := 7.0
const FLICKER_FADE_AT := 0.6
const SCREEN := Vector2i(640, 360)
## Pause after the narration before the next shot (seconds).
const VOICE_TAIL := 0.8
## The caption finishes typing at this share of the narration.
const VOICE_TYPE_SHARE := 0.9
## Music is lowered by this much during the intro (the narration leads).
const MUSIC_DUCK_DB := 8.0

@export var sequence: IntroSequence

var _index: int = -1
var _shot_time: float = 0.0
var _hold: float = 0.0
## A confirm press that started during the intro is being held.
var _holding: bool = false
var _busy: bool = false
var _done: bool = false
var _montage_index: int = -1
var _black: ImageTexture
var _shade: ShaderMaterial
var _dissolve: ShaderMaterial
## Length of the current shot: its data duration, or longer if the voice needs it.
var _shot_length: float = 0.0
var _voice_length: float = 0.0

@onready var _picture: TextureRect = %Picture
@onready var _incoming: TextureRect = %Incoming
@onready var _caption: Control = %Caption
@onready var _text: Label = %Text
@onready var _skip_fill: ColorRect = %SkipFill
@onready var _skip_track: Control = %SkipTrack
@onready var _skip_hint: Control = %SkipHint
@onready var _voice: AudioStreamPlayer = %Voice


func _enter_tree() -> void:
	_duck_music(-MUSIC_DUCK_DB)


func _exit_tree() -> void:
	_duck_music(MUSIC_DUCK_DB)


func _ready() -> void:
	assert(sequence != null and not sequence.shots.is_empty(), "Intro requires an IntroSequence.")
	_shade = _picture.material as ShaderMaterial
	_dissolve = _incoming.material as ShaderMaterial
	PaletteShift.setup(_shade)
	var image := Image.create(SCREEN.x, SCREEN.y, false, Image.FORMAT_RGBA8)
	image.fill(Palette.SHADOW_ABSOLUTE)
	_black = ImageTexture.create_from_image(image)
	_place(_picture, _black)
	_incoming.hide()
	_text.text = ""
	_caption.hide()
	_skip_fill.size.x = 0.0
	_skip_hint.show()
	_next_shot()


func _process(delta: float) -> void:
	_update_input(delta)
	if _busy or _done:
		return
	_shot_time += delta
	var shot := sequence.shots[_index]
	_type_text(shot)
	_animate(shot)
	if _shot_time >= _shot_length:
		_next_shot()


# --- Input ---------------------------------------------------------------------

## Press/release come from events (a quick tap can fall between two frames);
## only presses that started during the intro count, so the button that chose
## "New game" in the menu does not skip the first line when released.
func _input(event: InputEvent) -> void:
	if event.is_echo() or not (event.is_action(&"select") or event.is_action(&"ui_accept")):
		return
	get_viewport().set_input_as_handled()
	if event.is_pressed():
		if not _holding:
			_holding = true
			_hold = 0.0
	elif _holding:
		_holding = false
		_skip_fill.size.x = 0.0
		if _hold < HOLD_TO_SKIP:
			_advance()


func _update_input(delta: float) -> void:
	if not _holding:
		return
	_hold += delta
	_skip_fill.size.x = floorf(_skip_track.size.x * minf(_hold / HOLD_TO_SKIP, 1.0))
	if _hold >= HOLD_TO_SKIP:
		_holding = false
		_finish()


## Tap: finish typing the line, or go to the next shot.
func _advance() -> void:
	if _busy or _done:
		return
	if _text.visible_characters >= 0 and _text.visible_characters < _text.get_total_character_count():
		_text.visible_characters = -1
	else:
		_next_shot()


# --- Shots ---------------------------------------------------------------------

func _next_shot() -> void:
	_busy = true
	_voice.stop()
	_index += 1
	if _index >= sequence.shots.size():
		_caption.hide()
		await _dissolve_to(_black, DISSOLVE_TIME)
		_finish()
		return
	var shot := sequence.shots[_index]
	var picture := _first_picture(shot)
	if not _same_picture(picture, _picture.texture):
		await _dissolve_to(picture, DISSOLVE_TIME)
		if _done:
			return
	_shot_time = 0.0
	_montage_index = 0 if shot.backgrounds.size() > 1 else -1
	_set_level(0.0)
	_text.text = tr(shot.text_key)
	_text.visible_characters = 0
	_caption.show()
	_start_voice()
	_busy = false


func _first_picture(shot: IntroShot) -> Texture2D:
	if shot.backgrounds.is_empty():
		return _black
	if shot.close_up.has_area():
		var atlas := AtlasTexture.new()
		atlas.atlas = shot.backgrounds[0]
		atlas.region = Rect2(shot.close_up)
		return atlas
	return shot.backgrounds[0]


## Same art on screen (close-ups are new AtlasTextures each time, so compare
## their source and region).
func _same_picture(a: Texture2D, b: Texture2D) -> bool:
	if a == b:
		return true
	if a is AtlasTexture and b is AtlasTexture:
		return (a as AtlasTexture).atlas == (b as AtlasTexture).atlas \
			and (a as AtlasTexture).region == (b as AtlasTexture).region
	return false


func _type_text(shot: IntroShot) -> void:
	if _text.visible_characters < 0:
		return
	var total := _text.get_total_character_count()
	var type_time := _voice_length * VOICE_TYPE_SHARE if _voice_length > 0.0 else shot.duration * TYPE_SHARE
	var speed := maxf(TYPE_SPEED, total / maxf(type_time, 0.1))
	var shown := mini(total, floori(_shot_time * speed))
	_text.visible_characters = -1 if shown >= total else shown


func _animate(shot: IntroShot) -> void:
	var t := _shot_time
	match shot.motion:
		IntroShot.Motion.FLICKER:
			var fade_at := _shot_length * FLICKER_FADE_AT
			if t < fade_at:
				_set_level(FLICKER_LEVELS[int(t * FLICKER_SPEED) % FLICKER_LEVELS.size()])
			else:
				_set_level(minf(4.0, 4.0 * (t - fade_at) / (_shot_length - fade_at)))
	# Montage: the biomes follow each other at equal intervals, each one
	# dissolving into the next.
	if _montage_index >= 0 and not _incoming.visible:
		var slot := _shot_length / shot.backgrounds.size()
		var index := mini(shot.backgrounds.size() - 1, floori(t / slot))
		if index != _montage_index:
			_montage_index = index
			_dissolve_to(shot.backgrounds[index], MONTAGE_DISSOLVE_TIME)


func _finish() -> void:
	if _done:
		return
	_done = true
	_voice.stop()
	finished.emit()


# --- Helpers -------------------------------------------------------------------

## Plays the shot's narration (if recorded for the current locale) and sets the
## shot length to fit it.
func _start_voice() -> void:
	var shot := sequence.shots[_index]
	var stream := sequence.get_voice(_index, TranslationServer.get_locale())
	_voice_length = stream.get_length() if stream else 0.0
	# With a voice the shot follows the recording; without one, its data duration.
	_shot_length = _voice_length + VOICE_TAIL if stream else shot.duration
	_voice.stream = stream
	if stream:
		_voice.play()


func _duck_music(db: float) -> void:
	var bus := AudioServer.get_bus_index(&"Music")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, AudioServer.get_bus_volume_db(bus) + db)


## Dissolves the current picture into `texture` pixel by pixel.
func _dissolve_to(texture: Texture2D, time: float) -> void:
	_place(_incoming, texture)
	_dissolve.set_shader_parameter(&"progress", 0.0)
	_incoming.show()
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: _dissolve.set_shader_parameter(&"progress", v),
		0.0, 1.0, time)
	await tween.finished
	_place(_picture, texture)
	_incoming.hide()


func _place(rect: TextureRect, texture: Texture2D) -> void:
	rect.texture = texture
	rect.position = Vector2.ZERO
	rect.size = Vector2(SCREEN)


func _set_level(level: float) -> void:
	_shade.set_shader_parameter(&"level", level)
