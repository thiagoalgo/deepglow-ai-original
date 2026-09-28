class_name UpgradeTreeView
extends Control
## Draws the upgrade tree HORIZONTALLY: the tree grows left to right. A node's
## grid_position is (lane, depth): depth (y) becomes the column, lane (x) the
## row on screen. The tree is split into biome bands (Biome.tree_row = first
## depth of the band), each with a header (name + points to unlock, biome color)
## and a dotted separator between bands. Links are pixel lines with 45°
## diagonals (2x2 brush, whole pixels), in the child's biome color once the
## parent is owned. Lives inside a horizontal ScrollContainer.

signal node_focused(upgrade: UpgradeNode)
signal node_pressed(upgrade: UpgradeNode)
## A left/right click on the tree outside any node (closes the details popup).
signal background_pressed

## Horizontal distance between depths, vertical distance between lanes.
const CELL := Vector2i(64, 40)
const LANES := 6
## Band header height (two text lines) and the space below it.
const HEADER_HEIGHT := 30
const HEADER_GAP := 4
## Horizontal padding inside a band and the gap between bands.
const BAND_PADDING := 8
const BAND_GAP := 4
## Separator between bands: one dot every SEPARATOR_STEP pixels.
const SEPARATOR_STEP := 4
## Horizontal run into/out of a node before a diagonal starts.
const LINK_LEAD := 4
const LINE := 1

## Links whose parent is not owned yet (owned ones use the biome color).
@export var line_color: Color = Palette.STRUCTURE_INDIGO
@export var separator_color: Color = Palette.SHADOW_LIFTED

var _views: Dictionary[StringName, UpgradeNodeView] = {}
var _progression: ProgressionState
var _database: GameDatabase
## depth -> x of its column center.
var _depth_x: Dictionary[int, int] = {}
## depth -> biome of its band.
var _depth_biome: Dictionary[int, Biome] = {}
## One entry per biome: {biome, rect}.
var _bands: Array[Dictionary] = []
var _links: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_links = Control.new()
	_links.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_links.draw.connect(_draw_links)
	add_child(_links)


func build(database: GameDatabase) -> void:
	_database = database
	for view: UpgradeNodeView in _views.values():
		view.queue_free()
	_views.clear()
	_layout_bands(database)
	var height := HEADER_HEIGHT + HEADER_GAP + LANES * CELL.y
	for upgrade: UpgradeNode in database.upgrades:
		var view := UpgradeNodeView.create(upgrade)
		view.position = Vector2(_node_center(upgrade.grid_position) - Vector2i.ONE * UpgradeNodeView.FRAME_SIZE / 2)
		view.focus_entered.connect(func() -> void: node_focused.emit(upgrade))
		view.pressed.connect(func() -> void: node_pressed.emit(upgrade))
		add_child(view)
		_views[upgrade.id] = view
	var last: Rect2i = _bands[-1]["rect"]
	custom_minimum_size = Vector2(last.end.x, height)
	_links.size = custom_minimum_size
	_link_focus_neighbors()
	_links.queue_redraw()


func refresh(progression: ProgressionState, inventory: Inventory) -> void:
	_progression = progression
	for view: UpgradeNodeView in _views.values():
		view.refresh(progression, inventory)
	_links.queue_redraw()


func get_view(upgrade_id: StringName) -> UpgradeNodeView:
	return _views.get(upgrade_id)


## Focuses the first node (keyboard/gamepad players need a starting point).
func focus_first() -> void:
	var first: UpgradeNodeView
	for view: UpgradeNodeView in _views.values():
		var cell := view.upgrade.grid_position
		if first == null or cell.y < first.upgrade.grid_position.y \
				or (cell.y == first.upgrade.grid_position.y and cell.x < first.upgrade.grid_position.x):
			first = view
	if first:
		first.grab_focus()


## Marks one node as the selected one (null clears the selection).
func set_selected(upgrade: UpgradeNode) -> void:
	for view: UpgradeNodeView in _views.values():
		view.selected = upgrade != null and view.upgrade == upgrade


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		background_pressed.emit()


# --- Layout ---------------------------------------------------------------------

## Bands left to right; a band is as wide as its depths or its header text.
func _layout_bands(database: GameDatabase) -> void:
	_bands.clear()
	_depth_x.clear()
	_depth_biome.clear()
	var max_depth := 0
	for upgrade: UpgradeNode in database.upgrades:
		max_depth = maxi(max_depth, upgrade.grid_position.y)
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var x := 0
	for i: int in database.biomes.size():
		var biome := database.biomes[i]
		var first := biome.tree_row
		var end := database.biomes[i + 1].tree_row if i + 1 < database.biomes.size() else max_depth + 1
		var depths := end - first
		var title := maxf(_text_width(tr(biome.get_name_key()), font, font_size),
			_text_width(_unlock_text(biome), font, font_size))
		var width := maxi(depths * CELL.x + BAND_PADDING * 2, int(title) + 16)
		width += width % 2
		var inner := (width - depths * CELL.x) / 2
		for d: int in depths:
			_depth_x[first + d] = x + inner + d * CELL.x + CELL.x / 2
			_depth_biome[first + d] = biome
		_bands.append({"biome": biome, "rect": Rect2i(x, 0, width, HEADER_HEIGHT + HEADER_GAP + LANES * CELL.y)})
		x += width + BAND_GAP
	# The last band has no gap after it.


func _node_center(cell: Vector2i) -> Vector2i:
	var y := HEADER_HEIGHT + HEADER_GAP + cell.x * CELL.y + UpgradeNodeView.FRAME_SIZE / 2 + 2
	return Vector2i(_depth_x.get(cell.y, 0), y)


# --- Keyboard / gamepad ------------------------------------------------------------

## Screen directions follow the horizontal layout: left/right move in depth,
## up/down between lanes. Each direction goes to the closest node that way.
func _link_focus_neighbors() -> void:
	var directions: Dictionary[Side, Vector2i] = {
		SIDE_LEFT: Vector2i(0, -1), SIDE_RIGHT: Vector2i(0, 1),
		SIDE_TOP: Vector2i(-1, 0), SIDE_BOTTOM: Vector2i(1, 0),
	}
	for view: UpgradeNodeView in _views.values():
		for side: Side in directions:
			var target := _closest_in_direction(view.upgrade.grid_position, directions[side])
			var path := view.get_path_to(target) if target else NodePath()
			view.set_focus_neighbor(side, path)


func _closest_in_direction(from: Vector2i, direction: Vector2i) -> UpgradeNodeView:
	var best: UpgradeNodeView
	var best_score := INF
	for view: UpgradeNodeView in _views.values():
		var delta := view.upgrade.grid_position - from
		var along := delta.x * direction.x + delta.y * direction.y
		if along <= 0:
			continue
		var across := absi(delta.y) if direction.x != 0 else absi(delta.x)
		var score := along + across * 2.0
		if score < best_score:
			best_score = score
			best = view
	return best


# --- Drawing --------------------------------------------------------------------------

func _draw_links() -> void:
	# Links under the nodes (child controls drawn after this layer); owned
	# (active) links last so they stay on top of shared segments.
	for i: int in range(1, _bands.size()):
		_draw_separator(_bands[i]["rect"])
	var inactive: Array[PackedVector2Array] = []
	var active: Array[Dictionary] = []
	for view: UpgradeNodeView in _views.values():
		for prerequisite: UpgradeNode in view.upgrade.prerequisites:
			var parent_view: UpgradeNodeView = _views.get(prerequisite.id)
			if parent_view == null:
				continue
			var path := _link_path(prerequisite.grid_position, view.upgrade.grid_position)
			if parent_view.level > 0:
				var biome: Biome = _depth_biome.get(view.upgrade.grid_position.y)
				active.append({"path": path, "color": biome.color if biome else line_color})
			else:
				inactive.append(path)
	for path: PackedVector2Array in inactive:
		_draw_path(path, line_color)
	for link: Dictionary in active:
		_draw_path(link["path"], link["color"])
	for band: Dictionary in _bands:
		_draw_header(band["biome"], band["rect"])


## Octilinear path (horizontal + 45° diagonals, plus a vertical middle when the
## lanes are far apart) from the parent's right edge to the child's left edge.
## The diagonal goes in the middle of the gap, or right after the parent / right
## before the child when the middle route would run behind another node.
func _link_path(from_cell: Vector2i, to_cell: Vector2i) -> PackedVector2Array:
	var half := UpgradeNodeView.FRAME_SIZE / 2
	var start := Vector2(_node_center(from_cell) + Vector2i(half, -LINE / 2))
	var end := Vector2(_node_center(to_cell) + Vector2i(-half, -LINE / 2))
	var dy := end.y - start.y
	if dy == 0:
		return PackedVector2Array([start, end])
	var dir := signf(dy)
	var room := end.x - start.x - LINK_LEAD * 2
	if room >= absf(dy):
		var candidates: Array[float] = [
			floorf((start.x + end.x) / 2.0) - floorf(absf(dy) / 2.0),  # centered
			start.x + LINK_LEAD,  # right after the parent
			end.x - LINK_LEAD - absf(dy),  # right before the child
		]
		var first: PackedVector2Array
		for x: float in candidates:
			var a := Vector2(x, start.y)
			var path := PackedVector2Array([start, a, Vector2(a.x + absf(dy), end.y), end])
			if first.is_empty():
				first = path
			if not _path_blocked(path, from_cell, to_cell):
				return path
		return first
	# Steep: diagonal, vertical, diagonal.
	var h := floorf(maxf(room, 0.0) / 2.0)
	var a := Vector2(start.x + LINK_LEAD, start.y)
	var b := Vector2(a.x + h, start.y + dir * h)
	var c := Vector2(b.x, end.y - dir * h)
	var d := Vector2(c.x + h, end.y)
	return PackedVector2Array([start, a, b, c, d, end])


## True when the path runs behind a node other than its two ends.
func _path_blocked(path: PackedVector2Array, from_cell: Vector2i, to_cell: Vector2i) -> bool:
	var half := UpgradeNodeView.FRAME_SIZE / 2
	var boxes: Array[Rect2] = []
	for view: UpgradeNodeView in _views.values():
		var cell := view.upgrade.grid_position
		if cell != from_cell and cell != to_cell:
			boxes.append(Rect2(Vector2(_node_center(cell) - Vector2i(half, half)), Vector2.ONE * half * 2))
	for i: int in path.size() - 1:
		var steps := int(maxf(absf(path[i + 1].x - path[i].x), absf(path[i + 1].y - path[i].y)))
		for s: int in range(0, steps + 1, 2):
			var point := path[i].move_toward(path[i + 1], s * (1.4143 if path[i].x != path[i + 1].x and path[i].y != path[i + 1].y else 1.0))
			for box: Rect2 in boxes:
				if box.has_point(point):
					return true
	return false


## Rasterizes a path with a LINE x LINE brush, 1 px steps: crisp pixel-art lines and diagonals.
func _draw_path(path: PackedVector2Array, color: Color) -> void:
	for i: int in path.size() - 1:
		var from := path[i]
		var to := path[i + 1]
		var steps := int(maxf(absf(to.x - from.x), absf(to.y - from.y)))
		var step := Vector2(signf(to.x - from.x), signf(to.y - from.y))
		if step.x == 0.0 or step.y == 0.0:
			var rect := Rect2(from.min(to), (to - from).abs() + Vector2(LINE, LINE))
			_links.draw_rect(rect, color)
			continue
		for s: int in steps + 1:
			_links.draw_rect(Rect2(from + step * s, Vector2(LINE, LINE)), color)


## Dotted vertical line in the gap before `band` (below the headers).
func _draw_separator(band: Rect2i) -> void:
	var x := band.position.x - BAND_GAP / 2 - 1
	var y := HEADER_HEIGHT + HEADER_GAP
	while y < band.end.y:
		_links.draw_rect(Rect2(x, y, 2, 2), separator_color)
		y += SEPARATOR_STEP


## Header of a band: biome name and the points that unlock it. Bright in the
## biome color once reached, dim before.
func _draw_header(biome: Biome, band: Rect2i) -> void:
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var reached := _progression != null and _progression.get_total_levels() >= biome.required_points
	var center := band.position.x + band.size.x / 2.0
	var name := tr(biome.get_name_key())
	var name_color := biome.color if reached else Palette.STRUCTURE_VIOLET
	# The starting biome needs no points: its name alone, centered.
	var name_y := band.position.y + (13 if biome.required_points > 0 else 19)
	_links.draw_string(font, Vector2(floorf(center - _text_width(name, font, font_size) / 2.0), name_y),
		name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, name_color)
	if biome.required_points == 0:
		return
	var unlock := _unlock_text(biome)
	var unlock_color := Palette.STRUCTURE_MID_BLUE if reached else Palette.LIGHT_PINK
	_links.draw_string(font, Vector2(floorf(center - _text_width(unlock, font, font_size) / 2.0), band.position.y + 25),
		unlock, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, unlock_color)


func _unlock_text(biome: Biome) -> String:
	return tr(&"UI_BIOME_UNLOCK") % biome.required_points if biome.required_points > 0 else ""


static func _text_width(text: String, font: Font, font_size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
