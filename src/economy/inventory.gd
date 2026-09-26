class_name Inventory
extends RefCounted
## Resource amounts owned by the player, keyed by ResourceType.id.

signal changed(resource_id: StringName, amount: int)

var _amounts: Dictionary[StringName, int] = {}
## Resources the player has ever owned (UI only shows these).
var _discovered: Dictionary[StringName, bool] = {}


func get_amount(resource_id: StringName) -> int:
	return _amounts.get(resource_id, 0)


func add(resource_id: StringName, amount: int) -> void:
	if amount == 0:
		return
	var total: int = get_amount(resource_id) + amount
	assert(total >= 0, "Inventory would go negative for %s" % resource_id)
	_amounts[resource_id] = total
	if amount > 0:
		_discovered[resource_id] = true
	changed.emit(resource_id, total)


func is_discovered(resource_id: StringName) -> bool:
	return _discovered.has(resource_id)


func has_all(costs: Array[ResourceAmount]) -> bool:
	for cost: ResourceAmount in costs:
		if get_amount(cost.resource.id) < cost.amount:
			return false
	return true


## Removes all costs atomically. Returns false (and changes nothing) if unaffordable.
func spend(costs: Array[ResourceAmount]) -> bool:
	if not has_all(costs):
		return false
	for cost: ResourceAmount in costs:
		add(cost.resource.id, -cost.amount)
	return true


func to_dict() -> Dictionary[StringName, int]:
	return _amounts.duplicate()
