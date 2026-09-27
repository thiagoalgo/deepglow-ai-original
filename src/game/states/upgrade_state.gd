extends GameState
## Between phases: spend resources on the upgrade tree, then build the next phase.
## Autosaves on entry (purchases save through Game); "Menu" returns to the title.


func enter(_payload: Dictionary = {}) -> void:
	game.board.clear_items()
	game.save_run()
	game.report_achievements()
	game.upgrade_screen.start_requested.connect(_on_start_requested)
	game.upgrade_screen.menu_requested.connect(_on_menu_requested)
	game.upgrade_screen.open(game.database, game.progression, game.inventory, game.phase_number + 1)


func exit() -> void:
	game.upgrade_screen.start_requested.disconnect(_on_start_requested)
	game.upgrade_screen.menu_requested.disconnect(_on_menu_requested)


func _on_start_requested() -> void:
	request_transition(&"PhaseBuild")


func _on_menu_requested() -> void:
	game.exit_requested.emit()
