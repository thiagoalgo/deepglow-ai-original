class_name BoardModel
extends RefCounted
## Pure board state (no nodes, no rendering).
## Game rules must read/modify the board through this class, which keeps
## the logic testable in headless mode (see tests/).

signal cell_changed(cell: Vector2i, old_value: Variant, new_value: Variant)

var size: Vector2i
var _cells: Dictionary[Vector2i, Variant] = {}


func _init(board_size: Vector2i = Vector2i(8, 8)) -> void:
	size = board_size


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func is_empty(cell: Vector2i) -> bool:
	return is_inside(cell) and not _cells.has(cell)


func get_at(cell: Vector2i) -> Variant:
	return _cells.get(cell)


func set_at(cell: Vector2i, value: Variant) -> void:
	assert(is_inside(cell), "Cell outside the board: %s" % cell)
	var old: Variant = _cells.get(cell)
	if value == null:
		_cells.erase(cell)
	else:
		_cells[cell] = value
	cell_changed.emit(cell, old, value)


func clear_at(cell: Vector2i) -> void:
	set_at(cell, null)


func clear() -> void:
	for cell: Vector2i in _cells.keys():
		clear_at(cell)


func occupied_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(_cells.keys())
	return result


func empty_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			if not _cells.has(cell):
				result.append(cell)
	return result


func neighbors(cell: Vector2i, include_diagonals: bool = false) -> Array[Vector2i]:
	var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	if include_diagonals:
		dirs.append_array([Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)])
	var result: Array[Vector2i] = []
	for dir: Vector2i in dirs:
		var n := cell + dir
		if is_inside(n):
			result.append(n)
	return result
