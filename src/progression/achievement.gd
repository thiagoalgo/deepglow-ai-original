class_name Achievement
extends Resource
## A platform achievement (Steam) unlocked by long-term progress. The id is the
## API name configured in Steamworks; display names/descriptions live there
## (see docs/publishing.md). Evaluated by Game after each phase and purchase.

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


func is_unlocked(progression: ProgressionState) -> bool:
	match kind:
		Kind.PHASES_PLAYED:
			return progression.phases_played >= amount
		Kind.UPGRADE_OWNED:
			return progression.get_level(target) > 0
		Kind.TOTAL_LEVELS:
			return progression.get_total_levels() >= amount
	return false
