extends GameState
## Prepares the run and moves to the first phase.


func enter(_payload: Dictionary = {}) -> void:
	game.board.clear_items()
	request_transition.call_deferred(&"PhaseBuild")
