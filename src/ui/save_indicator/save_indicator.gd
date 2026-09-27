class_name SaveIndicator
extends PanelContainer
## Small "Saving… / Game saved" badge (bottom-left of the upgrade screen).
## Saving itself takes a few milliseconds, so the badge holds "Saving" for
## SAVING_TIME and the result for RESULT_TIME, long enough to be noticed.

const SAVING_TIME := 1.2
const RESULT_TIME := 1.8
const DOT_STEP := 0.25

enum Stage { HIDDEN, SAVING, RESULT }

var _stage: Stage = Stage.HIDDEN
var _elapsed: float = 0.0
var _ok: bool = true

@onready var _icon: SaveIcon = %Icon
@onready var _label: Label = %Label


func _ready() -> void:
	hide()
	set_process(false)


## Shows the badge for a save that just happened (`ok` = it succeeded).
func show_save(ok: bool) -> void:
	_ok = ok
	_stage = Stage.SAVING
	_elapsed = 0.0
	show()
	set_process(true)
	_update()


func dismiss() -> void:
	_stage = Stage.HIDDEN
	hide()
	set_process(false)


func _process(delta: float) -> void:
	_elapsed += delta
	if _stage == Stage.SAVING and _elapsed >= SAVING_TIME:
		_stage = Stage.RESULT
		_elapsed = 0.0
	elif _stage == Stage.RESULT and _elapsed >= RESULT_TIME:
		dismiss()
		return
	_update()


func _update() -> void:
	match _stage:
		Stage.SAVING:
			_icon.look = SaveIcon.Look.DOTS
			_icon.active_dot = int(_elapsed / DOT_STEP) % 3
			_label.text = tr(&"UI_SAVING")
			_label.theme_type_variation = &"MutedLabel"
		Stage.RESULT:
			_icon.look = SaveIcon.Look.CHECK if _ok else SaveIcon.Look.CROSS
			_label.text = tr(&"UI_SAVED") if _ok else tr(&"UI_SAVE_FAILED")
			_label.theme_type_variation = &"" if _ok else &"AlertLabel"
