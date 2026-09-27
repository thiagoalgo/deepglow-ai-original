extends GameState
## Shows what the phase produced, then moves to the upgrade screen.


func enter(payload: Dictionary = {}) -> void:
	var gathered: Dictionary[StringName, int] = {}
	gathered.assign(payload.get("gathered", {}))
	game.phase_summary.continued.connect(_on_continued, CONNECT_ONE_SHOT)
	game.phase_summary.open(game.phase_number, gathered, payload.get("collected", 0),
		payload.get("total", 0), game.database, payload.get("hungry_seconds", 0.0),
		payload.get("thirsty_seconds", 0.0))


func _on_continued() -> void:
	request_transition(&"Upgrade")
