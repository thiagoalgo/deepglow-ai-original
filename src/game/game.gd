class_name Game
extends Node2D
## Match root. Orchestrates Board + StateMachine and holds the match
## context (turn, catalog). Rules live in the states under states/.

@export var catalog: PieceCatalog

var turn_number: int = 0

@onready var board: Board = %Board
@onready var state_machine: StateMachine = %StateMachine


func _ready() -> void:
	assert(catalog != null, "Game requires a PieceCatalog.")
	_center_board()


func _center_board() -> void:
	var viewport_size := get_viewport_rect().size
	var board_size := Vector2(board.config.get_pixel_size())
	board.position = ((viewport_size - board_size) / 2.0).floor()
