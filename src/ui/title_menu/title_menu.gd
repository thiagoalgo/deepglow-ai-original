class_name TitleMenu
extends Control
## Title screen: Continue (only when a save exists), New game (asks for
## confirmation before overwriting a save), Language, CRT filter and Quit.
## Main decides what each choice does; this screen only reports it.

signal continue_requested
signal new_game_requested
signal language_requested
signal quit_requested

## Next phase of the saved run; 0 when there is no save.
var _saved_next_phase: int = 0

@onready var _menu: VBoxContainer = %Menu
@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _language_button: Button = %LanguageButton
@onready var _crt_toggle: Button = %CrtToggle
@onready var _quit_button: Button = %QuitButton
@onready var _confirm: VBoxContainer = %Confirm
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton


## Call before adding the screen to the tree.
func setup(saved_next_phase: int) -> void:
	_saved_next_phase = saved_next_phase


func _ready() -> void:
	_continue_button.visible = _saved_next_phase > 0
	_continue_button.text = tr(&"UI_CONTINUE_RUN") % _saved_next_phase
	_continue_button.pressed.connect(continue_requested.emit)
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_language_button.pressed.connect(language_requested.emit)
	_crt_toggle.pressed.connect(func() -> void: Settings.set_crt_enabled(not Settings.crt_enabled))
	_quit_button.pressed.connect(quit_requested.emit)
	# Quitting makes no sense in a browser build.
	_quit_button.visible = not OS.has_feature("web")
	_confirm_button.pressed.connect(new_game_requested.emit)
	_cancel_button.pressed.connect(_show_menu.bind(true))
	Settings.crt_changed.connect(_update_crt_label)
	_update_crt_label(Settings.crt_enabled)
	_show_menu(false)


func _unhandled_input(event: InputEvent) -> void:
	if _confirm.visible and event.is_action_pressed(&"cancel"):
		_show_menu(true)
		get_viewport().set_input_as_handled()


func _on_new_game_pressed() -> void:
	if _saved_next_phase > 0:
		_menu.hide()
		_confirm.show()
		_cancel_button.grab_focus.call_deferred()
	else:
		new_game_requested.emit()


## Shows the main buttons; focus goes to New game when coming back from the
## confirmation, otherwise to the first visible option.
func _show_menu(from_confirm: bool) -> void:
	_confirm.hide()
	_menu.show()
	var target := _new_game_button if from_confirm or not _continue_button.visible else _continue_button
	target.grab_focus.call_deferred()


func _update_crt_label(enabled: bool) -> void:
	_crt_toggle.text = tr(&"UI_CRT_ON") if enabled else tr(&"UI_CRT_OFF")
