class_name UpgradeNode
extends Resource
## A node of the upgrade tree. Leveled: cost grows geometrically per level.
## Name keys: UPGRADE_<ID>_NAME and UPGRADE_<ID>_DESC.

enum Effect {
	UNLOCK_TOOL,      ## target = tool id; unlocks it (use max_level 1)
	TOOL_POWER,       ## target = tool id; -value clicks on its sources per level
	YIELD_BONUS,      ## target = resource id; +value units per collected source per level
	PHASE_TIME,       ## +value seconds per phase per level
	RARITY_LUCK,      ## +value (fraction) weight for non-baseline rarities per level
	HUNGER_DRAIN,     ## -value (fraction) hunger drain per level
	THIRST_DRAIN,     ## -value (fraction) thirst drain per level
}

@export var id: StringName
@export var effect: Effect = Effect.YIELD_BONUS
@export var target: StringName
@export var value_per_level: float = 1.0
@export_range(1, 20) var max_level: int = 1
@export var base_costs: Array[ResourceAmount] = []
## Cost multiplier applied per already-owned level.
@export var cost_growth: float = 2.0
## Upgrades (UpgradeNode) that must own at least one level before this one is available.
## Typed as Resource on purpose: a self-typed Array[UpgradeNode] creates a script
## reference cycle that leaks at exit.
@export var prerequisites: Array[Resource] = []


func get_name_key() -> StringName:
	return StringName("UPGRADE_%s_NAME" % String(id).to_upper())


func get_desc_key() -> StringName:
	return StringName("UPGRADE_%s_DESC" % String(id).to_upper())


## Cost to buy the next level when `current_level` levels are already owned.
func get_cost(current_level: int) -> Array[ResourceAmount]:
	var result: Array[ResourceAmount] = []
	var factor := pow(cost_growth, current_level)
	for base: ResourceAmount in base_costs:
		result.append(ResourceAmount.new(base.resource, ceili(base.amount * factor)))
	return result
