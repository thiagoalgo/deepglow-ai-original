class_name UpgradeScreen
extends Control
## Between-phase upgrade tree (list form for M1). Shows available upgrades,
## their next cost and lets the player buy them, then start the next phase.

signal start_requested

var _progression: ProgressionState
var _inventory: Inventory
var _database: GameDatabase
var _rows: Array[UpgradeRow] = []

@onready var _inventory_bar: HBoxContainer = %InventoryBar
@onready var _rows_list: VBoxContainer = %Rows
@onready var _description: Label = %Description
@onready var _start_button: Button = %StartButton


func _ready() -> void:
	hide()
	_start_button.pressed.connect(_on_start_pressed)


func open(database: GameDatabase, progression: ProgressionState, inventory: Inventory,
		next_phase: int) -> void:
	_database = database
	_progression = progression
	_inventory = inventory
	_start_button.text = tr(&"UI_START_PHASE") % next_phase
	_description.text = ""
	_rebuild()
	show()
	_start_button.grab_focus.call_deferred()


func _rebuild() -> void:
	for child: Node in _inventory_bar.get_children():
		child.queue_free()
	for resource: ResourceType in _database.resources:
		_inventory_bar.add_child(ResourceAmountView.create(resource, str(_inventory.get_amount(resource.id))))
	for row: UpgradeRow in _rows:
		row.queue_free()
	_rows.clear()
	for upgrade: UpgradeNode in _database.upgrades:
		# Show owned/maxed and currently available upgrades; hide locked ones.
		if not _progression.is_available(upgrade) and _progression.get_level(upgrade.id) == 0:
			continue
		var row := UpgradeRow.create(upgrade)
		row.buy_requested.connect(_on_buy_requested)
		row.focused.connect(_on_row_focused)
		_rows_list.add_child(row)
		row.refresh(_progression, _inventory)
		_rows.append(row)


func _on_buy_requested(upgrade: UpgradeNode) -> void:
	if _progression.buy(upgrade, _inventory):
		_rebuild()
		_description.text = tr(upgrade.get_desc_key())


func _on_row_focused(upgrade: UpgradeNode) -> void:
	_description.text = tr(upgrade.get_desc_key())


func _on_start_pressed() -> void:
	hide()
	start_requested.emit()
