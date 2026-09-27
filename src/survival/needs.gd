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


func is_hungry() -> bool:
	return hunger <= 0.0


func is_thirsty() -> bool:
	return thirst <= 0.0


## Either bar is empty (balance metric).
func is_starving() -> bool:
	return is_hungry() or is_thirsty()


## Damage multiplier applied to each click: an empty hunger bar weakens hits.
func get_click_factor(hungry_factor: float) -> float:
	return hungry_factor if is_hungry() else 1.0


## Amount actually gathered: an empty thirst bar wastes part of every material
## (food and drink are never reduced, so the player can always recover).
func apply_yield_penalty(amount: int, resource: ResourceType, thirsty_factor: float) -> int:
	if not is_thirsty() or resource.category != ResourceType.Category.MATERIAL:
		return amount
	return maxi(1, roundi(amount * thirsty_factor))
