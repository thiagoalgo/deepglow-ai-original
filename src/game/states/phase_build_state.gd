extends GameState
## Generates the next phase from current progress and fills the board.


func enter(_payload: Dictionary = {}) -> void:
	game.phase_number += 1
	game.board.clear_items()
	var plan := PhaseGenerator.generate(game.progression, game.board.config.size,
		game.get_phase_seed(game.phase_number))
	for cell: Vector2i in plan.placements:
		var source: SourceType = plan.placements[cell]
		var card := game.card_scene.instantiate() as SourceCard
		card.setup(source, game.progression.get_effective_clicks(source))
		game.board.place_item(card, cell)
	game.current_plan = plan
	request_transition.call_deferred(&"Phase")
