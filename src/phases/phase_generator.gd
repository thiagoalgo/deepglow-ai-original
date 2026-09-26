class_name PhaseGenerator
extends RefCounted
## Builds a phase from the current progression (docs/game-design.md §6).
## Pure and deterministic for a given seed: shared by the game, tests and
## the balance simulator.

const MAX_PICK_ATTEMPTS := 12


static func generate(progression: ProgressionState, board_size: Vector2i, phase_seed: int) -> PhasePlan:
	var database := progression.database
	var rules := database.phase_rules
	var rng := RandomNumberGenerator.new()
	rng.seed = phase_seed

	var plan := PhasePlan.new()
	plan.phase_seed = phase_seed
	plan.duration = progression.get_phase_duration()
	plan.capacity_clicks = plan.duration * progression.measured_cps
	plan.budget_clicks = plan.capacity_clicks * rng.randf_range(rules.tightness_min, rules.tightness_max)

	var available := _available_sources(progression)
	if available.is_empty():
		return plan
	var max_sources := floori(board_size.x * board_size.y * rules.max_board_fill)
	var picked: Array[SourceType] = []

	# 1. Guarantees: minimum food and drink so the needs bars can be refilled.
	_pick_guaranteed(picked, available, ResourceType.Category.FOOD, rules.min_food_sources, progression, rng)
	_pick_guaranteed(picked, available, ResourceType.Category.DRINK, rules.min_drink_sources, progression, rng)
	for source: SourceType in picked:
		plan.planned_clicks += _cost(source, progression)

	# 2. Fill the click budget by rarity weight.
	while picked.size() < max_sources:
		var source := _pick_within_budget(available, plan.budget_clicks - plan.planned_clicks, progression, rng)
		if source == null:
			break
		picked.append(source)
		plan.planned_clicks += _cost(source, progression)

	# 3. Scatter on random free cells.
	var cells: Array[Vector2i] = []
	for y: int in board_size.y:
		for x: int in board_size.x:
			cells.append(Vector2i(x, y))
	_shuffle(cells, rng)
	for i: int in picked.size():
		plan.placements[cells[i]] = picked[i]
	return plan


## Click-equivalent cost of a source: effective clicks + mouse travel.
static func _cost(source: SourceType, progression: ProgressionState) -> float:
	return progression.get_effective_clicks(source) + progression.database.phase_rules.move_overhead_clicks


static func _available_sources(progression: ProgressionState) -> Array[SourceType]:
	var result: Array[SourceType] = []
	for source: SourceType in progression.database.sources:
		if progression.is_tool_unlocked(source.tool):
			result.append(source)
	return result


static func _pick_guaranteed(picked: Array[SourceType], available: Array[SourceType],
		category: ResourceType.Category, count: int, progression: ProgressionState,
		rng: RandomNumberGenerator) -> void:
	var candidates := available.filter(
		func(s: SourceType) -> bool: return s.yield_resource.category == category)
	var typed: Array[SourceType] = []
	typed.assign(candidates)
	for i: int in count:
		var source := _weighted_pick(typed, progression, rng)
		if source:
			picked.append(source)


static func _pick_within_budget(available: Array[SourceType], remaining: float,
		progression: ProgressionState, rng: RandomNumberGenerator) -> SourceType:
	for attempt: int in MAX_PICK_ATTEMPTS:
		var source := _weighted_pick(available, progression, rng)
		if source and _cost(source, progression) <= remaining:
			return source
	# Last resort: cheapest source that still fits (keeps phases tight).
	var cheapest: SourceType = null
	for source: SourceType in available:
		var cost := _cost(source, progression)
		if cost <= remaining and (cheapest == null or cost < _cost(cheapest, progression)):
			cheapest = source
	return cheapest


static func _weighted_pick(sources: Array[SourceType], progression: ProgressionState,
		rng: RandomNumberGenerator) -> SourceType:
	var total := 0.0
	for source: SourceType in sources:
		total += progression.get_rarity_weight(source.rarity)
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	for source: SourceType in sources:
		roll -= progression.get_rarity_weight(source.rarity)
		if roll <= 0.0:
			return source
	return sources.back()


static func _shuffle(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i: int in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := cells[i]
		cells[i] = cells[j]
		cells[j] = tmp
