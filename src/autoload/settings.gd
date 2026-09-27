extends Node
## Player settings (autoload "Settings"), persisted to user://settings.cfg.
##
## Owns the active locale and the CRT filter switch. To add a language: add a column to
## localization/translations.csv, register the generated .translation in
## Project Settings > Localization, and add an entry to SUPPORTED_LOCALES.

signal locale_changed(locale: String)
signal crt_changed(enabled: bool)

const SAVE_PATH := "user://settings.cfg"
const DEFAULT_LOCALE := "en"
## Locale code -> language name written in that language (never translated).
const SUPPORTED_LOCALES: Dictionary[String, String] = {
	"en": "English",
	"pt_BR": "Português (Brasil)",
}

var locale: String = DEFAULT_LOCALE
## Soft CRT look (curved tube, scanlines). Toggle: title screen or the toggle_crt action (F2).
var crt_enabled: bool = true

var _config := ConfigFile.new()
var _has_saved_locale: bool = false


func _ready() -> void:
	_load()
	_apply_locale()


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


func _load() -> void:
	if _config.load(SAVE_PATH) == OK and _config.has_section_key("general", "locale"):
		locale = match_supported_locale(str(_config.get_value("general", "locale")))
		_has_saved_locale = true
	else:
		locale = match_supported_locale(OS.get_locale())
	crt_enabled = bool(_config.get_value("video", "crt", crt_enabled))


func _save() -> void:
	if _has_saved_locale:
		_config.set_value("general", "locale", locale)
	_config.set_value("video", "crt", crt_enabled)
	var err := _config.save(SAVE_PATH)
	if err != OK:
		push_error("Failed to save settings: %s" % error_string(err))
