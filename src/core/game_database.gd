class_name GameDatabase
extends Resource
## Root of all game data (data/game_database.tres). Systems receive this instead
## of loading individual .tres files, which keeps tests and the simulator simple.

@export var resources: Array[ResourceType] = []
@export var rarities: Array[Rarity] = []
@export var tools: Array[ToolType] = []
@export var sources: Array[SourceType] = []
@export var upgrades: Array[UpgradeNode] = []
@export var phase_rules: PhaseRules
## Platform (Steam) achievements, see Achievement and the Platform autoload.
@export var achievements: Array[Achievement] = []


func get_resource(id: StringName) -> ResourceType:
	for item: ResourceType in resources:
		if item.id == id:
			return item
	return null


func get_tool(id: StringName) -> ToolType:
	for item: ToolType in tools:
		if item.id == id:
			return item
	return null


func get_source(id: StringName) -> SourceType:
	for item: SourceType in sources:
		if item.id == id:
			return item
	return null


func get_upgrade(id: StringName) -> UpgradeNode:
	for item: UpgradeNode in upgrades:
		if item.id == id:
			return item
	return null
