@tool
class_name BoardGridView
extends Node2D
## Board drawing: a frame and one cell of "ground" per square (BoardGround of
## the current biome: fill, 1 px bevel lit from the top-left, tufts/specks
## placed from a fixed per-cell seed). Palette only, whole pixels.

## Tuft stamps: tiny pixel maps ("x" = pixel, "/" = next row), grass-like shapes.
const TUFTS: Array[String] = ["..x../x.x.x/.xxx.", "x..x/.xx./.xx.", "x.x/.x.", "x.../...x"]
## Tufts keep this far from the cell edge.
const TUFT_MARGIN := 3

@export var config: BoardConfig:
	set(value):
		config = value
		queue_redraw()

@export var cell_fill: Color = Palette.SHADOW_DEEP
@export var cell_border: Color = Palette.SHADOW_LIFTED
@export var board_fill: Color = Palette.SHADOW_BLUEBLACK
@export_range(0, 8) var gap: int = 1
@export_range(0, 16) var frame_margin: int = 10
## Ground of the current biome (null = plain cells in cell_fill/cell_border).
@export var ground: BoardGround:
	set(value):
		ground = value
		queue_redraw()


func _draw() -> void:
	if config == null:
		return
	var board_rect := Rect2(Vector2.ZERO, config.get_pixel_size())
	# The frame also covers the concept-art board baked into the background.
	var frame := PixelStyleBox.create(board_fill, cell_border, 2, PackedInt32Array([4, 2]))
	frame.draw(get_canvas_item(), board_rect.grow(frame_margin))
	var cell := PixelStyleBox.create(cell_fill, cell_border, 2, PackedInt32Array([2]))
	if ground:
		cell = PixelStyleBox.create(ground.fill, ground.outline, 1, PackedInt32Array([2, 1]), 1)
	for y: int in config.size.y:
		for x: int in config.size.x:
			var origin := Vector2(x * config.cell_size.x, y * config.cell_size.y)
			var rect := Rect2(origin + Vector2(gap, gap), Vector2(config.cell_size) - Vector2(gap * 2, gap * 2))
			cell.draw(get_canvas_item(), rect)
			if ground:
				_draw_ground(rect, Vector2i(x, y))


## Bevel and tufts of one cell (the fill and outline are already drawn).
func _draw_ground(rect: Rect2, cell: Vector2i) -> void:
	var inner := rect.grow(-1)
	# Lit top/left edge, shaded bottom/right edge (1 px, clear of the cut corners).
	draw_rect(Rect2(inner.position + Vector2(2, 0), Vector2(inner.size.x - 4, 1)), ground.light_edge)
	draw_rect(Rect2(inner.position + Vector2(0, 2), Vector2(1, inner.size.y - 4)), ground.light_edge)
	draw_rect(Rect2(inner.position + Vector2(2, inner.size.y - 1), Vector2(inner.size.x - 4, 1)), ground.dark_edge)
	draw_rect(Rect2(inner.position + Vector2(inner.size.x - 1, 2), Vector2(1, inner.size.y - 4)), ground.dark_edge)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(cell) + 7
	var area := rect.grow(-TUFT_MARGIN)
	for i: int in rng.randi_range(ground.tufts.x, ground.tufts.y):
		var rows := TUFTS[rng.randi() % TUFTS.size()].split("/")
		var at := area.position + Vector2(rng.randi_range(0, int(area.size.x) - 5),
			rng.randi_range(0, int(area.size.y) - 3))
		for row: int in rows.size():
			for col: int in rows[row].length():
				if rows[row][col] == "x":
					draw_rect(Rect2(at + Vector2(col, row), Vector2.ONE), ground.tuft)
	if ground.accent.a > 0.0 and rng.randf() < ground.accent_chance:
		var at := Vector2(rng.randi_range(0, int(area.size.x) - 1), rng.randi_range(0, int(area.size.y) - 1))
		draw_rect(Rect2(area.position + at, Vector2.ONE), ground.accent)

