class_name TitleMenu
extends Control
## Title screen: Continue (only when a save exists), New game (asks for
## confirmation before overwriting a save), Settings and Quit.
## Main decides what each choice does; this screen only reports it.

signal continue_requested
signal new_game_requested
signal settings_requested
signal quit_requested

## Next phase of the saved run; 0 when there is no save.
var _saved_next_phase: int = 0
var _focus_settings: bool = false

@onready var _menu: VBoxContainer = %Menu
@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _confirm: VBoxContainer = %Confirm
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton
@onready var _version: Label = %Version


## Call before adding the screen to the tree. `focus_settings`: coming back
## from the Settings screen, so keep the focus on its button.
func setup(saved_next_phase: int, focus_settings: bool = false) -> void:
	_saved_next_phase = saved_next_phase
	_focus_settings = focus_settings


func _ready() -> void:
	_version.text = "v%s" % ProjectSettings.get_setting("application/config/version", "")
	_continue_button.visible = _saved_next_phase > 0
	_continue_button.text = tr(&"UI_CONTINUE_RUN") % _saved_next_phase
	_continue_button.pressed.connect(continue_requested.emit)
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_settings_button.pressed.connect(settings_requested.emit)
	_quit_button.pressed.connect(quit_requested.emit)
	# Quitting makes no sense in a browser build.
	_quit_button.visible = not OS.has_feature("web")
	_confirm_button.pressed.connect(new_game_requested.emit)
	_cancel_button.pressed.connect(_show_menu.bind(_new_game_button))
	var first := _continue_button if _continue_button.visible else _new_game_button
	_show_menu(_settings_button if _focus_settings else first)


func _unhandled_input(event: InputEvent) -> void:
	if _confirm.visible and event.is_action_pressed(&"cancel"):
		_show_menu(_new_game_button)
		get_viewport().set_input_as_handled()


func _on_new_game_pressed() -> void:
	if _saved_next_phase > 0:
		_menu.hide()
		_confirm.show()
		_cancel_button.grab_focus.call_deferred()
	else:
		new_game_requested.emit()


func _show_menu(focus: Button) -> void:
	_confirm.hide()
	_menu.show()
	focus.grab_focus.call_deferred()
