class_name PhasePlan
extends RefCounted
## Output of PhaseGenerator: what goes where, plus the numbers used to build it.

var phase_seed: int
var duration: float
var capacity_clicks: float
var budget_clicks: float
var planned_clicks: float = 0.0
## cell -> SourceType
var placements: Dictionary[Vector2i, SourceType] = {}
