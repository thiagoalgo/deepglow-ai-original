class_name ResourceType
extends Resource
## A collectable resource (wood, fruit, water…). One .tres per resource in data/resources/.
## Name key: RESOURCE_<ID>_NAME.

enum Category { MATERIAL, FOOD, DRINK }

@export var id: StringName
@export var category: Category = Category.MATERIAL
## Small HUD icon (8x8).
@export var icon: Texture2D
@export var placeholder_color: Color = Palette.LIGHT_BLUE_WHITE
## How much of the hunger bar (0..1) one unit restores when collected.
@export_range(0.0, 1.0, 0.01) var hunger_restore: float = 0.0
## How much of the thirst bar (0..1) one unit restores when collected.
@export_range(0.0, 1.0, 0.01) var thirst_restore: float = 0.0


func get_name_key() -> StringName:
	return StringName("RESOURCE_%s_NAME" % String(id).to_upper())
