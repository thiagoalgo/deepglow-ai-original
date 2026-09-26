class_name PhaseRules
extends Resource
## Tuning knobs for phases, the phase generator and survival needs.
## Instance: data/phases/default_rules.tres. See docs/game-design.md §5–6.

@export_group("Timing")
@export var base_duration: float = 45.0

@export_group("Generator")
## Starting clicks/second estimate before any phase was measured.
@export var default_cps: float = 3.0
@export var min_cps: float = 2.0
@export var max_cps: float = 6.0
## Weight of the latest phase in the clicks/second moving average.
@export_range(0.0, 1.0) var cps_smoothing: float = 0.5
## Budget = capacity × random(tightness_min, tightness_max).
@export var tightness_min: float = 1.0
@export var tightness_max: float = 1.15
## Click-equivalents spent moving the mouse to each source.
@export var move_overhead_clicks: float = 1.0
## Guaranteed sources per phase by resource category.
@export var min_food_sources: int = 2
@export var min_drink_sources: int = 2
## Upper bound of occupied cells (fraction of the board).
@export_range(0.1, 1.0) var max_board_fill: float = 0.75

@export_group("Needs")
## Bar fraction lost per second (1.0 = full bar).
@export var hunger_drain_per_second: float = 0.02
@export var thirst_drain_per_second: float = 0.025
## Damage per click while hunger or thirst is empty (1.0 = normal).
@export_range(0.1, 1.0) var starving_click_factor: float = 0.5
