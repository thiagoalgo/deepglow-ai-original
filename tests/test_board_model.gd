extends RefCounted
## BoardModel tests.


func test_inside_bounds() -> String:
	var m := BoardModel.new(Vector2i(8, 8))
	if not m.is_inside(Vector2i(0, 0)) or not m.is_inside(Vector2i(7, 7)):
		return "corners should be inside"
	if m.is_inside(Vector2i(8, 0)) or m.is_inside(Vector2i(-1, 3)):
		return "out of bounds should be false"
	return ""


func test_set_and_clear() -> String:
	var m := BoardModel.new(Vector2i(4, 4))
	m.set_at(Vector2i(1, 2), "x")
	if m.is_empty(Vector2i(1, 2)) or m.get_at(Vector2i(1, 2)) != "x":
		return "set_at failed"
	if m.empty_cells().size() != 15:
		return "empty_cells should have 15"
	m.clear()
	if m.occupied_cells().size() != 0:
		return "clear failed"
	return ""


func test_neighbors_corner() -> String:
	var m := BoardModel.new(Vector2i(8, 8))
	if m.neighbors(Vector2i(0, 0)).size() != 2:
		return "corner should have 2 orthogonal neighbors"
	if m.neighbors(Vector2i(0, 0), true).size() != 3:
		return "corner should have 3 neighbors with diagonals"
	return ""
