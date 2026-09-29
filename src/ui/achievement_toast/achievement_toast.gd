class_name AchievementToast
extends CanvasLayer
## "Achievement unlocked!" / "Badge earned!" notice (top centre) for every new
## unlock (Events.achievement_unlocked), one after the other. Appears and
## disappears in one step (no alpha fades: pixel-art rule). Many unlocks at once
## (e.g. loading an old save) become a single summary notice.

## Seconds each notice stays on screen.
@export var show_time: float = 2.6
## More unlocks than this in the same frame = one summary notice.
@export var max_single: int = 3
@export var database: GameDatabase

var _queue: Array[Dictionary] = []
## Unlocks of the current frame, not queued yet.
var _batch: Array[Dictionary] = []
var _showing: bool = false

@onready var _panel: PanelContainer = %Panel
@onready var _slot: Control = %BadgeSlot
@onready var _title: Label = %Title
@onready var _name: Label = %Name


func _ready() -> void:
	_panel.hide()
	Events.achievement_unlocked.connect(_on_achievement_unlocked)


func _on_achievement_unlocked(badge: bool, id: StringName) -> void:
	if _batch.is_empty():
		_flush_batch.call_deferred()
	_batch.append({"badge": badge, "id": id})


func _flush_batch() -> void:
	if _batch.size() > max_single:
		_queue.append({"summary": _batch.size()})
	else:
		_queue.append_array(_batch)
	_batch.clear()
	if not _showing:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		_panel.hide()
		return
	_showing = true
	var item: Dictionary = _queue.pop_front()
	for child: Node in _slot.get_children():
		child.queue_free()
	var badge_view: BadgeView
	if item.has("summary"):
		badge_view = BadgeView.create(load("res://assets/sprites/icons/crystal.png") as Texture2D,
			Palette.LIGHT_AMBER, true)
		_title.text = tr(&"UI_ACHIEVEMENT_UNLOCKED")
		_name.text = tr(&"UI_UNLOCKED_MANY") % item["summary"]
	elif item["badge"]:
		var upgrade := database.get_upgrade(item["id"])
		badge_view = BadgeView.create(upgrade.icon, _biome_color(upgrade), true)
		_title.text = tr(&"UI_BADGE_UNLOCKED")
		_name.text = tr(upgrade.get_name_key())
	else:
		var achievement := _find_achievement(item["id"])
		badge_view = BadgeView.create(achievement.icon, Palette.LIGHT_AMBER, true)
		_title.text = tr(&"UI_ACHIEVEMENT_UNLOCKED")
		_name.text = tr(achievement.get_name_key())
	badge_view.focus_mode = Control.FOCUS_NONE
	badge_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot.add_child(badge_view)
	_panel.show()
	_panel.reset_size()
	_panel.position.x = floorf((_panel.get_viewport_rect().size.x - _panel.size.x) / 2.0)
	Sound.play_ui(&"ui_click")
	get_tree().create_timer(show_time).timeout.connect(_show_next)


func _find_achievement(id: StringName) -> Achievement:
	for achievement: Achievement in database.achievements:
		if achievement.id == id:
			return achievement
	return null


func _biome_color(upgrade: UpgradeNode) -> Color:
	var color := Palette.STRUCTURE_HIGHLIGHT
	for biome: Biome in database.biomes:
		if upgrade.grid_position.y >= biome.tree_row:
			color = biome.color
	return color
