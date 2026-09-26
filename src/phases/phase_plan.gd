class_name PhasePlan
extends RefCounted
## Output of PhaseGenerator: what goes where, plus the numbers used to build it.

var phase_seed: int
## Seconds on the timer (fitted to the player's measured speed).
var duration: float
## Click-equivalents of content the generator aimed for (progression only).
var budget_clicks: float
## Click-equivalents actually placed on the board.
var planned_clicks: float = 0.0
## > 1 means slightly less time than the work needs.
var tightness: float = 1.0
## cell -> SourceType
var placements: Dictionary[Vector2i, SourceType] = {}
