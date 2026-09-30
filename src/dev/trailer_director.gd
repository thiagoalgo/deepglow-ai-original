extends Node
## TRAILER CAPTURE ONLY (not part of the game). Plays the game automatically
## with a fake mouse so Movie Maker can record real gameplay.
## Registered as an autoload only by tools/trailer/capture.sh (on a copy of the project).
## Args (after --): save=NN seconds=N cps=N buys=N tree_scroll=N summary_hold=S music=1 lang=xx

const SCALE := 3.0
var mouse := Vector2(320, 200)
var args := {}
var main: Node
var game: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a: String in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	_run.call_deferred()


func _arg(k: String, d: Variant) -> Variant:
	return type_convert(args[k], typeof(d)) if args.has(k) else d


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _secs(s: float) -> void:
	await _frames(int(s * 30.0))


func _run() -> void:
	Settings.set_locale("en")
	var mb := AudioServer.get_bus_index(&"Music")
	if mb >= 0 and _arg("music", 0) == 0:
		AudioServer.set_bus_mute(mb, true)
	await _frames(2)
	main = get_tree().root.find_child("Main", true, false)
	var nn := "%02d_" % int(_arg("save", 1))
	var dir := DirAccess.open("res://src/dev/saves/")
	var path := ""
	for f in dir.get_files():
		if f.begins_with(nn) and f.ends_with(".json"):
			path = "res://src/dev/saves/" + f
	var save = SaveSystem.read(path)
	if _arg("lang", "en") != "en":
		Settings.set_locale(_arg("lang", "en"))
	main.call("load_run", save)
	await _frames(3)
	game = main.find_child("Game", true, false)
	game.achievement_toast.visible = false
	var end_at := float(_arg("seconds", 40))
	var t0 := Time.get_ticks_msec()
	var buys := int(_arg("buys", 2))
	_move_instant(Vector2(420, 300))
	while true:
		await _frames(1)
		var ups: Control = game.upgrade_screen
		var summ: Control = game.phase_summary
		if game.phase_timer.time_left > 0.0 and not game.phase_timer.is_stopped():
			await _play_phase()
		elif summ.visible:
			await _secs(float(_arg("summary_hold", 2.5)))
			await _click_control(summ.get("_continue_button"))
			await _secs(0.6)
		elif ups.visible:
			await _secs(1.0)
			var steps := int(_arg("tree_scroll", 0))
			if steps > 0:
				await _glide(Vector2(420, 200), 20)
				for i in steps:
					await _wheel(MOUSE_BUTTON_WHEEL_DOWN)
					await _secs(0.5)
				await _secs(1.0)
				for i in steps:
					await _wheel(MOUSE_BUTTON_WHEEL_UP)
					await _secs(0.25)
			var bought := 0
			while bought < buys:
				var ok: bool = await _buy_one()
				if not ok:
					break
				bought += 1
			await _secs(0.6)
			await _click_control(ups.get("_start_button"))
			await _secs(1.0)
		if _frames_elapsed() > end_at:
			break
		if Engine.get_frames_drawn() > int(end_at * 30.0) + 300:
			break
	get_tree().quit()


var _frame_count := 0
func _process(_d: float) -> void:
	_frame_count += 1


func _frames_elapsed() -> float:
	return _frame_count / 30.0


func _play_phase() -> void:
	var cps := float(_arg("cps", 7.0))
	var board: Node2D = game.board
	while not game.phase_timer.is_stopped() and _frames_elapsed() < float(_arg("seconds", 40)):
		var cells: Array = board.model.occupied_cells()
		if cells.is_empty():
			await _frames(1)
			continue
		var best: Vector2i = cells[0]
		var best_d := INF
		for c: Vector2i in cells:
			var card = board.get_item(c)
			if card == null or not game.progression.is_tool_unlocked(card.source.tool):
				continue
			var p: Vector2 = board.position + board.cell_to_local(c)
			var d: float = p.distance_to(mouse) + randf() * 30.0
			if d < best_d:
				best_d = d
				best = c
		if best_d == INF:
			await _frames(5)
			continue
		var target: Vector2 = board.position + board.cell_to_local(best) + Vector2(randf_range(-4, 4), randf_range(-6, 2))
		await _glide(target, clampi(int(mouse.distance_to(target) / 18.0) + 3, 4, 12))
		var guard := 0
		while board.get_item(best) != null and not game.phase_timer.is_stopped() and guard < 40:
			await _press()
			await _frames(maxi(1, int(30.0 / cps) - 1 + (randi() % 2)))
			guard += 1
	await _secs(0.3)


func _buy_one() -> bool:
	var ups: Control = game.upgrade_screen
	var tree_view = ups.get("_tree_view")
	var candidates: Array = []
	for u: UpgradeNode in game.database.upgrades:
		if game.progression.can_buy(u, game.inventory):
			var v: Control = tree_view.get_view(u.id)
			if v and v.is_visible_in_tree():
				candidates.append(v)
	if candidates.is_empty():
		return false
	var v: Control = candidates[randi() % candidates.size()]
	await _click_control(v)
	await _secs(0.9)
	var buy: Button = ups.get("_buy_button")
	if buy.visible and not buy.disabled:
		await _click_control(buy)
		await _secs(0.8)
		return true
	return false


func _click_control(c: Control) -> void:
	if c == null:
		return
	var r := c.get_global_rect()
	await _glide(r.get_center() + Vector2(randf_range(-2, 2), randf_range(-1, 1)), 14)
	await _frames(3)
	await _press()


func _move_instant(p: Vector2) -> void:
	mouse = p
	_send_motion()


func _glide(to: Vector2, frames: int) -> void:
	var from := mouse
	for i in range(1, frames + 1):
		var t := float(i) / frames
		t = t * t * (3.0 - 2.0 * t)
		mouse = from.lerp(to, t)
		_send_motion()
		await _frames(1)


func _send_motion() -> void:
	var w := mouse * SCALE
	Input.warp_mouse(w)
	var e := InputEventMouseMotion.new()
	e.position = w
	e.global_position = w
	Input.parse_input_event(e)


func _wheel(button: MouseButton) -> void:
	var w := mouse * SCALE
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = button
		e.pressed = pressed
		e.factor = 1.0
		e.position = w
		e.global_position = w
		Input.parse_input_event(e)
		await _frames(1)


func _press() -> void:
	var w := mouse * SCALE
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = w
		e.global_position = w
		Input.parse_input_event(e)
		await _frames(1)
