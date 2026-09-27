@tool
class_name SaveIcon
extends Control
## 16x16 pixel icon for the save indicator: three blinking dots while saving,
## a check when saved, a cross on failure. Whole 2x2 blocks, palette only.

enum Look { DOTS, CHECK, CROSS }

const SIZE := 16
const CHECK_BLOCKS: Array[Vector2i] = [
	Vector2i(1, 8), Vector2i(3, 10), Vector2i(5, 12), Vector2i(7, 10),
	Vector2i(9, 8), Vector2i(11, 6), Vector2i(13, 4),
]
const CROSS_BLOCKS: Array[Vector2i] = [
	Vector2i(3, 3), Vector2i(5, 5), Vector2i(7, 7), Vector2i(9, 9), Vector2i(11, 11),
	Vector2i(11, 3), Vector2i(9, 5), Vector2i(5, 9), Vector2i(3, 11),
]

@export var look: Look = Look.DOTS:
	set(v):
		look = v
		queue_redraw()
## Which dot is lit (0..2) in the DOTS look.
@export_range(0, 2) var active_dot: int = 0:
	set(v):
		active_dot = v
		queue_redraw()
@export var on_color: Color = Palette.VEGETATION_NEON_TEAL
@export var off_color: Color = Palette.STRUCTURE_INDIGO
@export var fail_color: Color = Palette.LIGHT_PINK


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)


func _draw() -> void:
	match look:
		Look.DOTS:
			for i: int in 3:
				draw_rect(Rect2(1 + i * 5, 6, 4, 4), on_color if i == active_dot else off_color)
		Look.CHECK:
			_draw_blocks(CHECK_BLOCKS, on_color)
		Look.CROSS:
			_draw_blocks(CROSS_BLOCKS, fail_color)


func _draw_blocks(blocks: Array[Vector2i], color: Color) -> void:
	for block: Vector2i in blocks:
		draw_rect(Rect2(block, Vector2(2, 2)), color)
