class_name DemoEndScreen
extends Control
## "Thanks for playing the demo!" (demo builds, after the demo ending): play
## time, phases played, a feedback button (only when Demo.get_feedback_url() is
## set) and "Keep playing" (back to the tree; the rest of the demo biomes can
## still be finished and the save carries over to the full game).

signal closed

@onready var _time_label: Label = %TimeLabel
@onready var _phases_label: Label = %PhasesLabel
@onready var _feedback_button: Button = %FeedbackButton
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	hide()
	_feedback_button.pressed.connect(_on_feedback_pressed)
	_continue_button.pressed.connect(close)


func open(play_seconds: float, phases_played: int) -> void:
	_time_label.text = tr(&"UI_DEMO_PLAY_TIME") % format_time(play_seconds)
	_phases_label.text = tr(&"UI_DEMO_PHASES") % phases_played
	_feedback_button.visible = not Demo.get_feedback_url().is_empty()
	show()
	_continue_button.grab_focus.call_deferred()


func close() -> void:
	if _continue_button.has_focus() or _feedback_button.has_focus():
		get_viewport().gui_release_focus()
	hide()
	closed.emit()


## "42 min" / "1 h 05 min".
static func format_time(seconds: float) -> String:
	var minutes := int(seconds / 60.0)
	if minutes < 60:
		return "%d min" % minutes
	return "%d h %02d min" % [minutes / 60, minutes % 60]


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _on_feedback_pressed() -> void:
	OS.shell_open(Demo.get_feedback_url())
