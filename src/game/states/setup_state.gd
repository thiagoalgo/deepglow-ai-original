extends GameState
## Prepares the run: a new run goes to the first phase, a loaded one
## (phase_number > 0) resumes at the upgrade screen.


func enter(_payload: Dictionary = {}) -> void:
	game.board.clear_items()
	var next_state := &"Upgrade" if game.phase_number > 0 else &"PhaseBuild"
	request_transition.call_deferred(next_state)
