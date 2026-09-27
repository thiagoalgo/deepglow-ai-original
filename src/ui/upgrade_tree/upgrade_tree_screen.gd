class_name UpgradeTreeScreen
extends Control
## Between-phase upgrade tree (docs/game-design.md §7.1). Clicking (or focusing
## with the keyboard) a node only selects it and shows its details; buying is
## always an explicit press of the Buy button. The screen opens with nothing selected.
## Keyboard/gamepad: confirming a node selects it and moves the focus to Buy
## (confirm again to buy, cancel to go back to the node).

## Mouse wheel: pixels scrolled per notch (smoothly tweened, whole pixels).
const WHEEL_STEP := 48
const SCROLL_TIME := 0.15
## Space kept above/below a node scrolled into view by keyboard/gamepad focus.
const FOCUS_MARGIN := 24

signal start_requested
## "Menu" pressed: back to the title menu (the run is saved on every change).
signal menu_requested

var _database: GameDatabase
var _progression: ProgressionState
var _inventory: Inventory
var _selected: UpgradeNode
var _scroll_tween: Tween
var _scroll_target: Vector2i = Vector2i.ZERO
## Last input came from the mouse (then pressing a node never moves the focus).
var _pointer_input: bool = true

@onready var _inventory_bar: HFlowContainer = %InventoryBar
@onready var _tree_view: UpgradeTreeView = %TreeView
@onready var _scroll: ScrollContainer = %Scroll
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _description: Label = %Description
@onready var _costs: HBoxContainer = %Costs
@onready var _status_label: Label = %StatusLabel
@onready var _buy_button: Button = %BuyButton
@onready var _start_button: Button = %StartButton
@onready var _menu_button: Button = %MenuButton
@onready var _save_indicator: SaveIndicator = %SaveIndicator


func _ready() -> void:
	hide()
	_tree_view.node_focused.connect(_on_node_focused)
	_scroll.gui_input.connect(_on_scroll_input)
	_tree_view.node_pressed.connect(_on_node_pressed)
	_buy_button.pressed.connect(_buy_selected)
	_start_button.pressed.connect(_on_start_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)


func open(database: GameDatabase, progression: ProgressionState, inventory: Inventory,
		next_phase: int) -> void:
	_database = database
	_progression = progression
	_inventory = inventory
	_start_button.text = tr(&"UI_START_PHASE") % next_phase
	_selected = null
	_tree_view.build(database)
	_scroll_target = Vector2i(_scroll.scroll_horizontal, _scroll.scroll_vertical)
	_refresh()
	show()


## Shows the "Saving… / Game saved" badge next to the Start button.
func show_save(ok: bool) -> void:
	_save_indicator.show_save(ok)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		_pointer_input = true
	elif event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_pointer_input = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	# Cancel on the Buy button goes back to the node it belongs to.
	if _buy_button.has_focus() and _selected \
			and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"cancel")):
		_focus_selected_node()
		get_viewport().set_input_as_handled()
		return
	# Nothing is focused when the screen opens (so nothing gets bought by
	# accident); the first key/gamepad direction focuses the tree.
	if get_viewport().gui_get_focus_owner() != null:
		return
	for action: StringName in [&"ui_left", &"ui_right", &"ui_up", &"ui_down"]:
		if event.is_action_pressed(action):
			_tree_view.focus_first()
			get_viewport().set_input_as_handled()
			return


func _refresh() -> void:
	for child: Node in _inventory_bar.get_children():
		child.queue_free()
	for resource: ResourceType in _database.resources:
		if _inventory.is_discovered(resource.id):
			_inventory_bar.add_child(ResourceAmountView.create(resource, NumberFormat.compact(_inventory.get_amount(resource.id))))
	_tree_view.refresh(_progression, _inventory)
	if _selected:
		_select(_selected)
	else:
		_tree_view.set_selected(null)
		_clear_details()


func _on_node_pressed(upgrade: UpgradeNode) -> void:
	_select(upgrade)
	if not _pointer_input and not _buy_button.disabled:
		var view := _tree_view.get_view(upgrade.id)
		_buy_button.focus_neighbor_left = _buy_button.get_path_to(view)
		_buy_button.focus_neighbor_top = _buy_button.get_path_to(view)
		_buy_button.grab_focus()


func _focus_selected_node() -> void:
	var view := _tree_view.get_view(_selected.id) if _selected else null
	if view:
		view.grab_focus()


func _on_node_focused(upgrade: UpgradeNode) -> void:
	_select(upgrade)
	_scroll_into_view(_tree_view.get_view(upgrade.id))


## Scrolls just enough to show `control` (plus a margin), smoothly.
func _scroll_into_view(control: Control) -> void:
	if control == null:
		return
	var rect := Rect2(control.position, control.size).grow(FOCUS_MARGIN)
	var view_size := _scroll.size
	var target := _scroll_target
	if rect.position.y < target.y:
		target.y = int(rect.position.y)
	elif rect.end.y > target.y + view_size.y:
		target.y = int(rect.end.y - view_size.y)
	if rect.position.x < target.x:
		target.x = int(rect.position.x)
	elif rect.end.x > target.x + view_size.x:
		target.x = int(rect.end.x - view_size.x)
	_scroll_to(target)


func _scroll_to(target: Vector2i) -> void:
	var max_scroll := Vector2i((_tree_view.size - _scroll.size).max(Vector2.ZERO))
	_scroll_target = target.clamp(Vector2i.ZERO, max_scroll)
	if _scroll_tween:
		_scroll_tween.kill()
	_scroll_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_scroll_tween.tween_property(_scroll, ^"scroll_vertical", _scroll_target.y, SCROLL_TIME)
	_scroll_tween.tween_property(_scroll, ^"scroll_horizontal", _scroll_target.x, SCROLL_TIME)


## Replaces the ScrollContainer's small, uneven wheel steps with fixed smooth steps.
func _on_scroll_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or not button.pressed:
		return
	var step := Vector2i.ZERO
	match button.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			step.y = -WHEEL_STEP
		MOUSE_BUTTON_WHEEL_DOWN:
			step.y = WHEEL_STEP
		MOUSE_BUTTON_WHEEL_LEFT:
			step.x = -WHEEL_STEP
		MOUSE_BUTTON_WHEEL_RIGHT:
			step.x = WHEEL_STEP
		_:
			return
	if button.shift_pressed:
		step = Vector2i(step.y, step.x)
	_scroll_to(_scroll_target + step)
	_scroll.accept_event()


func _select(upgrade: UpgradeNode) -> void:
	_selected = upgrade
	_tree_view.set_selected(upgrade)
	_name_label.text = tr(upgrade.get_name_key())
	_level_label.text = tr(&"UI_LEVEL") % [_progression.get_level(upgrade.id), upgrade.max_level]
	_description.text = tr(upgrade.get_desc_key())
	for child: Node in _costs.get_children():
		child.queue_free()
	_status_label.text = ""
	if _progression.is_maxed(upgrade):
		_buy_button.text = tr(&"UI_MAXED")
		_buy_button.disabled = true
		return
	_buy_button.text = tr(&"UI_BUY")
	for cost: ResourceAmount in _progression.get_next_cost(upgrade):
		var missing := _inventory.get_amount(cost.resource.id) < cost.amount
		_costs.add_child(ResourceAmountView.create(cost.resource, NumberFormat.compact(cost.amount), missing))
	_status_label.text = _lock_reason(upgrade)
	_buy_button.disabled = not _progression.can_buy(upgrade, _inventory)


func _lock_reason(upgrade: UpgradeNode) -> String:
	if _progression.is_blocked_by_choice(upgrade):
		return tr(&"UI_CHOICE_TAKEN")
	if _progression.get_total_levels() < upgrade.required_points:
		return tr(&"UI_REQUIRES_POINTS") % upgrade.required_points
	var missing: PackedStringArray = []
	for prerequisite: UpgradeNode in upgrade.prerequisites:
		if _progression.get_level(prerequisite.id) < 1:
			missing.append(tr(prerequisite.get_name_key()))
	if not missing.is_empty():
		return tr(&"UI_REQUIRES") % ", ".join(missing)
	return ""


func _clear_details() -> void:
	_name_label.text = ""
	_level_label.text = ""
	_description.text = tr(&"UI_SELECT_UPGRADE")
	for child: Node in _costs.get_children():
		child.queue_free()
	_status_label.text = ""
	_buy_button.disabled = true


func _buy_selected() -> void:
	if _selected and _progression.buy(_selected, _inventory):
		_refresh()
		# Maxed or no longer affordable: give the focus back to the node.
		if _buy_button.disabled and not _pointer_input:
			_focus_selected_node()


func _on_start_pressed() -> void:
	_close()
	start_requested.emit()


func _on_menu_pressed() -> void:
	_close()
	menu_requested.emit()


func _close() -> void:
	_selected = null
	_save_indicator.dismiss()
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
	hide()
