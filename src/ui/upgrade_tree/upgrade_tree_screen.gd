class_name UpgradeTreeScreen
extends Control
## Between-phase upgrade tree (docs/game-design.md §7.1). Clicking (or focusing
## with the keyboard) a node only selects it and shows its details; buying is
## always an explicit press of the Buy button. The screen opens with nothing selected.

signal start_requested
## "Menu" pressed: back to the title menu (the run is saved on every change).
signal menu_requested

var _database: GameDatabase
var _progression: ProgressionState
var _inventory: Inventory
var _selected: UpgradeNode

@onready var _inventory_bar: HFlowContainer = %InventoryBar
@onready var _tree_view: UpgradeTreeView = %TreeView
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _description: Label = %Description
@onready var _costs: HBoxContainer = %Costs
@onready var _status_label: Label = %StatusLabel
@onready var _buy_button: Button = %BuyButton
@onready var _start_button: Button = %StartButton
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	hide()
	_tree_view.node_focused.connect(_select)
	_tree_view.node_pressed.connect(_select)
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
	_refresh()
	show()


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


func _on_start_pressed() -> void:
	_close()
	start_requested.emit()


func _on_menu_pressed() -> void:
	_close()
	menu_requested.emit()


func _close() -> void:
	_selected = null
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
	hide()
