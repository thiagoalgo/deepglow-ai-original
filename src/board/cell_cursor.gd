class_name CellCursor
extends Node2D
## Highlight for the cell under the mouse. Positioned by Board.

@export var color: Color = Palette.LIGHT_BLUE_WHITE
@export var size: Vector2 = Vector2(40, 40)


func _draw() -> void:
	var rect := Rect2(-size / 2.0, size).grow(-2)
	draw_rect(rect.grow(-1), color, false, 2.0)


func show_at(local_position: Vector2) -> void:
	position = local_position
	show()
