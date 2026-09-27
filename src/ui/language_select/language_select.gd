class_name LanguageSelect
extends Control
## Start screen: pick the game language.
## One button per entry in Settings.SUPPORTED_LOCALES (built at runtime).
## Focusing/hovering a language previews the whole screen in that language;
## confirming persists it through Settings. Also hosts the CRT filter switch.

signal language_confirmed(locale: String)

@onready var _options: VBoxContainer = %Options
@onready var _crt_toggle: Button = %CrtToggle


func _ready() -> void:
	_build_options()
	_crt_toggle.pressed.connect(func() -> void: Settings.set_crt_enabled(not Settings.crt_enabled))
	Settings.crt_changed.connect(_update_crt_label)
	_update_crt_label(Settings.crt_enabled)


func _build_options() -> void:
	var initial_button: Button
	for locale: String in Settings.SUPPORTED_LOCALES:
		var button := Button.new()
		button.name = "Option_%s" % locale
		# Language names are always shown in their own language.
		button.text = Settings.SUPPORTED_LOCALES[locale]
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.focus_entered.connect(_on_option_focused.bind(locale))
		button.mouse_entered.connect(button.grab_focus)
		button.pressed.connect(_on_option_pressed.bind(locale))
		_options.add_child(button)
		if locale == Settings.locale:
			initial_button = button
	if initial_button == null and _options.get_child_count() > 0:
		initial_button = _options.get_child(0) as Button
	if initial_button:
		initial_button.grab_focus.call_deferred()


func _on_option_focused(locale: String) -> void:
	# Preview only; Settings keeps the persisted locale until confirmation.
	TranslationServer.set_locale(locale)


func _on_option_pressed(locale: String) -> void:
	Settings.set_locale(locale)
	language_confirmed.emit(locale)


func _update_crt_label(enabled: bool) -> void:
	_crt_toggle.text = tr(&"UI_CRT_ON") if enabled else tr(&"UI_CRT_OFF")
