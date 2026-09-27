class_name Hud
extends CanvasLayer
## Phase HUD: phase number, clock timer, needs and inventory.
## Configured by Game via setup(); updates come from Events.

const LOW_TIME := 10.0

var _counters: Dictionary[StringName, Label] = {}
var _phase_duration: float = 1.0

@onready var _phase_label: Label = %PhaseLabel
@onready var _time_label: Label = %TimeLabel
@onready var _clock: ClockTimer = %Clock
@onready var _hunger_bar: NeedBar = %HungerBar
@onready var _thirst_bar: NeedBar = %ThirstBar
@onready var _inventory_list: GridContainer = %InventoryList


func _ready() -> void:
	Events.phase_started.connect(_on_phase_started)
	Events.phase_time_changed.connect(_on_phase_time_changed)
	Events.needs_changed.connect(_on_needs_changed)
	Events.inventory_changed.connect(_on_inventory_changed)
	_phase_label.text = ""
	_time_label.text = ""


func setup(database: GameDatabase, inventory: Inventory) -> void:
	for child: Node in _inventory_list.get_children():
		child.queue_free()
	_counters.clear()
	for resource: ResourceType in database.resources:
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 4)
		var icon := TextureRect.new()
		icon.texture = resource.icon
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		row.add_child(icon)
		var label := Label.new()
		label.text = NumberFormat.compact(inventory.get_amount(resource.id))
		row.add_child(label)
		# Rows appear once the resource is first collected (keeps the HUD short).
		row.visible = inventory.is_discovered(resource.id)
		_inventory_list.add_child(row)
		_counters[resource.id] = label


func _on_phase_started(phase_number: int, duration: float) -> void:
	_phase_label.text = tr(&"HUD_PHASE") % phase_number
	_phase_duration = maxf(duration, 0.001)
	_on_phase_time_changed(duration)


func _on_phase_time_changed(time_left: float) -> void:
	_time_label.text = str(ceili(time_left))
	var low := time_left <= LOW_TIME
	_time_label.theme_type_variation = &"AlertTitleLabel" if low else &"TitleLabel"
	_clock.value = time_left / _phase_duration
	_clock.alert = low


func _on_needs_changed(hunger: float, thirst: float) -> void:
	_hunger_bar.value = hunger
	_thirst_bar.value = thirst


func _on_inventory_changed(resource_id: StringName, amount: int) -> void:
	if _counters.has(resource_id):
		var label := _counters[resource_id]
		label.text = NumberFormat.compact(amount)
		if amount > 0:
			(label.get_parent() as Control).show()
