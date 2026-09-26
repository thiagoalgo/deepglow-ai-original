class_name UpgradeTreeView
extends Control
## Draws the upgrade tree: nodes on a grid (UpgradeNode.grid_position),
## lines from each prerequisite to its dependents and "N required" gate
## dividers above rows with required_points. Lives inside a ScrollContainer.

signal node_focused(upgrade: UpgradeNode)
signal node_pressed(upgrade: UpgradeNode)

## Distance between grid cells (node + level label + spacing).
@export var cell_size: Vector2 = Vector2(28, 28)
@export var padding: Vector2 = Vector2(10, 12)
## Extra vertical space inserted above rows that have a gate divider.
@export var gate_gap: float = 12.0
@export var line_color: Color = Palette.STRUCTURE_INDIGO
@export var active_line_color: Color = Palette.VEGETATION_MOSS
@export var gate_color: Color = Palette.STRUCTURE_VIOLET

var _views: Dictionary[StringName, UpgradeNodeView] = {}
var _gates: Dictionary[int, int] = {}  # row -> required points
var _progression: ProgressionState


func build(database: GameDatabase) -> void:
	for view: UpgradeNodeView in _views.values():
		view.queue_free()
	_views.clear()
	_gates.clear()
	var extent := Vector2i.ZERO
	for upgrade: UpgradeNode in database.upgrades:
		if upgrade.required_points > 0:
			_gates[upgrade.grid_position.y] = maxi(_gates.get(upgrade.grid_position.y, 0),
				upgrade.required_points)
	for upgrade: UpgradeNode in database.upgrades:
		var view := UpgradeNodeView.create(upgrade)
		view.position = _node_position(upgrade.grid_position)
		view.focus_entered.connect(func() -> void: node_focused.emit(upgrade))
		view.pressed.connect(func() -> void: node_pressed.emit(upgrade))
		add_child(view)
		_views[upgrade.id] = view
		extent = extent.max(upgrade.grid_position)
	custom_minimum_size = padding * 2.0 + Vector2(extent + Vector2i.ONE) * cell_size \
		+ Vector2(0, _gates_up_to(extent.y) * gate_gap)
	queue_redraw()


func refresh(progression: ProgressionState, inventory: Inventory) -> void:
	_progression = progression
	for view: UpgradeNodeView in _views.values():
		view.refresh(progression, inventory)
	queue_redraw()


func get_view(upgrade_id: StringName) -> UpgradeNodeView:
	return _views.get(upgrade_id)


func focus_first_affordable() -> void:
	var fallback: UpgradeNodeView = null
	for view: UpgradeNodeView in _views.values():
		if view.state == UpgradeNodeView.NodeState.AFFORDABLE:
			view.grab_focus()
			return
		if fallback == null:
			fallback = view
	if fallback:
		fallback.grab_focus()


func _node_position(cell: Vector2i) -> Vector2:
	var offset := (cell_size - Vector2(UpgradeNodeView.FRAME_SIZE, UpgradeNodeView.FRAME_SIZE)) / 2.0
	return (padding + Vector2(cell) * cell_size + offset + Vector2(0, _row_shift(cell.y))).floor()


## Vertical shift of a row caused by the gate gaps above it (and its own).
func _row_shift(row: int) -> float:
	return _gates_up_to(row) * gate_gap


func _gates_up_to(row: int) -> int:
	var count := 0
	for gate_row: int in _gates:
		if gate_row <= row:
			count += 1
	return count


func _node_center(cell: Vector2i) -> Vector2:
	return _node_position(cell) + Vector2.ONE * UpgradeNodeView.FRAME_SIZE / 2.0


func _draw() -> void:
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	# Gate dividers.
	for row: int in _gates:
		# Middle of the gap inserted above the gated row.
		var y := floorf(padding.y + row * cell_size.y + _row_shift(row) - gate_gap / 2.0 + 1.0)
		var label := tr(&"UI_REQUIRED_POINTS") % _gates[row]
		var met := _progression != null and _progression.get_total_levels() >= _gates[row]
		var color := active_line_color if met else gate_color
		draw_line(Vector2(padding.x, y), Vector2(size.x - padding.x, y), color, 1.0)
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var x := floorf((size.x - width) / 2.0)
		draw_rect(Rect2(x - 2, y - 4, width + 4, 8), Palette.SHADOW_BLUEBLACK)
		draw_string(font, Vector2(x, y + 3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	# Connections (drawn under the nodes, which are child controls).
	for view: UpgradeNodeView in _views.values():
		for prerequisite: UpgradeNode in view.upgrade.prerequisites:
			var parent_view: UpgradeNodeView = _views.get(prerequisite.id)
			if parent_view == null:
				continue
			var owned := parent_view.level > 0
			var from := _node_center(prerequisite.grid_position)
			var to := _node_center(view.upgrade.grid_position)
			draw_line(from.floor(), to.floor(), active_line_color if owned else line_color, 2.0)
