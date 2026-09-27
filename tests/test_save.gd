extends RefCounted
## SaveGame / SaveSystem tests: a run survives a JSON round trip and old or
## broken saves are handled safely.

const DATABASE_PATH := "res://data/game_database.tres"
const TEST_PATH := "user://test_save.json"


func _db() -> GameDatabase:
	return load(DATABASE_PATH) as GameDatabase


## A small played run: some resources, one upgrade bought, two phases.
func _played_run(db: GameDatabase) -> Array:
	var inv := Inventory.new()
	var prog := ProgressionState.new(db)
	inv.add(&"wood", 500)
	inv.add(&"fruit", 7)
	inv.add(&"water", 3)
	inv.add(&"water", -3)  # discovered but empty
	if not prog.buy(db.get_upgrade(&"sharp_axe"), inv):
		return []
	prog.record_phase(120, 40.0)
	prog.record_phase(150, 40.0)
	return [inv, prog]


func test_round_trip_through_file() -> String:
	var db := _db()
	var run := _played_run(db)
	if run.is_empty():
		return "setup: could not buy sharp_axe"
	var inv: Inventory = run[0]
	var prog: ProgressionState = run[1]
	var err := SaveSystem.write(SaveGame.capture(12345, 2, inv, prog), TEST_PATH)
	if err != OK:
		return "write failed: %s" % error_string(err)
	var loaded := SaveSystem.read(TEST_PATH)
	SaveSystem.delete(TEST_PATH)
	if loaded == null:
		return "read returned null"
	if loaded.run_seed != 12345 or loaded.phase_number != 2:
		return "seed/phase mismatch: %d/%d" % [loaded.run_seed, loaded.phase_number]
	var inv2 := Inventory.new()
	var prog2 := ProgressionState.new(db)
	loaded.apply_to(inv2, prog2)
	for id: StringName in [&"wood", &"fruit", &"water"]:
		if inv2.get_amount(id) != inv.get_amount(id):
			return "amount mismatch for %s" % id
		if not inv2.is_discovered(id):
			return "%s should stay discovered" % id
	if prog2.get_level(&"sharp_axe") != 1:
		return "upgrade level lost"
	if prog2.phases_played != 2 or not is_equal_approx(prog2.measured_cps, prog.measured_cps):
		return "phase stats lost"
	return ""


func test_unknown_ids_are_dropped_and_levels_clamped() -> String:
	var db := _db()
	var axe := db.get_upgrade(&"sharp_axe")
	var data := {
		"version": SaveGame.VERSION,
		"run_seed": 1,
		"phase_number": 3,
		"inventory": {"amounts": {"wood": 10, "unobtainium": 99}, "discovered": ["wood", "unobtainium"]},
		"progression": {"levels": {"sharp_axe": 999, "removed_upgrade": 2}, "phases_played": 3, "measured_cps": 3.0},
	}
	var save := SaveGame.from_dict(data)
	if save == null:
		return "valid data rejected"
	var inv := Inventory.new()
	var prog := ProgressionState.new(db)
	save.apply_to(inv, prog)
	if inv.get_amount(&"unobtainium") != 0 or inv.is_discovered(&"unobtainium"):
		return "unknown resource kept"
	if inv.get_amount(&"wood") != 10:
		return "known resource lost"
	if prog.get_level(&"sharp_axe") != axe.max_level:
		return "level not clamped to max_level"
	if prog.get_levels().has(&"removed_upgrade"):
		return "unknown upgrade kept"
	return ""


func test_rejects_broken_and_newer_saves() -> String:
	if SaveGame.from_dict({}) != null:
		return "empty dict accepted"
	if SaveGame.from_dict({"version": SaveGame.VERSION + 1}) != null:
		return "newer version accepted"
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("{ not json")
	file.close()
	var loaded := SaveSystem.read(TEST_PATH)
	SaveSystem.delete(TEST_PATH)
	if loaded != null:
		return "broken file accepted"
	if SaveSystem.exists(TEST_PATH):
		return "delete failed"
	return ""
