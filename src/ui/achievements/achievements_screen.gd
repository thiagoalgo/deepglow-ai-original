class_name AchievementsScreen
extends Control
## "My achievements" (title menu): the milestone achievements and one badge per
## upgrade of the tree (earned by taking it to its max level), unlocked or not.
## Hovering/focusing a badge shows its name and how to get it. Kept across runs
## (AchievementStore). Back / cancel returns to the title menu.

signal closed

@export var database: GameDatabase

var _store := AchievementStore.new()

@onready var _achievements_label: Label = %AchievementsLabel
@onready var _achievements_grid: GridContainer = %AchievementsGrid
@onready var _badges_label: Label = %BadgesLabel
@onready var _badges_grid: GridContainer = %BadgesGrid
@onready var _name_label: Label = %NameLabel
@onready var _desc_label: Label = %DescLabel
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(closed.emit)
	var got := 0
	for achievement: Achievement in database.achievements:
		var unlocked := _store.has_achievement(achievement.id)
		got += int(unlocked)
		var badge := BadgeView.create(achievement.icon, Palette.LIGHT_AMBER, unlocked)
		_connect_details(badge, tr(achievement.get_name_key()), tr(achievement.get_desc_key()), unlocked,
			Palette.LIGHT_AMBER)
		_achievements_grid.add_child(badge)
	_achievements_label.text = tr(&"UI_ACHIEVEMENTS_SECTION") % [got, database.achievements.size()]
	got = 0
	for upgrade: UpgradeNode in _upgrades_in_tree_order():
		var unlocked := _store.has_badge(upgrade.id)
		got += int(unlocked)
		var color := _biome_color(upgrade)
		var badge := BadgeView.create(upgrade.icon, color, unlocked)
		var title := tr(upgrade.get_name_key())
		var how := tr(&"UI_BADGE_HOW_ONE") % title if upgrade.max_level == 1 \
			else tr(&"UI_BADGE_HOW") % [title, upgrade.max_level]
		_connect_details(badge, title, how, unlocked, color)
		_badges_grid.add_child(badge)
	_badges_label.text = tr(&"UI_BADGES_SECTION") % [got, database.upgrades.size()]
	_show_details("", "", false, Palette.STRUCTURE_HIGHLIGHT)
	_back_button.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"cancel"):
		closed.emit()
		get_viewport().set_input_as_handled()


## Badges in the order of the tree: biome by biome, left to right, top to bottom.
func _upgrades_in_tree_order() -> Array[UpgradeNode]:
	var upgrades: Array[UpgradeNode] = database.upgrades.duplicate()
	upgrades.sort_custom(func(a: UpgradeNode, b: UpgradeNode) -> bool:
		if a.grid_position.y != b.grid_position.y:
			return a.grid_position.y < b.grid_position.y
		return a.grid_position.x < b.grid_position.x)
	return upgrades


## Accent color of the biome the upgrade belongs to (same as its tree column).
func _biome_color(upgrade: UpgradeNode) -> Color:
	var color := Palette.STRUCTURE_HIGHLIGHT
	for biome: Biome in database.biomes:
		if upgrade.grid_position.y >= biome.tree_row:
			color = biome.color
	return color


func _connect_details(badge: BadgeView, title: String, how: String, unlocked: bool, color: Color) -> void:
	var show_details := _show_details.bind(title, how, unlocked, color)
	badge.focus_entered.connect(show_details)
	badge.mouse_entered.connect(show_details)


func _show_details(title: String, how: String, unlocked: bool, color: Color) -> void:
	if title.is_empty():
		_name_label.text = ""
		_desc_label.text = ""
		return
	var state := tr(&"UI_UNLOCKED") if unlocked else tr(&"UI_LOCKED")
	_name_label.text = "%s · %s" % [title, state]
	_name_label.add_theme_color_override(&"font_color", color if unlocked else Palette.STRUCTURE_MID_BLUE)
	_desc_label.text = how
