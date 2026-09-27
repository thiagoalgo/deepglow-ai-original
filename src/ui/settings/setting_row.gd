class_name SettingRow
extends Button
## One line of the Settings screen: "Name      < Value >".
## The whole row is a focusable button: left/right (keys, d-pad) step through
## the options, a click/confirm advances to the next one (wrapping around).
## New settings (volume, ...) are new rows; values live in the Settings autoload.

signal value_changed(index: int)

## Translation key of the setting name.
@export var label_key: StringName

var _options: PackedStringArray = []
var _index: int = 0

@onready var _name_label: Label = %NameLabel
@onready var _value_label: Label = %ValueLabel


func _ready() -> void:
	_name_label.text = label_key
	pressed.connect(_step.bind(1))
	focus_entered.connect(_update_colors)
	focus_exited.connect(_update_colors)
	mouse_entered.connect(_update_colors)
	mouse_exited.connect(_update_colors)
	_update_colors()


## Display strings (already translated) and the selected index. Does not emit.
func set_options(options: PackedStringArray, index: int) -> void:
	_options = options
	_index = clampi(index, 0, maxi(0, options.size() - 1))
	_update_value()


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_left"):
		_step(-1)
		accept_event()
	elif event.is_action_pressed(&"ui_right"):
		_step(1)
		accept_event()


func _step(direction: int) -> void:
	if _options.size() < 2:
		return
	_index = posmod(_index + direction, _options.size())
	_update_value()
	value_changed.emit(_index)


func _update_value() -> void:
	if _value_label and not _options.is_empty():
		_value_label.text = "<  %s  >" % _options[_index]


func _update_colors() -> void:
	var active := has_focus() or is_hovered()
	var name_color := get_theme_color(&"font_focus_color", &"Button") if active \
		else get_theme_color(&"font_color", &"MutedLabel")
	var value_color := get_theme_color(&"font_focus_color" if active else &"font_color", &"Button")
	_name_label.add_theme_color_override(&"font_color", name_color)
	_value_label.add_theme_color_override(&"font_color", value_color)
