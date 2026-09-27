class_name GameFx
extends Node
## Visual feedback driven by the Events bus: material chips on every hit and a
## sparkle burst when a source is collected (PixelBurst, palette-only).

const SPARKLE_COLORS: PackedColorArray = [
	Palette.LIGHT_BLUE_WHITE, Palette.LIGHT_SULFUR_YELLOW, Palette.VEGETATION_NEON_TEAL,
	Palette.VEGETATION_MOSS,
]

@export var board: Board
## Parent for the bursts (world coordinates).
@export var effects: Node2D
@export var chips_per_hit: int = 6
## Chips start this far from the cell centre and fly outwards (away from the
## cursor, which covers the centre of the cell while clicking).
@export var chip_start_radius: float = 12.0
@export var sparkles_per_collect: int = 10


func _ready() -> void:
	Events.source_hit.connect(_on_source_hit)
	Events.source_collected.connect(_on_source_collected)


func _cell_world(cell: Vector2i) -> Vector2:
	return board.position + board.cell_to_local(cell)


func _on_source_hit(source: SourceType, cell: Vector2i, _depleted: bool) -> void:
	var colors := source.tool.particle_colors
	if colors.is_empty():
		return
	PixelBurst.spawn(effects, _cell_world(cell), colors, chips_per_hit,
		130.0, 380.0, 0.4, PI * 0.6, chip_start_radius)


func _on_source_collected(source: SourceType, _amount: int, cell: Vector2i) -> void:
	var rare := source.rarity != null and not source.rarity.is_baseline
	var count := sparkles_per_collect * (2 if rare else 1)
	PixelBurst.spawn(effects, _cell_world(cell), SPARKLE_COLORS, count, 84.0, 60.0, 0.55, PI, 8.0)
