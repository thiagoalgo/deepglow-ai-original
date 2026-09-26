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
## Tree node icon (10x10).
@export var icon: Texture2D
@export var effect: Effect = Effect.YIELD_BONUS
@export var target: StringName
@export var value_per_level: float = 1.0
@export_range(1, 20) var max_level: int = 1
@export var base_costs: Array[ResourceAmount] = []
## Cost multiplier applied per already-owned level.
@export var cost_growth: float = 2.0
@export_group("Tree layout")
## Cell of the node in the upgrade tree grid (column, row). Row 0 is the top.
## Connections are drawn from each prerequisite to this node.
@export var grid_position: Vector2i = Vector2i.ZERO
## Nodes sharing a non-empty choice group are mutually exclusive: once one of
## them owns a level, the others become unavailable ("pick one" nodes).
@export var choice_group: StringName
## Gate: total levels invested in the whole tree required before this node
## becomes available (like "8 points required" rows).
@export var required_points: int = 0

@export_group("Requirements")
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
