extends GameState
## Prepares a new match and moves to the first turn.


func enter(_payload: Dictionary = {}) -> void:
	game.board.reset()
	game.turn_number = 0
	request_transition.call_deferred(&"PlayerTurn")
