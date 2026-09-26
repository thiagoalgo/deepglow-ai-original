extends RefCounted
## Smoke tests for the balance simulator (the full report is run manually,
## see AGENTS.md "Useful commands").

const Simulator := preload("res://tools/balance/balance_simulator.gd")


func _simulator() -> Object:
	var db := load("res://data/game_database.tres") as GameDatabase
	return Simulator.new(db, Vector2i(8, 8))


func test_average_player_completes_tree() -> String:
	var result: Object = _simulator().run(Simulator.Profile.new("average", 3.0), 1)
	if not result.get("completed"):
		return "tree not completed in %d phases" % result.get("phases")
	return ""


func test_simulation_is_deterministic() -> String:
	var sim: Object = _simulator()
	var profile := Simulator.Profile.new("average", 3.0)
	var a: Object = sim.run(profile, 42)
	var b: Object = sim.run(profile, 42)
	if a.get("phases") != b.get("phases") or a.get("seconds") != b.get("seconds"):
		return "same seed must give the same run"
	return ""
