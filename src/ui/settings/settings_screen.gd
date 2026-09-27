class_name SettingsScreen
extends Control
## Player settings: language, CRT filter, fullscreen (volume rows come with audio).
## Every change applies and is saved immediately through the Settings autoload;
## Back (or the cancel action) closes the screen.

signal closed

@onready var _language_row: SettingRow = %LanguageRow
@onready var _crt_row: SettingRow = %CrtRow
@onready var _fullscreen_row: SettingRow = %FullscreenRow
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_language_row.value_changed.connect(_on_language_changed)
	_crt_row.value_changed.connect(func(index: int) -> void: Settings.set_crt_enabled(index == 1))
	_fullscreen_row.value_changed.connect(func(index: int) -> void: Settings.set_fullscreen(index == 1))
	_back_button.pressed.connect(closed.emit)
	Settings.locale_changed.connect(_refresh.unbind(1))
	Settings.crt_changed.connect(_refresh.unbind(1))
	Settings.fullscreen_changed.connect(_refresh.unbind(1))
	_refresh()
	_language_row.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()


func _refresh() -> void:
	# Language names are always written in their own language (never translated).
	_language_row.set_options(PackedStringArray(Settings.SUPPORTED_LOCALES.values()),
		_locales().find(Settings.locale))
	var off_on := PackedStringArray([tr(&"UI_OFF"), tr(&"UI_ON")])
	_crt_row.set_options(off_on, 1 if Settings.crt_enabled else 0)
	_fullscreen_row.set_options(off_on, 1 if Settings.fullscreen else 0)


func _on_language_changed(index: int) -> void:
	Settings.set_locale(_locales()[index])


func _locales() -> PackedStringArray:
	return PackedStringArray(Settings.SUPPORTED_LOCALES.keys())
