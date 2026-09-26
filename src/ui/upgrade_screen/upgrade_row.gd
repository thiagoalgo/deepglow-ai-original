class_name UpgradeRow
extends HBoxContainer
## One upgrade line: name, level, next cost and buy button.

signal buy_requested(upgrade: UpgradeNode)
signal focused(upgrade: UpgradeNode)

var upgrade: UpgradeNode

var _name_label: Label
var _level_label: Label
var _costs: HBoxContainer
var _buy_button: Button


static func create(p_upgrade: UpgradeNode) -> UpgradeRow:
	var row := UpgradeRow.new()
	row.upgrade = p_upgrade
	row._build()
	return row


func refresh(progression: ProgressionState, inventory: Inventory) -> void:
	var level := progression.get_level(upgrade.id)
	_level_label.text = tr(&"UI_LEVEL") % [level, upgrade.max_level]
	for child: Node in _costs.get_children():
		child.queue_free()
	if progression.is_maxed(upgrade):
		_buy_button.text = tr(&"UI_MAXED")
		_buy_button.disabled = true
		return
	_buy_button.text = tr(&"UI_BUY")
	for cost: ResourceAmount in progression.get_next_cost(upgrade):
		var missing := inventory.get_amount(cost.resource.id) < cost.amount
		_costs.add_child(ResourceAmountView.create(cost.resource, str(cost.amount), missing))
	_buy_button.disabled = not progression.can_buy(upgrade, inventory)


func _build() -> void:
	add_theme_constant_override(&"separation", 4)
	_name_label = Label.new()
	_name_label.text = upgrade.get_name_key()
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.clip_text = true
	add_child(_name_label)
	_level_label = Label.new()
	_level_label.theme_type_variation = &"MutedLabel"
	_level_label.custom_minimum_size = Vector2(28, 0)
	add_child(_level_label)
	_costs = HBoxContainer.new()
	_costs.add_theme_constant_override(&"separation", 4)
	_costs.custom_minimum_size = Vector2(64, 0)
	add_child(_costs)
	_buy_button = Button.new()
	_buy_button.custom_minimum_size = Vector2(40, 0)
	_buy_button.pressed.connect(func() -> void: buy_requested.emit(upgrade))
	_buy_button.focus_entered.connect(func() -> void: focused.emit(upgrade))
	_buy_button.mouse_entered.connect(func() -> void: focused.emit(upgrade))
	add_child(_buy_button)
