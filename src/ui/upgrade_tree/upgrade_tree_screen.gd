class_name UpgradeTreeScreen
extends Control
## Between-phase upgrade tree (docs/game-design.md §7.1), laid out left to right
## (one band per biome). Clicking a node (or confirming it with the keyboard/
## gamepad) selects it and opens its details popup next to it; moving the focus
## alone never opens it. Buying is always an explicit press of the Buy button.
## The popup keeps its place and never shrinks while it stays on the same node.
## It closes with cancel (Esc / B / right click) or a click on an empty spot.
## Keyboard/gamepad: confirming a node moves the focus to Buy (confirm again to
## buy); cancel closes the popup and gives the focus back to the node.

## Mouse wheel: pixels scrolled per notch (smoothly tweened, whole pixels).
const WHEEL_STEP := 48
const SCROLL_TIME := 0.15
## Space kept left/right of a node scrolled into view by keyboard/gamepad focus.
const FOCUS_MARGIN := 24
## Gap between the selected node and its details popup.
const POPUP_GAP := 10

signal start_requested
## "Menu" pressed: back to the title menu (the run is saved on every change).
signal menu_requested

var _database: GameDatabase
var _progression: ProgressionState
var _inventory: Inventory
var _selected: UpgradeNode
## Popup position relative to the selected node (kept while scrolling/buying).
var _popup_offset: Vector2 = Vector2.ZERO
var _scroll_tween: Tween
var _scroll_target: Vector2i = Vector2i.ZERO
## Last input came from the mouse (then pressing a node never moves the focus).
var _pointer_input: bool = true

@onready var _inventory_bar: HFlowContainer = %InventoryBar
@onready var _tree_view: UpgradeTreeView = %TreeView
@onready var _scroll: ScrollContainer = %Scroll
@onready var _details: PanelContainer = %Details
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _description: Label = %Description
@onready var _costs: HBoxContainer = %Costs
@onready var _status_label: Label = %StatusLabel
@onready var _choice_label: Label = %ChoiceLabel
@onready var _buy_button: Button = %BuyButton
@onready var _start_button: Button = %StartButton
## "Tree complete: X/N", only after the ending (post-game goal).
@onready var _tree_progress: Label = %TreeProgress
@onready var _menu_button: Button = %MenuButton
@onready var _save_indicator: SaveIndicator = %SaveIndicator


func _ready() -> void:
	hide()
	_tree_view.node_focused.connect(_on_node_focused)
	_scroll.gui_input.connect(_on_scroll_input)
	_tree_view.node_pressed.connect(_on_node_pressed)
	_tree_view.background_pressed.connect(_on_background_pressed)
	_scroll.get_h_scroll_bar().value_changed.connect(_on_scrolled.unbind(1))
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
	_scroll_target = Vector2i(_scroll.scroll_horizontal, 0)
	_refresh()
	show()


## Re-reads the inventory and progression (after an outside change, e.g. the
## dev console's "set").
func refresh() -> void:
	_refresh()


## Closes the details popup (e.g. before the demo end screen covers the tree).
func hide_details() -> void:
	if _selected:
		_close_details()


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
	# Cancel closes the popup; the focus goes back to the node it belongs to.
	if _selected and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"cancel")):
		var had_focus := get_viewport().gui_get_focus_owner() != null
		var node := _selected
		_close_details()
		if had_focus:
			var view := _tree_view.get_view(node.id)
			if view:
				view.grab_focus()
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
	_tree_progress.visible = _progression.is_story_complete()
	_tree_progress.text = tr(&"UI_TREE_PROGRESS") % [_progression.count_maxed(), _database.upgrades.size()]
	if _selected:
		_show_details(_selected)
	else:
		_tree_view.set_selected(null)
		_clear_details()


func _on_node_pressed(upgrade: UpgradeNode) -> void:
	_select(upgrade)
	if not _pointer_input and not _buy_button.disabled and _details.visible:
		var view := _tree_view.get_view(upgrade.id)
		_buy_button.focus_neighbor_left = _buy_button.get_path_to(view)
		_buy_button.focus_neighbor_top = _buy_button.get_path_to(view)
		_buy_button.grab_focus()


func _focus_selected_node() -> void:
	var view := _tree_view.get_view(_selected.id) if _selected else null
	if view:
		view.grab_focus()


## Moving the focus only highlights the node (and scrolls to it); leaving the
## node whose popup is open closes the popup.
func _on_node_focused(upgrade: UpgradeNode) -> void:
	if _selected and upgrade != _selected:
		_close_details()
	_scroll_into_view(_tree_view.get_view(upgrade.id))


## Scrolls just enough to show `control` (plus a margin), smoothly.
func _scroll_into_view(control: Control) -> void:
	if control == null:
		return
	var rect := Rect2(control.position, control.size).grow(FOCUS_MARGIN)
	var view_size := _scroll.size
	var target := _scroll_target
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
	_scroll_tween.tween_property(_scroll, ^"scroll_horizontal", _scroll_target.x, SCROLL_TIME)


## Replaces the ScrollContainer's small, uneven wheel steps with fixed smooth steps.
func _on_scroll_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or not button.pressed:
		return
	# The tree only scrolls sideways: every wheel direction moves it left/right.
	var step := 0
	match button.button_index:
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT:
			step = -WHEEL_STEP
		MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT:
			step = WHEEL_STEP
		_:
			return
	_scroll_to(_scroll_target + Vector2i(step, 0))
	_scroll.accept_event()


## Opens the popup for `upgrade`, placed beside its node.
func _select(upgrade: UpgradeNode) -> void:
	_selected = upgrade
	_tree_view.set_selected(upgrade)
	_details.custom_minimum_size.y = 0
	_details.size = Vector2.ZERO
	_show_details(upgrade)
	_details.show()
	_place_details.call_deferred()


## Fills the popup. Its size only grows, so buying never makes it jump.
func _show_details(upgrade: UpgradeNode) -> void:
	_name_label.text = tr(upgrade.get_name_key())
	_level_label.text = tr(&"UI_LEVEL") % [_progression.get_level(upgrade.id), upgrade.max_level]
	_description.text = tr(upgrade.get_desc_key())
	for child: Node in _costs.get_children():
		_costs.remove_child(child)
		child.queue_free()
	_status_label.text = ""
	_update_choice_label(upgrade)
	_details.custom_minimum_size.y = _details.size.y
	if _progression.is_maxed(upgrade):
		_buy_button.text = tr(&"UI_MAXED")
		_buy_button.disabled = true
		return
	# The first level of a choice node is a decision, not just a purchase.
	var choosing := not upgrade.choice_group.is_empty() and _progression.get_level(upgrade.id) == 0
	_buy_button.text = tr(&"UI_CHOOSE") if choosing else tr(&"UI_BUY")
	for cost: ResourceAmount in _progression.get_next_cost(upgrade):
		var missing := _inventory.get_amount(cost.resource.id) < cost.amount
		_costs.add_child(ResourceAmountView.create(cost.resource, NumberFormat.compact(cost.amount), missing))
	_status_label.text = _lock_reason(upgrade)
	_buy_button.disabled = not _progression.can_buy(upgrade, _inventory)


## Amber line for mutually exclusive nodes: what buying blocks, or what was blocked.
## (A node blocked by the other choice explains it in the status line instead.)
func _update_choice_label(upgrade: UpgradeNode) -> void:
	_choice_label.visible = false
	if upgrade.choice_group.is_empty() or _progression.is_blocked_by_choice(upgrade) \
			or _progression.is_story_complete():
		return
	var rivals := ", ".join(_choice_rival_names(upgrade, false))
	var owned := _progression.get_level(upgrade.id) > 0
	_choice_label.text = (tr(&"UI_CHOICE_MADE") if owned else tr(&"UI_CHOICE_WARNING")) % rivals
	_choice_label.visible = true


## Names of the other nodes in the same choice group (only owned ones if `owned_only`).
func _choice_rival_names(upgrade: UpgradeNode, owned_only: bool) -> PackedStringArray:
	var names: PackedStringArray = []
	for other: UpgradeNode in _database.upgrades:
		if other == upgrade or other.choice_group != upgrade.choice_group:
			continue
		if owned_only and _progression.get_level(other.id) == 0:
			continue
		names.append(tr(other.get_name_key()))
	return names


func _lock_reason(upgrade: UpgradeNode) -> String:
	if _progression.is_beyond_demo(upgrade):
		return tr(&"UI_REQUIRES_FULL_VERSION")
	if _progression.is_blocked_by_choice(upgrade):
		return tr(&"UI_CHOICE_TAKEN") % ", ".join(_choice_rival_names(upgrade, true))
	var required := _progression.get_required_points(upgrade)
	if _progression.get_total_levels() < required:
		return tr(&"UI_REQUIRES_POINTS") % required
	var missing: PackedStringArray = []
	for prerequisite: UpgradeNode in upgrade.prerequisites:
		if _progression.get_level(prerequisite.id) < 1:
			missing.append(tr(prerequisite.get_name_key()))
	if not missing.is_empty():
		return tr(&"UI_REQUIRES") % ", ".join(missing)
	return ""


func _clear_details() -> void:
	_details.hide()
	_buy_button.disabled = true


func _close_details() -> void:
	if _buy_button.has_focus():
		_buy_button.release_focus()
	_selected = null
	_tree_view.set_selected(null)
	_clear_details()


## Puts the popup beside the selected node: right of it, or left when it does not
## fit; vertically centred on the node and kept inside the tree area. Called once
## when it opens; scrolling then moves it with the node (_follow_node).
func _place_details() -> void:
	var view := _tree_view.get_view(_selected.id) if _selected else null
	if view == null:
		return
	_details.reset_size()
	var node_rect := view.get_global_rect()
	var popup := _details.size
	# Inside the tree area: never over the resources bar or the footer.
	var bounds := _scroll.get_global_rect()
	var x := node_rect.end.x + POPUP_GAP
	if x + popup.x > bounds.end.x:
		x = node_rect.position.x - POPUP_GAP - popup.x
	x = clampf(x, bounds.position.x, bounds.end.x - popup.x)
	var y := clampf(node_rect.get_center().y - popup.y / 2.0, bounds.position.y, bounds.end.y - popup.y)
	_popup_offset = Vector2(x, y).floor() - node_rect.position
	_follow_node()


## Keeps the popup at the same place relative to its node; hidden while the
## node is scrolled out of sight.
func _follow_node() -> void:
	var view := _tree_view.get_view(_selected.id) if _selected else null
	if view == null:
		return
	var node_rect := view.get_global_rect()
	_details.visible = _scroll.get_global_rect().encloses(node_rect)
	_details.global_position = node_rect.position + _popup_offset


func _on_background_pressed() -> void:
	_close_details()


func _on_scrolled() -> void:
	_follow_node()


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
	_details.hide()
	_save_indicator.dismiss()
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
	hide()
