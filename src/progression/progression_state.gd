class_name ProgressionState
extends RefCounted
## Long-term progress: upgrade levels, phase count and measured player speed.
## Derived stats (tool power, phase time, bonuses) are computed from upgrade
## levels + data, so there is a single source of truth.

signal upgrade_purchased(upgrade: UpgradeNode, new_level: int)

var database: GameDatabase
## Phases already played.
var phases_played: int = 0
## Moving average of effective clicks/second (see PhaseRules).
var measured_cps: float
var _levels: Dictionary[StringName, int] = {}


func _init(p_database: GameDatabase) -> void:
	database = p_database
	measured_cps = database.phase_rules.default_cps


# --- Upgrades -----------------------------------------------------------------

func get_level(upgrade_id: StringName) -> int:
	return _levels.get(upgrade_id, 0)


func is_maxed(upgrade: UpgradeNode) -> bool:
	return get_level(upgrade.id) >= upgrade.max_level


func is_available(upgrade: UpgradeNode) -> bool:
	if is_maxed(upgrade):
		return false
	if get_total_levels() < upgrade.required_points:
		return false
	if is_blocked_by_choice(upgrade):
		return false
	for prerequisite: UpgradeNode in upgrade.prerequisites:
		if get_level(prerequisite.id) < 1:
			return false
	return true


## Total levels bought across the whole tree (used by required_points gates).
func get_total_levels() -> int:
	var total := 0
	for level: int in _levels.values():
		total += level
	return total


## True when another node of the same choice group already owns a level.
func is_blocked_by_choice(upgrade: UpgradeNode) -> bool:
	if upgrade.choice_group.is_empty():
		return false
	for other: UpgradeNode in database.upgrades:
		if other != upgrade and other.choice_group == upgrade.choice_group and get_level(other.id) > 0:
			return true
	return false


func get_next_cost(upgrade: UpgradeNode) -> Array[ResourceAmount]:
	return upgrade.get_cost(get_level(upgrade.id))


func can_buy(upgrade: UpgradeNode, inventory: Inventory) -> bool:
	return is_available(upgrade) and inventory.has_all(get_next_cost(upgrade))


func buy(upgrade: UpgradeNode, inventory: Inventory) -> bool:
	if not is_available(upgrade) or not inventory.spend(get_next_cost(upgrade)):
		return false
	_levels[upgrade.id] = get_level(upgrade.id) + 1
	upgrade_purchased.emit(upgrade, _levels[upgrade.id])
	return true


## How much of each resource the upgrades still to buy will cost in total,
## minus what the inventory already holds (only resources still missing are
## listed). Blocked choice nodes are ignored. Used by PhaseGenerator to favour
## the sources the player actually needs.
func get_remaining_need(inventory: Inventory) -> Dictionary[StringName, int]:
	var totals: Dictionary[StringName, int] = {}
	for upgrade: UpgradeNode in database.upgrades:
		if is_blocked_by_choice(upgrade):
			continue
		for level: int in range(get_level(upgrade.id), upgrade.max_level):
			for cost: ResourceAmount in upgrade.get_cost(level):
				totals[cost.resource.id] = totals.get(cost.resource.id, 0) + cost.amount
	var need: Dictionary[StringName, int] = {}
	for id: StringName in totals:
		var missing := totals[id] - (inventory.get_amount(id) if inventory else 0)
		if missing > 0:
			need[id] = missing
	return need


## Copy of the bought levels (upgrade id -> level), for saving.
func get_levels() -> Dictionary[StringName, int]:
	return _levels.duplicate()


## Replaces the long-term progress (loading a save). Values are trusted:
## SaveGame.apply_to() validates them against the database first.
func restore(levels: Dictionary[StringName, int], p_phases_played: int, p_measured_cps: float) -> void:
	_levels = levels.duplicate()
	phases_played = p_phases_played
	if p_measured_cps > 0.0:
		measured_cps = p_measured_cps


# --- Derived stats ------------------------------------------------------------

func is_tool_unlocked(tool: ToolType) -> bool:
	return tool.unlocked_by_default or _effect_total(UpgradeNode.Effect.UNLOCK_TOOL, tool.id) > 0.0


func get_effective_clicks(source: SourceType) -> int:
	var power := roundi(_effect_total(UpgradeNode.Effect.TOOL_POWER, source.tool.id))
	return maxi(1, source.clicks - power)


func get_yield(source: SourceType) -> int:
	var bonus := roundi(_effect_total(UpgradeNode.Effect.YIELD_BONUS, source.yield_resource.id))
	return source.yield_amount + bonus


func get_phase_duration() -> float:
	return database.phase_rules.base_duration + _effect_total(UpgradeNode.Effect.PHASE_TIME)


func get_rarity_weight(rarity: Rarity) -> float:
	if rarity.is_baseline:
		return rarity.weight
	return rarity.weight * (1.0 + _effect_total(UpgradeNode.Effect.RARITY_LUCK))


func get_hunger_drain() -> float:
	var reduction := clampf(_effect_total(UpgradeNode.Effect.HUNGER_DRAIN), 0.0, 0.9)
	return database.phase_rules.hunger_drain_per_second * (1.0 - reduction)


func get_thirst_drain() -> float:
	var reduction := clampf(_effect_total(UpgradeNode.Effect.THIRST_DRAIN), 0.0, 0.9)
	return database.phase_rules.thirst_drain_per_second * (1.0 - reduction)


## Folds the clicks/second measured in the last phase into the moving average.
func record_phase(clicks: int, active_seconds: float) -> void:
	phases_played += 1
	if active_seconds <= 0.0:
		return
	var rules := database.phase_rules
	var sample := clampf(clicks / active_seconds, rules.min_cps, rules.max_cps)
	measured_cps = lerpf(measured_cps, sample, rules.cps_smoothing)


## Sum of value_per_level × level for every upgrade with the given effect
## (and target, when not empty).
func _effect_total(effect: UpgradeNode.Effect, target: StringName = &"") -> float:
	var total := 0.0
	for upgrade: UpgradeNode in database.upgrades:
		if upgrade.effect != effect:
			continue
		if not target.is_empty() and upgrade.target != target:
			continue
		total += upgrade.value_per_level * get_level(upgrade.id)
	return total
