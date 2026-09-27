extends RefCounted
## Achievement data and rules.

const DATABASE_PATH := "res://data/game_database.tres"


func _db() -> GameDatabase:
	return load(DATABASE_PATH) as GameDatabase


func test_ids_are_unique_and_targets_exist() -> String:
	var db := _db()
	if db.achievements.is_empty():
		return "no achievements in the database"
	var seen: Dictionary[StringName, bool] = {}
	for achievement: Achievement in db.achievements:
		if seen.has(achievement.id):
			return "duplicate id %s" % achievement.id
		seen[achievement.id] = true
		if not String(achievement.id).begins_with("ACH_"):
			return "%s should start with ACH_ (Steam API name)" % achievement.id
		if achievement.kind == Achievement.Kind.UPGRADE_OWNED and db.get_upgrade(achievement.target) == null:
			return "%s targets missing upgrade %s" % [achievement.id, achievement.target]
	return ""


func test_unlock_rules() -> String:
	var db := _db()
	var prog := ProgressionState.new(db)
	var phases := Achievement.new()
	phases.kind = Achievement.Kind.PHASES_PLAYED
	phases.amount = 2
	var owned := Achievement.new()
	owned.kind = Achievement.Kind.UPGRADE_OWNED
	owned.target = &"sharp_axe"
	var levels := Achievement.new()
	levels.kind = Achievement.Kind.TOTAL_LEVELS
	levels.amount = 1
	if phases.is_unlocked(prog) or owned.is_unlocked(prog) or levels.is_unlocked(prog):
		return "nothing should be unlocked at the start"
	prog.record_phase(10, 10.0)
	prog.record_phase(10, 10.0)
	var inv := Inventory.new()
	inv.add(&"wood", 1000)
	prog.buy(db.get_upgrade(&"sharp_axe"), inv)
	if not (phases.is_unlocked(prog) and owned.is_unlocked(prog) and levels.is_unlocked(prog)):
		return "all three should be unlocked"
	return ""
