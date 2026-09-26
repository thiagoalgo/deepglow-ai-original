class_name Rarity
extends Resource
## Rarity tier of a source. Weight drives how often the phase generator picks it.
## Name key: RARITY_<ID>_NAME.

@export var id: StringName
## Base pick weight (common 60, uncommon 25, rare 12, epic 3).
@export var weight: float = 1.0
## Card frame color.
@export var color: Color = Palette.SHADOW_LIFTED
## True for the baseline tier; "luck" upgrades only boost non-baseline tiers.
@export var is_baseline: bool = false
