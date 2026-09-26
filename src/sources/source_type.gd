class_name SourceType
extends Resource
## A resource source that can appear on the board (pine tree, puddle…).
## One .tres per source in data/sources/. Name key: SOURCE_<ID>_NAME.

@export var id: StringName
## Grouping for upgrades and placement (e.g. &"tree", &"fruit", &"water").
@export var family: StringName
## Progression tier (0 = starting content).
@export var tier: int = 0
@export var rarity: Rarity
@export var tool: ToolType
## Clicks needed to collect it before tool upgrades.
@export_range(1, 99) var clicks: int = 1
@export var yield_resource: ResourceType
@export var yield_amount: int = 1
## 16x16 sprite. Null while prototyping (placeholder drawing is used).
@export var texture: Texture2D
@export var placeholder_color: Color = Palette.LIGHT_BLUE_WHITE


func get_name_key() -> StringName:
	return StringName("SOURCE_%s_NAME" % String(id).to_upper())
