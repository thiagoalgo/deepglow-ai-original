class_name ResourceAmount
extends Resource
## A (resource, amount) pair. Used for costs and yields.
## Create in code with ResourceAmount.new(resource, amount).

@export var resource: ResourceType
@export var amount: int = 1


func _init(p_resource: ResourceType = null, p_amount: int = 1) -> void:
	resource = p_resource
	amount = p_amount
