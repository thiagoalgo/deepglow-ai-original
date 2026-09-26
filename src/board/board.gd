class_name Board
extends Node2D
## Board view + input. Holds a BoardModel (pure state) and keeps the
## Piece nodes in sync with it. Contains no game rules: rules live in the
## Game states (src/game/states/).

signal cell_hovered(cell: Vector2i)
signal cell_hover_exited
signal cell_clicked(cell: Vector2i)
signal cell_cancelled(cell: Vector2i)

const INVALID_CELL := Vector2i(-1, -1)

@export var config: BoardConfig
@export var piece_scene: PackedScene

var model: BoardModel
var hovered_cell: Vector2i = INVALID_CELL

@onready var _grid_view: BoardGridView = %GridView
@onready var _pieces_root: Node2D = %Pieces
@onready var _cursor: CellCursor = %Cursor


func _ready() -> void:
	assert(config != null, "Board requires a BoardConfig.")
	assert(piece_scene != null, "Board requires piece_scene.")
	model = BoardModel.new(config.size)
	_grid_view.config = config
	_cursor.size = Vector2(config.cell_size)
	_cursor.hide()


# --- Coordinates -------------------------------------------------------------

func cell_to_local(cell: Vector2i) -> Vector2:
	return Vector2(cell * config.cell_size) + Vector2(config.cell_size) / 2.0


func local_to_cell(local_pos: Vector2) -> Vector2i:
	var cell := Vector2i((local_pos / Vector2(config.cell_size)).floor())
	return cell if model.is_inside(cell) else INVALID_CELL


# --- Pieces ------------------------------------------------------------------

func place_piece(data: PieceData, cell: Vector2i) -> Piece:
	if not model.is_empty(cell):
		push_warning("Cell occupied or invalid: %s" % cell)
		return null
	var piece := piece_scene.instantiate() as Piece
	piece.data = data
	piece.cell = cell
	piece.position = cell_to_local(cell)
	_pieces_root.add_child(piece)
	model.set_at(cell, piece)
	piece.play_spawn()
	Events.piece_placed.emit(piece, cell)
	return piece


func remove_piece(cell: Vector2i) -> void:
	var piece := get_piece(cell)
	if piece == null:
		return
	model.clear_at(cell)
	Events.piece_removed.emit(piece, cell)
	piece.despawn()


func move_piece(from: Vector2i, to: Vector2i) -> bool:
	var piece := get_piece(from)
	if piece == null or not model.is_empty(to):
		return false
	model.clear_at(from)
	model.set_at(to, piece)
	piece.cell = to
	piece.move_to(cell_to_local(to))
	return true


func get_piece(cell: Vector2i) -> Piece:
	return model.get_at(cell) as Piece


func reset() -> void:
	for cell: Vector2i in model.occupied_cells():
		remove_piece(cell)


# --- Input -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover(local_to_cell(get_local_mouse_position()))
	elif event.is_action_pressed(&"select") and hovered_cell != INVALID_CELL:
		cell_clicked.emit(hovered_cell)
		Events.cell_selected.emit(hovered_cell)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"cancel") and hovered_cell != INVALID_CELL:
		cell_cancelled.emit(hovered_cell)
		get_viewport().set_input_as_handled()


func _update_hover(cell: Vector2i) -> void:
	if cell == hovered_cell:
		return
	hovered_cell = cell
	if cell == INVALID_CELL:
		_cursor.hide()
		cell_hover_exited.emit()
		Events.cell_hover_exited.emit()
	else:
		_cursor.show_at(cell_to_local(cell))
		cell_hovered.emit(cell)
		Events.cell_hovered.emit(cell)
