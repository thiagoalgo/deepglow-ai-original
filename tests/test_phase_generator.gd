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


func test_budget_is_respected_and_filled() -> String:
	var prog := _prog()
	for s: int in 50:
		var plan := PhaseGenerator.generate(prog, BOARD, s)
		if plan.planned_clicks > plan.budget_clicks + 0.001 and plan.placements.size() > 4:
			return "seed %d over budget (%.1f > %.1f)" % [s, plan.planned_clicks, plan.budget_clicks]
		# The cheapest source fills the gap, so almost all the budget is used.
		if plan.planned_clicks < plan.budget_clicks - 3.0:
			return "seed %d leaves budget unused (%.1f of %.1f)" % [s, plan.planned_clicks, plan.budget_clicks]
	return ""


func test_timer_fits_player_speed() -> String:
	var rules := _prog().database.phase_rules
	for cps: float in [2.0, 3.0, 4.5]:
		var prog := _prog()
		prog.measured_cps = cps
		var plan := PhaseGenerator.generate(prog, BOARD, 99)
		var needed := plan.planned_clicks / cps
		var ratio := needed / plan.duration
		# Work/time ratio must stay inside the tightness range (±1 s of rounding).
		if ratio > rules.tightness_max + 0.05 or ratio < rules.tightness_min - 0.05:
			return "cps %.1f: work/time %.2f outside tightness range" % [cps, ratio]
	return ""


func test_content_is_independent_of_speed() -> String:
	var slow := _prog()
	slow.measured_cps = 2.0
	var fast := _prog()
	fast.measured_cps = 5.0
	var a := PhaseGenerator.generate(slow, BOARD, 5)
	var b := PhaseGenerator.generate(fast, BOARD, 5)
	if a.placements.size() != b.placements.size() or a.planned_clicks != b.planned_clicks:
		return "content should not depend on player speed"
	if b.duration >= a.duration:
		return "faster player should get a shorter timer"
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
	var rules := prog.database.phase_rules
	var original := rules.reference_cps
	rules.reference_cps = 100.0  # absurd content budget
	var plan := PhaseGenerator.generate(prog, BOARD, 7)
	rules.reference_cps = original
	var limit := floori(BOARD.x * BOARD.y * rules.max_board_fill)
	if plan.placements.size() > limit:
		return "%d sources > limit %d" % [plan.placements.size(), limit]
	return ""
