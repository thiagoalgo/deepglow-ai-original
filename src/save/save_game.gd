class_name SaveGame
extends RefCounted
## Snapshot of a run between phases (M5), converted to/from a JSON-safe Dictionary.
## Saved: run seed, completed phases, inventory and progression. Nothing inside a
## phase is saved: a loaded run resumes at the upgrade screen.
## Pure logic (no autoloads), so it is covered by tests/test_save.gd.

## Bump when the format changes; from_dict() refuses newer versions.
const VERSION := 1

var run_seed: int = 0
## Phases already completed (the next phase is phase_number + 1).
var phase_number: int = 0
var amounts: Dictionary[StringName, int] = {}
var discovered: Array[StringName] = []
var levels: Dictionary[StringName, int] = {}
var phases_played: int = 0
var measured_cps: float = 0.0
## Seconds played in the run (optional key: older saves read as 0).
var play_seconds: float = 0.0


static func capture(p_run_seed: int, p_phase_number: int, inventory: Inventory,
		progression: ProgressionState) -> SaveGame:
	var save := SaveGame.new()
	save.run_seed = p_run_seed
	save.phase_number = p_phase_number
	save.amounts = inventory.to_dict()
	save.discovered = inventory.get_discovered()
	save.levels = progression.get_levels()
	save.phases_played = progression.phases_played
	save.measured_cps = progression.measured_cps
	save.play_seconds = progression.play_seconds
	return save


## Restores the snapshot into fresh run state. Ids that no longer exist in the
## database are dropped and levels are clamped to the current max_level, so old
## saves survive data changes.
func apply_to(inventory: Inventory, progression: ProgressionState) -> void:
	var database := progression.database
	var valid_resources: Dictionary[StringName, bool] = {}
	for resource: ResourceType in database.resources:
		valid_resources[resource.id] = true
	var clean_amounts: Dictionary[StringName, int] = {}
	for id: StringName in amounts:
		if valid_resources.has(id):
			clean_amounts[id] = maxi(0, amounts[id])
	var clean_discovered: Array[StringName] = []
	for id: StringName in discovered:
		if valid_resources.has(id):
			clean_discovered.append(id)
	inventory.restore(clean_amounts, clean_discovered)

	var clean_levels: Dictionary[StringName, int] = {}
	for upgrade: UpgradeNode in database.upgrades:
		var level: int = levels.get(upgrade.id, 0)
		if level > 0:
			clean_levels[upgrade.id] = mini(level, upgrade.max_level)
	progression.restore(clean_levels, phases_played, measured_cps)
	progression.play_seconds = maxf(0.0, play_seconds)


func to_dict() -> Dictionary:
	var amounts_out := {}
	for id: StringName in amounts:
		amounts_out[String(id)] = amounts[id]
	var discovered_out: Array[String] = []
	for id: StringName in discovered:
		discovered_out.append(String(id))
	var levels_out := {}
	for id: StringName in levels:
		levels_out[String(id)] = levels[id]
	return {
		"version": VERSION,
		"run_seed": run_seed,
		"phase_number": phase_number,
		"inventory": {"amounts": amounts_out, "discovered": discovered_out},
		"progression": {
			"levels": levels_out,
			"phases_played": phases_played,
			"measured_cps": measured_cps,
			"play_seconds": play_seconds,
		},
	}


## Returns null when the data is not a save this version can read.
static func from_dict(data: Dictionary) -> SaveGame:
	var version := int(data.get("version", 0))
	if version < 1 or version > VERSION:
		return null
	var save := SaveGame.new()
	save.run_seed = int(data.get("run_seed", 0))
	save.phase_number = maxi(0, int(data.get("phase_number", 0)))
	var inventory: Dictionary = _as_dict(data.get("inventory"))
	var amounts_in: Dictionary = _as_dict(inventory.get("amounts"))
	for key: Variant in amounts_in:
		save.amounts[StringName(str(key))] = int(amounts_in[key])
	var discovered_in: Array = _as_array(inventory.get("discovered"))
	for id: Variant in discovered_in:
		save.discovered.append(StringName(str(id)))
	var progression: Dictionary = _as_dict(data.get("progression"))
	var levels_in: Dictionary = _as_dict(progression.get("levels"))
	for key: Variant in levels_in:
		save.levels[StringName(str(key))] = int(levels_in[key])
	save.phases_played = maxi(0, int(progression.get("phases_played", 0)))
	save.measured_cps = float(progression.get("measured_cps", 0.0))
	save.play_seconds = float(progression.get("play_seconds", 0.0))
	return save


static func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


static func _as_array(value: Variant) -> Array:
	return value if value is Array else []
