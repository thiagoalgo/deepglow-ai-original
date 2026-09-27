class_name PhaseRules
extends Resource
## Tuning knobs for phases, the phase generator and survival needs.
## Instance: data/phases/default_rules.tres. See docs/game-design.md §5–6.

@export_group("Timing")
## Nominal phase length. Sets how much CONTENT a phase has
## (base_duration × reference_cps); the actual timer is fitted to each
## player's measured speed.
@export var base_duration: float = 45.0
## Shortest timer allowed (seconds).
@export var min_duration: float = 15.0

@export_group("Generator")
## Click-equivalents per second of the reference player; converts
## base_duration into the content budget of a phase.
@export var reference_cps: float = 3.0
## Starting clicks/second estimate before any phase was measured.
@export var default_cps: float = 3.0
@export var min_cps: float = 2.0
@export var max_cps: float = 6.0
## Weight of the latest phase in the clicks/second moving average.
@export_range(0.0, 1.0) var cps_smoothing: float = 0.5
## Timer = planned work / (measured cps × random(tightness_min, tightness_max)).
@export var tightness_min: float = 1.0
@export var tightness_max: float = 1.15
## Click-equivalents spent moving the mouse to each source.
@export var move_overhead_clicks: float = 1.0
## Guaranteed sources per phase by resource category.
@export var min_food_sources: int = 2
@export var min_drink_sources: int = 2
## Upper bound of occupied cells (fraction of the board).
@export_range(0.1, 1.0) var max_board_fill: float = 0.75
## How strongly cheap sources are avoided once they would overflow the board
## (0 = never, higher = prefer pricier/rarer sources more aggressively).
@export_range(0.0, 8.0) var cheap_source_penalty: float = 2.0
## Demand: sources whose resource the remaining upgrades still need get their
## weight multiplied by up to (1 + demand_boost) — the most needed resource gets
## the full boost, the others in proportion to how much of them is missing.
@export_range(0.0, 20.0) var demand_boost: float = 3.0
## Weight multiplier for sources whose resource no upgrade needs any more
## (food/drink guarantees still apply, so hunger and thirst stay manageable).
@export_range(0.0, 1.0) var surplus_weight: float = 0.15

@export_group("Needs")
## Bar fraction lost per second (1.0 = full bar).
@export var hunger_drain_per_second: float = 0.02
@export var thirst_drain_per_second: float = 0.025
## Damage per click while hunger or thirst is empty (1.0 = normal).
@export_range(0.1, 1.0) var starving_click_factor: float = 0.5
