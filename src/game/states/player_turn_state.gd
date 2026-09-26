extends GameState
## Player turn (prototype): left click on an empty cell places a random
## piece from the catalog; right click removes it. Replace with the real
## rules once the game design is defined.


func enter(_payload: Dictionary = {}) -> void:
	game.turn_number += 1
	game.board.cell_clicked.connect(_on_cell_clicked)
	game.board.cell_cancelled.connect(_on_cell_cancelled)
	Events.turn_started.emit(game.turn_number)


func exit() -> void:
	game.board.cell_clicked.disconnect(_on_cell_clicked)
	game.board.cell_cancelled.disconnect(_on_cell_cancelled)
	Events.turn_ended.emit(game.turn_number)


func _on_cell_clicked(cell: Vector2i) -> void:
	if not game.board.model.is_empty(cell):
		return
	game.board.place_piece(game.catalog.pick_random(), cell)
	request_transition(&"PlayerTurn")


func _on_cell_cancelled(cell: Vector2i) -> void:
	game.board.remove_piece(cell)
