class_name CellCursor
extends Node2D
## Highlight for the cell under the mouse. Positioned by Board.

@export var color: Color = Palette.VEGETATION_NEON_TEAL
@export var size: Vector2 = Vector2(20, 20)


func _draw() -> void:
	var rect := Rect2(-size / 2.0, size).grow(-1)
	draw_rect(rect, color, false, 1.0)


func show_at(local_position: Vector2) -> void:
	position = local_position
	show()
