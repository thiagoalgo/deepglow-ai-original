class_name PauseMenu
extends Control
## Pause overlay for the phase (Esc / P / gamepad Start). While open the scene
## tree is paused: the phase timer, needs and board input stop, so nothing can
## be collected. "Main menu" asks for confirmation because the phase in
## progress is not saved (the save is the one from before the phase).

signal resumed
signal quit_requested

@onready var _menu: VBoxContainer = %Menu
@onready var _resume_button: Button = %ResumeButton
@onready var _quit_button: Button = %QuitButton
@onready var _confirm: VBoxContainer = %Confirm
@onready var _leave_button: Button = %LeaveButton
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_resume_button.pressed.connect(close)
	_quit_button.pressed.connect(_show_confirm)
	_leave_button.pressed.connect(_on_leave_pressed)
	_cancel_button.pressed.connect(_show_menu.bind(_quit_button))


## Pauses the game and shows the menu.
func open() -> void:
	get_tree().paused = true
	show()
	_show_menu(_resume_button)


## Hides the menu and resumes the game.
func close() -> void:
	_release_focus()
	hide()
	get_tree().paused = false
	resumed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		if _confirm.visible:
			_show_menu(_quit_button)
		else:
			close()


func _show_menu(focus: Button) -> void:
	_confirm.hide()
	_menu.show()
	focus.grab_focus.call_deferred()


func _show_confirm() -> void:
	_menu.hide()
	_confirm.show()
	_cancel_button.grab_focus.call_deferred()


func _on_leave_pressed() -> void:
	_release_focus()
	hide()
	get_tree().paused = false
	quit_requested.emit()


func _release_focus() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
