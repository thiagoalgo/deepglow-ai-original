class_name PhaseSummary
extends Control
## End-of-phase overlay: what was collected and how much of the board was cleared.

signal continued

@onready var _title: Label = %Title
@onready var _cleared: Label = %Cleared
@onready var _hungry: Label = %Hungry
@onready var _thirsty: Label = %Thirsty
@onready var _gathered_list: HBoxContainer = %GatheredList
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	hide()
	_continue_button.pressed.connect(_on_continue_pressed)


func open(phase_number: int, gathered: Dictionary[StringName, int], cleared: int, total: int,
		database: GameDatabase, hungry_seconds: float = 0.0, thirsty_seconds: float = 0.0) -> void:
	_title.text = tr(&"UI_SUMMARY_TITLE") % phase_number
	_cleared.text = tr(&"UI_SUMMARY_CLEARED") % [cleared, total]
	# Explain the empty-bar penalties, so they are not a hidden rule.
	_hungry.text = tr(&"UI_SUMMARY_HUNGRY") % roundi(hungry_seconds)
	_hungry.visible = roundi(hungry_seconds) > 0
	_thirsty.text = tr(&"UI_SUMMARY_THIRSTY") % roundi(thirsty_seconds)
	_thirsty.visible = roundi(thirsty_seconds) > 0
	for child: Node in _gathered_list.get_children():
		child.queue_free()
	for resource: ResourceType in database.resources:
		var amount: int = gathered.get(resource.id, 0)
		if amount > 0:
			_gathered_list.add_child(ResourceAmountView.create(resource, "+%d" % amount))
	show()
	_continue_button.grab_focus.call_deferred()


func _on_continue_pressed() -> void:
	hide()
	continued.emit()
