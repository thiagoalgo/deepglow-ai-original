class_name Needs
extends RefCounted
## Hunger and thirst bars (0 = empty, 1 = full) for the current phase.

signal changed(hunger: float, thirst: float)

var hunger: float = 1.0
var thirst: float = 1.0


func reset() -> void:
	hunger = 1.0
	thirst = 1.0
	changed.emit(hunger, thirst)


func drain(delta: float, hunger_rate: float, thirst_rate: float) -> void:
	hunger = maxf(0.0, hunger - hunger_rate * delta)
	thirst = maxf(0.0, thirst - thirst_rate * delta)
	changed.emit(hunger, thirst)


func restore(hunger_amount: float, thirst_amount: float) -> void:
	hunger = minf(1.0, hunger + hunger_amount)
	thirst = minf(1.0, thirst + thirst_amount)
	changed.emit(hunger, thirst)


func is_starving() -> bool:
	return hunger <= 0.0 or thirst <= 0.0


## Damage multiplier applied to each click.
func get_click_factor(starving_factor: float) -> float:
	return starving_factor if is_starving() else 1.0
