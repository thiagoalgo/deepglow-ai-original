extends GameState
## Between phases: spend resources on the upgrade tree, then build the next phase.


func enter(_payload: Dictionary = {}) -> void:
	game.board.clear_items()
	game.upgrade_screen.start_requested.connect(_on_start_requested, CONNECT_ONE_SHOT)
	game.upgrade_screen.open(game.database, game.progression, game.inventory, game.phase_number + 1)


func _on_start_requested() -> void:
	request_transition(&"PhaseBuild")
