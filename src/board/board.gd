class_name Board
extends Node2D
## Board view + input. Holds a BoardModel (pure state) with one Node2D item per
## occupied cell. Contains no game rules: rules live in the Game states
## (src/game/states/). Items are owned by the board once placed.

signal cell_hovered(cell: Vector2i)
signal cell_hover_exited
signal cell_clicked(cell: Vector2i)
signal cell_cancelled(cell: Vector2i)
## The hovered cell was moved with keys/gamepad (board_* actions), not the
## mouse: the software cursor should jump to that cell.
signal cell_navigated(cell: Vector2i)

const INVALID_CELL := Vector2i(-1, -1)
const NAV_ACTIONS: Dictionary[StringName, Vector2i] = {
	&"board_left": Vector2i.LEFT, &"board_right": Vector2i.RIGHT,
	&"board_up": Vector2i.UP, &"board_down": Vector2i.DOWN,
}

@export var config: BoardConfig

var model: BoardModel
var hovered_cell: Vector2i = INVALID_CELL
## Keys/gamepad move the hovered cell only while enabled (set by the Phase state),
## so menus drawn over the board keep those inputs.
var navigation_enabled: bool = false

@onready var _grid_view: BoardGridView = %GridView
@onready var _items_root: Node2D = %Items


func _ready() -> void:
	assert(config != null, "Board requires a BoardConfig.")
	model = BoardModel.new(config.size)
	_grid_view.config = config


# --- Coordinates -------------------------------------------------------------

func cell_to_local(cell: Vector2i) -> Vector2:
	return Vector2(cell * config.cell_size) + Vector2(config.cell_size) / 2.0


func local_to_cell(local_pos: Vector2) -> Vector2i:
	var cell := Vector2i((local_pos / Vector2(config.cell_size)).floor())
	return cell if model.is_inside(cell) else INVALID_CELL


# --- Items -------------------------------------------------------------------

func place_item(item: Node2D, cell: Vector2i) -> bool:
	if not model.is_empty(cell):
		push_warning("Cell occupied or invalid: %s" % cell)
		return false
	item.position = cell_to_local(cell)
	_items_root.add_child(item)
	model.set_at(cell, item)
	return true


## Detaches the item from the cell and returns it (the caller frees/animates it).
func take_item(cell: Vector2i) -> Node2D:
	var item := get_item(cell)
	if item:
		model.clear_at(cell)
	return item


func get_item(cell: Vector2i) -> Node2D:
	return model.get_at(cell) as Node2D


func is_empty() -> bool:
	return model.occupied_cells().is_empty()


func clear_items() -> void:
	for cell: Vector2i in model.occupied_cells():
		take_item(cell).queue_free()


# --- Input -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover(local_to_cell(get_local_mouse_position()))
		return
	if navigation_enabled:
		for action: StringName in NAV_ACTIONS:
			if event.is_action_pressed(action, true):
				_navigate(NAV_ACTIONS[action])
				get_viewport().set_input_as_handled()
				return
	if event.is_action_pressed(&"select") and hovered_cell != INVALID_CELL:
		cell_clicked.emit(hovered_cell)
		Events.cell_selected.emit(hovered_cell)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"cancel") and hovered_cell != INVALID_CELL:
		cell_cancelled.emit(hovered_cell)
		get_viewport().set_input_as_handled()


## Moves the hovered cell one step (the first press starts from the centre).
func _navigate(direction: Vector2i) -> void:
	var cell := hovered_cell
	if cell == INVALID_CELL:
		cell = config.size / 2
	else:
		cell = (cell + direction).clamp(Vector2i.ZERO, config.size - Vector2i.ONE)
	_update_hover(cell)
	cell_navigated.emit(cell)


func _update_hover(cell: Vector2i) -> void:
	if cell == hovered_cell:
		return
	hovered_cell = cell
	if cell == INVALID_CELL:
		cell_hover_exited.emit()
		Events.cell_hover_exited.emit()
	else:
		cell_hovered.emit(cell)
		Events.cell_hovered.emit(cell)
