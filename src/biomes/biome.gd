class_name Biome
extends Resource
## A stage of the journey (docs/game-design.md §7.2): each gate of the upgrade
## tree leads to a new biome with its own background. Name key: BIOME_<ID>_NAME.
## The biome list in GameDatabase is ordered from the first to the last.

@export var id: StringName
## Phase background (640x360, palette only).
@export var background: Texture2D
## Ambient particle layers (AmbientEffect) drawn behind the board in this biome.
@export var ambient_effects: Array[Resource] = []
## Ambience loop played while the run is in this biome (null = keep the current one).
@export var ambience: AudioStream
## Look of the board cells (BoardGround) in this biome.
@export var ground: BoardGround
## Accent color of the biome in the upgrade tree (band header, palette color).
@export var color: Color = Palette.STRUCTURE_HIGHLIGHT
## Levels invested in the tree needed to reach this biome (0 = starting biome).
## Also gates every upgrade node from `tree_row` down.
@export var required_points: int = 0
## First upgrade tree row that belongs to this biome (its gate divider is drawn
## above this row).
@export var tree_row: int = 0


func get_name_key() -> StringName:
	return StringName("BIOME_%s_NAME" % String(id).to_upper())
