extends RefCounted
## Headless balance simulator (docs/game-design.md §8).
##
## Plays full runs with a simulated player using the REAL game code
## (ProgressionState, PhaseGenerator, Inventory, Needs) and the real data
## (data/game_database.tres), so numbers never drift from the game.
## Load it with preload(); it intentionally has no class_name.

## Simulated player profile.
class Profile:
	var name: String
	## True click-equivalents per second (clicks + mouse travel).
	var cps: float
	## Seconds spent between phases (summary + upgrade screen).
	var between_phases: float = 15.0
	## Eat/drink when a bar drops below this. 0 = "careless" player who
	## ignores the bars and goes for materials (wood) first.
	var needs_threshold: float = 0.35

	func _init(p_name: String, p_cps: float) -> void:
		name = p_name
		cps = p_cps


## Result of one simulated run.
class RunResult:
	var profile: String
	var run_seed: int
	var completed: bool = false
	var phases: int = 0
	## Total wall-clock seconds (phases + between-phase time).
	var seconds: float = 0.0
	## upgrade id -> seconds when its first level was bought.
	var first_purchase: Dictionary[StringName, float] = {}
	## upgrade id -> seconds when it was maxed.
	var maxed_at: Dictionary[StringName, float] = {}
	var phases_cleared: int = 0
	var sources_per_phase: Array[int] = []
	var income_per_phase: Array[int] = []
	## Share (0..1) of each phase's income that the remaining upgrades still needed.
	var useful_share_per_phase: Array[float] = []
	var starving_seconds: float = 0.0
	## Phase number of the first purchase.
	var first_upgrade_phase: int = -1


const MAX_PHASES := 2000

var database: GameDatabase
var board_size: Vector2i


func _init(p_database: GameDatabase, p_board_size: Vector2i) -> void:
	database = p_database
	board_size = p_board_size


func run(profile: Profile, run_seed: int) -> RunResult:
	var result := RunResult.new()
	result.profile = profile.name
	result.run_seed = run_seed
	var progression := ProgressionState.new(database)
	var inventory := Inventory.new()
	var needs := Needs.new()

	while result.phases < MAX_PHASES:
		result.phases += 1
		var plan := PhaseGenerator.generate(progression, board_size, hash([run_seed, result.phases]), inventory)
		var need := progression.get_remaining_need(inventory)
		var before: Dictionary[StringName, int] = {}
		for resource: ResourceType in database.resources:
			before[resource.id] = inventory.get_amount(resource.id)
		var phase := _play_phase(plan, profile, progression, inventory, needs, result)
		var gained := 0
		var useful := 0
		for resource: ResourceType in database.resources:
			var delta := inventory.get_amount(resource.id) - before[resource.id]
			gained += delta
			useful += mini(delta, need.get(resource.id, 0))
		result.useful_share_per_phase.append(float(useful) / maxf(1.0, float(gained)))
		progression.record_phase(phase["click_equivalents"], phase["elapsed"])
		result.seconds += phase["elapsed"] + profile.between_phases
		result.sources_per_phase.append(plan.placements.size())
		result.income_per_phase.append(phase["income"])
		if phase["cleared"]:
			result.phases_cleared += 1
		_buy_upgrades(progression, inventory, result)
		if _tree_complete(progression):
			result.completed = true
			break
	return result


# --- Phase ---------------------------------------------------------------------

func _play_phase(plan: PhasePlan, profile: Profile, progression: ProgressionState,
		inventory: Inventory, needs: Needs, result: RunResult) -> Dictionary:
	var rules := database.phase_rules
	var remaining: Array[SourceType] = []
	remaining.assign(plan.placements.values())
	needs.reset()
	var time := 0.0
	var click_equivalents := 0.0
	var income := 0
	var hunger_rate := progression.get_hunger_drain()
	var thirst_rate := progression.get_thirst_drain()

	while not remaining.is_empty():
		var source := _choose(remaining, needs, profile, progression)
		var factor := needs.get_click_factor(rules.starving_click_factor)
		var clicks := ceilf(progression.get_effective_clicks(source) / factor)
		var cost := clicks + rules.move_overhead_clicks
		var duration := cost / profile.cps
		if time + duration > plan.duration:
			# Out of time: partial work on this source is lost.
			click_equivalents += (plan.duration - time) * profile.cps
			_drain(needs, plan.duration - time, hunger_rate, thirst_rate, result)
			time = plan.duration
			break
		_drain(needs, duration, hunger_rate, thirst_rate, result)
		time += duration
		click_equivalents += cost
		var amount := progression.get_yield(source)
		var resource := source.yield_resource
		inventory.add(resource.id, amount)
		needs.restore(resource.hunger_restore * amount, resource.thirst_restore * amount)
		income += amount
		remaining.erase(source)

	return {
		"elapsed": time,
		"click_equivalents": roundi(click_equivalents),
		"income": income,
		"cleared": remaining.is_empty(),
	}


func _drain(needs: Needs, seconds: float, hunger_rate: float, thirst_rate: float,
		result: RunResult) -> void:
	var was_starving := needs.is_starving()
	needs.drain(seconds, hunger_rate, thirst_rate)
	if was_starving or needs.is_starving():
		result.starving_seconds += seconds


## Player heuristic: refill a low bar first, otherwise best yield per click.
func _choose(remaining: Array[SourceType], needs: Needs, profile: Profile,
		progression: ProgressionState) -> SourceType:
	var wanted := -1
	if needs.thirst < profile.needs_threshold:
		wanted = ResourceType.Category.DRINK
	elif needs.hunger < profile.needs_threshold:
		wanted = ResourceType.Category.FOOD
	var best: SourceType = null
	var best_score := -1.0
	for source: SourceType in remaining:
		var score := float(progression.get_yield(source)) / (progression.get_effective_clicks(source)
			+ database.phase_rules.move_overhead_clicks)
		if wanted != -1 and source.yield_resource.category == wanted:
			score += 1000.0
		elif profile.needs_threshold <= 0.0 and source.yield_resource.category == ResourceType.Category.MATERIAL:
			score += 100.0
		if score > best_score:
			best_score = score
			best = source
	return best


# --- Purchases -----------------------------------------------------------------

## Greedy: keep buying the cheapest affordable upgrade (total resource units).
func _buy_upgrades(progression: ProgressionState, inventory: Inventory, result: RunResult) -> void:
	while true:
		var best: UpgradeNode = null
		var best_cost := INF
		for upgrade: UpgradeNode in database.upgrades:
			if not progression.can_buy(upgrade, inventory):
				continue
			var total := 0
			for cost: ResourceAmount in progression.get_next_cost(upgrade):
				total += cost.amount
			if total < best_cost:
				best_cost = total
				best = upgrade
		if best == null:
			return
		progression.buy(best, inventory)
		if not result.first_purchase.has(best.id):
			result.first_purchase[best.id] = result.seconds
		if result.first_upgrade_phase == -1:
			result.first_upgrade_phase = result.phases
		if progression.is_maxed(best):
			result.maxed_at[best.id] = result.seconds


func _tree_complete(progression: ProgressionState) -> bool:
	for upgrade: UpgradeNode in database.upgrades:
		if progression.is_maxed(upgrade):
			continue
		# Nodes blocked by a choice made elsewhere count as done.
		if progression.is_blocked_by_choice(upgrade):
			continue
		return false
	return true
