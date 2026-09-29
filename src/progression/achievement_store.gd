class_name AchievementStore
extends RefCounted
## What the player has unlocked across ALL runs (starting a new game keeps it):
## milestone achievements (Achievement) and badges (one per upgrade taken to its
## max level). Stored in user://achievements.cfg, separate from the run save,
## as `id = unix time of the unlock` in the [achievements] and [badges] sections.

const SAVE_PATH := "user://achievements.cfg"
const ACHIEVEMENTS := "achievements"
const BADGES := "badges"

var _path: String
var _config := ConfigFile.new()


func _init(path: String = SAVE_PATH) -> void:
	_path = path
	_config.load(_path)


func has_achievement(id: StringName) -> bool:
	return _config.has_section_key(ACHIEVEMENTS, String(id))


func has_badge(upgrade_id: StringName) -> bool:
	return _config.has_section_key(BADGES, String(upgrade_id))


func count(section: String) -> int:
	return _config.get_section_keys(section).size() if _config.has_section(section) else 0


## Unlocks everything the run has earned and saves. Returns only the NEW
## unlocks, as {"badge": bool, "id": StringName} (for the "unlocked!" toast).
func update(database: GameDatabase, progression: ProgressionState) -> Array[Dictionary]:
	var unlocked: Array[Dictionary] = []
	var now := int(Time.get_unix_time_from_system())
	for achievement: Achievement in database.achievements:
		if achievement.is_unlocked(progression) and not has_achievement(achievement.id):
			_config.set_value(ACHIEVEMENTS, String(achievement.id), now)
			unlocked.append({"badge": false, "id": achievement.id})
	for upgrade: UpgradeNode in database.upgrades:
		if progression.is_maxed(upgrade) and not has_badge(upgrade.id):
			_config.set_value(BADGES, String(upgrade.id), now)
			unlocked.append({"badge": true, "id": upgrade.id})
	if not unlocked.is_empty():
		_config.save(_path)
	return unlocked


## Forgets everything (dev console: clear_achievements).
func clear() -> void:
	_config = ConfigFile.new()
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path))
