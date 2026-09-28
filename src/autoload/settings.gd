extends Node
## Player settings (autoload "Settings"), persisted to user://settings.cfg.
##
## Owns the active locale, the CRT filter, fullscreen and the audio bus volumes
## (all edited on the Settings screen). To add a language: add a column to
## localization/translations.csv, register the generated .translation in
## Project Settings > Localization, and add an entry to SUPPORTED_LOCALES.

signal locale_changed(locale: String)
signal crt_changed(enabled: bool)
signal fullscreen_changed(enabled: bool)
signal volume_changed(bus: StringName, steps: int)

const SAVE_PATH := "user://settings.cfg"
const DEFAULT_LOCALE := "en"
## Volume is stored in steps (0 = muted .. VOLUME_STEPS = full) per audio bus
## (default_bus_layout.tres). Default steps per bus:
const DEFAULT_VOLUMES: Dictionary[StringName, int] = {&"Music": 7, &"SFX": 8, &"Ambience": 6, &"Voice": 9}
const VOLUME_STEPS := 10
## Locale code -> language name written in that language (never translated).
const SUPPORTED_LOCALES: Dictionary[String, String] = {
	"en": "English",
	"pt_BR": "Português (Brasil)",
}

var locale: String = DEFAULT_LOCALE
## Soft CRT look (curved tube, scanlines). Toggle: title screen or the toggle_crt action (F2).
var crt_enabled: bool = true
## Toggle: Settings screen or the toggle_fullscreen action (F11).
var fullscreen: bool = false
var volumes: Dictionary[StringName, int] = DEFAULT_VOLUMES.duplicate()

var _config := ConfigFile.new()
var _has_saved_locale: bool = false


func _ready() -> void:
	_load()
	_apply_locale()
	if fullscreen:
		_apply_fullscreen()
	for bus: StringName in volumes:
		_apply_volume(bus)


## True once the player has picked a language at least once.
func has_saved_locale() -> bool:
	return _has_saved_locale


func set_locale(new_locale: String) -> void:
	if not SUPPORTED_LOCALES.has(new_locale):
		push_error("Unsupported locale: %s" % new_locale)
		return
	locale = new_locale
	_has_saved_locale = true
	_apply_locale()
	_save()
	locale_changed.emit(locale)


func set_crt_enabled(enabled: bool) -> void:
	crt_enabled = enabled
	_save()
	crt_changed.emit(crt_enabled)


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_fullscreen()
	_save()
	fullscreen_changed.emit(fullscreen)


## Best supported match for a system/locale string (e.g. "pt_PT" -> "pt_BR").
static func match_supported_locale(requested: String) -> String:
	if SUPPORTED_LOCALES.has(requested):
		return requested
	var language := requested.get_slice("_", 0)
	for code: String in SUPPORTED_LOCALES:
		if code.get_slice("_", 0) == language:
			return code
	return DEFAULT_LOCALE


func _apply_locale() -> void:
	TranslationServer.set_locale(locale)


func get_volume(bus: StringName) -> int:
	return volumes.get(bus, VOLUME_STEPS)


func set_volume(bus: StringName, steps: int) -> void:
	volumes[bus] = clampi(steps, 0, VOLUME_STEPS)
	_apply_volume(bus)
	_save()
	volume_changed.emit(bus, volumes[bus])


func _apply_volume(bus: StringName) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	var steps := get_volume(bus)
	AudioServer.set_bus_mute(index, steps == 0)
	AudioServer.set_bus_volume_db(index, linear_to_db(float(steps) / VOLUME_STEPS))


func _apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func _load() -> void:
	if _config.load(SAVE_PATH) == OK and _config.has_section_key("general", "locale"):
		locale = match_supported_locale(str(_config.get_value("general", "locale")))
		_has_saved_locale = true
	else:
		locale = match_supported_locale(OS.get_locale())
	crt_enabled = bool(_config.get_value("video", "crt", crt_enabled))
	fullscreen = bool(_config.get_value("video", "fullscreen", fullscreen))
	for bus: StringName in DEFAULT_VOLUMES:
		volumes[bus] = clampi(int(_config.get_value("audio", String(bus).to_lower(), DEFAULT_VOLUMES[bus])), 0, VOLUME_STEPS)


func _save() -> void:
	if _has_saved_locale:
		_config.set_value("general", "locale", locale)
	_config.set_value("video", "crt", crt_enabled)
	_config.set_value("video", "fullscreen", fullscreen)
	for bus: StringName in volumes:
		_config.set_value("audio", String(bus).to_lower(), volumes[bus])
	var err := _config.save(SAVE_PATH)
	if err != OK:
		push_error("Failed to save settings: %s" % error_string(err))
