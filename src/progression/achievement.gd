class_name Achievement
extends Resource
## A milestone achievement unlocked by long-term progress: reported to Steam
## (the id is the Steamworks API name, docs/publishing.md) and shown in the
## "My achievements" screen (name/description keys <ID>_NAME / <ID>_DESC).
## Evaluated by Game after each phase and purchase.

enum Kind {
	PHASES_PLAYED,  ## progression.phases_played >= amount
	UPGRADE_OWNED,  ## the upgrade `target` has at least one level
	TOTAL_LEVELS,   ## levels bought across the whole tree >= amount
}

## Steamworks API name (e.g. ACH_FIRST_NIGHT).
@export var id: StringName
@export var kind: Kind = Kind.PHASES_PLAYED
## Upgrade id for UPGRADE_OWNED.
@export var target: StringName
@export var amount: int = 1
## Emblem drawn inside the badge (an existing game icon).
@export var icon: Texture2D


func get_name_key() -> StringName:
	return StringName("%s_NAME" % id)


func get_desc_key() -> StringName:
	return StringName("%s_DESC" % id)


func is_unlocked(progression: ProgressionState) -> bool:
	match kind:
		Kind.PHASES_PLAYED:
			return progression.phases_played >= amount
		Kind.UPGRADE_OWNED:
			return progression.get_level(target) > 0
		Kind.TOTAL_LEVELS:
			return progression.get_total_levels() >= amount
	return false
