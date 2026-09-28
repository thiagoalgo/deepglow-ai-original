class_name Hud
extends CanvasLayer
## Phase HUD: phase number, clock timer, needs and inventory.
## Configured by Game via setup(); updates come from Events.

const LOW_TIME := 10.0
## Icon shake when a bar empties: offsets in pixels, one per step.
const SHAKE_OFFSETS: PackedFloat32Array = [-2.0, 2.0, -2.0, 2.0, -1.0, 1.0, 0.0]
const SHAKE_STEP := 0.05
## Seconds the "new biome" banner stays on screen.
const BIOME_BANNER_TIME := 2.5

var _counters: Dictionary[StringName, Label] = {}
var _phase_duration: float = 1.0

@onready var _phase_label: Label = %PhaseLabel
@onready var _time_label: Label = %TimeLabel
@onready var _clock: ClockTimer = %Clock
@onready var _hunger_bar: NeedBar = %HungerBar
@onready var _thirst_bar: NeedBar = %ThirstBar
@onready var _hunger_label: Label = %HungerLabel
@onready var _thirst_label: Label = %ThirstLabel
@onready var _hunger_icon: TextureRect = %HungerIcon
@onready var _thirst_icon: TextureRect = %ThirstIcon
@onready var _inventory_list: GridContainer = %InventoryList
@onready var _biome_banner: Control = %BiomeBanner
@onready var _biome_name: Label = %BiomeName

var _banner_tween: Tween


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


## Announces a newly reached biome over the board for a moment.
func show_biome_banner(biome: Biome) -> void:
	_biome_name.text = biome.get_name_key()
	_biome_banner.show()
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_interval(BIOME_BANNER_TIME)
	_banner_tween.tween_callback(_biome_banner.hide)


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
	_show_need_state(_hunger_label, _hunger_icon, hunger <= 0.0, &"HUD_HUNGER", &"HUD_HUNGER_EMPTY")
	_show_need_state(_thirst_label, _thirst_icon, thirst <= 0.0, &"HUD_THIRST", &"HUD_THIRST_EMPTY")


## An empty bar's label names its penalty (alert color); the icon shakes once
## when the bar empties.
func _show_need_state(label: Label, icon: TextureRect, empty: bool, key: StringName,
		empty_key: StringName) -> void:
	var text_key := empty_key if empty else key
	if label.text == text_key:
		return
	label.text = text_key
	label.theme_type_variation = &"AlertLabel" if empty else &""
	if empty:
		var base_x := icon.position.x
		var tween := icon.create_tween()
		for offset: float in SHAKE_OFFSETS:
			tween.tween_property(icon, ^"position:x", base_x + offset, SHAKE_STEP)


func _on_inventory_changed(resource_id: StringName, amount: int) -> void:
	if _counters.has(resource_id):
		var label := _counters[resource_id]
		label.text = NumberFormat.compact(amount)
		if amount > 0:
			(label.get_parent() as Control).show()
