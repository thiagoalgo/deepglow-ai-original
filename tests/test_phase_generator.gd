extends RefCounted
## PhaseGenerator tests: budget, guarantees, determinism, unlock filtering.

const DATABASE_PATH := "res://data/game_database.tres"
const BOARD := Vector2i(8, 8)


func _prog() -> ProgressionState:
	return ProgressionState.new(load(DATABASE_PATH) as GameDatabase)


func test_deterministic_for_same_seed() -> String:
	var prog := _prog()
	var a := PhaseGenerator.generate(prog, BOARD, 1234)
	var b := PhaseGenerator.generate(prog, BOARD, 1234)
	if a.placements.size() != b.placements.size():
		return "sizes differ"
	for cell: Vector2i in a.placements:
		if b.placements.get(cell) != a.placements[cell]:
			return "placement differs at %s" % cell
	return ""


func test_budget_is_respected_and_tight() -> String:
	var prog := _prog()
	for s: int in 50:
		var plan := PhaseGenerator.generate(prog, BOARD, s)
		if plan.planned_clicks > plan.budget_clicks + 0.001 and plan.placements.size() > 4:
			return "seed %d over budget (%.1f > %.1f)" % [s, plan.planned_clicks, plan.budget_clicks]
		# Tight: the plan should use most of the budget (cheapest source fills the gap).
		if plan.planned_clicks < plan.budget_clicks - 3.0:
			return "seed %d leaves budget unused (%.1f of %.1f)" % [s, plan.planned_clicks, plan.budget_clicks]
		if plan.budget_clicks < plan.capacity_clicks:
			return "budget below capacity"
	return ""


func test_guarantees_food_and_drink() -> String:
	var prog := _prog()
	var rules := prog.database.phase_rules
	for s: int in 30:
		var plan := PhaseGenerator.generate(prog, BOARD, s)
		var food := 0
		var drink := 0
		for cell: Vector2i in plan.placements:
			var category := plan.placements[cell].yield_resource.category
			food += 1 if category == ResourceType.Category.FOOD else 0
			drink += 1 if category == ResourceType.Category.DRINK else 0
		if food < rules.min_food_sources or drink < rules.min_drink_sources:
			return "seed %d: food %d drink %d" % [s, food, drink]
	return ""


func test_respects_board_fill_limit() -> String:
	var prog := _prog()
	prog.measured_cps = 100.0  # absurd capacity
	var plan := PhaseGenerator.generate(prog, BOARD, 7)
	var limit := floori(BOARD.x * BOARD.y * prog.database.phase_rules.max_board_fill)
	if plan.placements.size() > limit:
		return "%d sources > limit %d" % [plan.placements.size(), limit]
	return ""
