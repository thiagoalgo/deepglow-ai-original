extends GameState
## The timed harvesting phase (docs/game-design.md §2–5).
## Clicks damage source cards; depleted sources yield resources and may
## refill hunger/thirst. Ends when the timer runs out or the board is empty.

var _clicks: int = 0
var _collected_sources: int = 0
var _total_sources: int = 0
var _gathered: Dictionary[StringName, int] = {}
var _ending: bool = false
## Seconds spent with each bar empty (shown on the summary).
var _hungry_seconds: float = 0.0
var _thirsty_seconds: float = 0.0
## The "weak"/"thirsty" popup already showed since the bar last emptied.
var _hunger_warned: bool = false
var _thirst_warned: bool = false


func enter(_payload: Dictionary = {}) -> void:
	_clicks = 0
	_collected_sources = 0
	_total_sources = game.current_plan.placements.size()
	_gathered = {}
	_ending = false
	_hungry_seconds = 0.0
	_thirsty_seconds = 0.0
	_hunger_warned = false
	_thirst_warned = false
	game.needs.reset()
	game.board.cell_clicked.connect(_on_cell_clicked)
	game.board.navigation_enabled = true
	game.board.cell_hovered.connect(_on_cell_hovered)
	game.board.cell_hover_exited.connect(_on_cell_hover_exited)
	game.phase_timer.timeout.connect(_end_phase)
	game.pause_menu.quit_requested.connect(_on_quit_requested)
	game.phase_timer.start(game.current_plan.duration)
	Events.phase_started.emit(game.phase_number, game.current_plan.duration)
	if game.board.hovered_cell != Board.INVALID_CELL:
		_on_cell_hovered(game.board.hovered_cell)


func exit() -> void:
	game.board.cell_clicked.disconnect(_on_cell_clicked)
	game.board.navigation_enabled = false
	game.board.cell_hovered.disconnect(_on_cell_hovered)
	game.board.cell_hover_exited.disconnect(_on_cell_hover_exited)
	game.phase_timer.timeout.disconnect(_end_phase)
	game.pause_menu.quit_requested.disconnect(_on_quit_requested)
	game.phase_timer.stop()
	game.tool_cursor.show_pointer()


func handle_input(event: InputEvent) -> void:
	if not _ending and event.is_action_pressed(&"pause"):
		game.get_viewport().set_input_as_handled()
		game.tool_cursor.show_pointer()
		game.pause_menu.open()


## "Main menu" from the pause screen: the phase is abandoned (nothing from it
## is saved; the save is the one from before the phase).
func _on_quit_requested() -> void:
	_ending = true
	game.exit_requested.emit()


func update(delta: float) -> void:
	if _ending:
		return
	game.needs.drain(delta, game.progression.get_hunger_drain(), game.progression.get_thirst_drain())
	if game.needs.is_hungry():
		_hungry_seconds += delta
	else:
		_hunger_warned = false
	if game.needs.is_thirsty():
		_thirsty_seconds += delta
	else:
		_thirst_warned = false
	Events.phase_time_changed.emit(game.phase_timer.time_left)


func _on_cell_clicked(cell: Vector2i) -> void:
	var card := game.board.get_item(cell) as SourceCard
	if card == null or _ending:
		return
	if not game.progression.is_tool_unlocked(card.source.tool):
		return
	_clicks += 1
	var rules := game.database.phase_rules
	var depleted := card.hit(game.needs.get_click_factor(rules.hungry_click_factor))
	if game.needs.is_hungry() and not _hunger_warned:
		_hunger_warned = true
		FloatingText.spawn(game.effects, _cell_world(cell) + Vector2(0, -16), tr(&"HUD_WEAK_POPUP"),
			null, &"FloatingAlertLabel")
	Events.source_hit.emit(card.source, cell, depleted)
	if depleted:
		_collect(card, cell)


func _collect(card: SourceCard, cell: Vector2i) -> void:
	var source := card.source
	var resource := source.yield_resource
	var full_amount := game.progression.get_yield(source)
	var amount := game.needs.apply_yield_penalty(full_amount, resource,
		game.database.phase_rules.thirsty_yield_factor)
	game.inventory.add(resource.id, amount)
	_gathered[resource.id] = _gathered.get(resource.id, 0) + amount
	game.needs.restore(resource.hunger_restore * amount, resource.thirst_restore * amount)
	_collected_sources += 1
	var world_pos := _cell_world(cell)
	var reduced := amount < full_amount
	FloatingText.spawn(game.effects, world_pos, "+%d" % amount, resource.icon,
		&"FloatingAlertLabel" if reduced else &"FloatingLabel")
	if reduced and not _thirst_warned:
		_thirst_warned = true
		FloatingText.spawn(game.effects, world_pos + Vector2(0, -16), tr(&"HUD_THIRSTY_POPUP"),
			null, &"FloatingAlertLabel")
	game.board.take_item(cell)
	card.collect()
	Events.source_collected.emit(source, amount, cell)
	_on_cell_hovered(cell)
	if game.board.is_empty():
		_end_phase()


func _end_phase() -> void:
	if _ending:
		return
	_ending = true
	# The last per-frame update can still show 1 s; publish the real final time
	# (0 when the timer ran out, the remaining time when the board was cleared).
	Events.phase_time_changed.emit(game.phase_timer.time_left)
	var elapsed := game.current_plan.duration - game.phase_timer.time_left
	if game.phase_timer.is_stopped():
		elapsed = game.current_plan.duration
	# Click-equivalents include mouse travel, matching the generator's cost model.
	var overhead := game.database.phase_rules.move_overhead_clicks * _collected_sources
	game.progression.record_phase(roundi(_clicks + overhead), elapsed)
	Events.phase_ended.emit(game.phase_number)
	request_transition.call_deferred(&"PhaseSummary", {
		"gathered": _gathered,
		"collected": _collected_sources,
		"total": _total_sources,
		"hungry_seconds": _hungry_seconds,
		"thirsty_seconds": _thirsty_seconds,
	})


func _cell_world(cell: Vector2i) -> Vector2:
	return game.board.position + game.board.cell_to_local(cell)


func _on_cell_hovered(cell: Vector2i) -> void:
	var card := game.board.get_item(cell) as SourceCard
	if card == null:
		game.tool_cursor.show_pointer()
	elif game.progression.is_tool_unlocked(card.source.tool):
		game.tool_cursor.show_tool(card.source.tool)
	else:
		game.tool_cursor.show_locked()


func _on_cell_hover_exited() -> void:
	game.tool_cursor.show_pointer()
