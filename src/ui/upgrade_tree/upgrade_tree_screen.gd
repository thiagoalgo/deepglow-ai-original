class_name UpgradeTreeScreen
extends Control
## Between-phase upgrade tree (docs/game-design.md §7.1). Hover/focus a node
## to see its details; buy with the Buy button or by clicking the node again.

signal start_requested

var _database: GameDatabase
var _progression: ProgressionState
var _inventory: Inventory
var _selected: UpgradeNode

@onready var _inventory_bar: HBoxContainer = %InventoryBar
@onready var _tree_view: UpgradeTreeView = %TreeView
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _description: Label = %Description
@onready var _costs: HBoxContainer = %Costs
@onready var _status_label: Label = %StatusLabel
@onready var _buy_button: Button = %BuyButton
@onready var _start_button: Button = %StartButton


func _ready() -> void:
	hide()
	_tree_view.node_focused.connect(_select)
	_tree_view.node_pressed.connect(_on_node_pressed)
	_buy_button.pressed.connect(_buy_selected)
	_start_button.pressed.connect(_on_start_pressed)


func open(database: GameDatabase, progression: ProgressionState, inventory: Inventory,
		next_phase: int) -> void:
	_database = database
	_progression = progression
	_inventory = inventory
	_start_button.text = tr(&"UI_START_PHASE") % next_phase
	_tree_view.build(database)
	_refresh()
	show()
	_tree_view.focus_first_affordable.call_deferred()


func _refresh() -> void:
	for child: Node in _inventory_bar.get_children():
		child.queue_free()
	for resource: ResourceType in _database.resources:
		_inventory_bar.add_child(ResourceAmountView.create(resource, str(_inventory.get_amount(resource.id))))
	_tree_view.refresh(_progression, _inventory)
	if _selected:
		_select(_selected)
	else:
		_clear_details()


func _select(upgrade: UpgradeNode) -> void:
	_selected = upgrade
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
		_costs.add_child(ResourceAmountView.create(cost.resource, str(cost.amount), missing))
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
	_description.text = ""
	_status_label.text = ""
	_buy_button.disabled = true


func _on_node_pressed(upgrade: UpgradeNode) -> void:
	if upgrade == _selected:
		_buy_selected()
	else:
		_select(upgrade)


func _buy_selected() -> void:
	if _selected and _progression.buy(_selected, _inventory):
		_refresh()


func _on_start_pressed() -> void:
	hide()
	start_requested.emit()
