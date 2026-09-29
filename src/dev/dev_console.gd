extends CanvasLayer
## Developer terminal (dev builds only; no class_name so nothing else can depend
## on it). Main creates it only when the game runs from the editor or from an
## export with the "dev" feature tag; release presets exclude src/dev/ entirely,
## so it never ships (see AGENTS.md, "Developer console").
## It is drawn over the game area at the window resolution (in its own
## SubViewport, not in the 640x360 game viewport), so the monospace font stays
## crisp, and goes through a copy of the game's CRT filter (keep_alpha) so it
## looks part of the same screen. Being a dev tool it ignores the
## palette/pixel-art rules on purpose.
##
## Ctrl+Space (or F1) opens/closes it; Esc or a click outside it closes it. The game is paused while it
## is open. Up/Down browse the command history. Type "help" or "?" for the list.
## New command = one entry in _register_commands() + a _cmd_* method.

const SAVES_DIR := "res://src/dev/saves/"
const MAX_LINES := 200
const HISTORY_SIZE := 30
## Fraction of the game area height taken by the terminal.
const HEIGHT := 0.4
## Font size = game area height / this (18 px at 1080p), never below MIN_FONT_SIZE.
const FONT_DIVISOR := 60
const MIN_FONT_SIZE := 14
## JetBrains Mono (SIL OFL, license next to the font), no ligatures.
const FONT_PATH := "res://src/dev/fonts/JetBrainsMonoNL-Regular.ttf"
## Fallback if the font file is missing: monospace fonts of the OS.
const FONT_NAMES: PackedStringArray = ["Monaco", "Menlo", "Consolas", "DejaVu Sans Mono", "monospace"]
const PROMPT := ">>> "
const TEXT_COLOR := Color("39ff14")
const DIM_TEXT_COLOR := Color("1f9e0c")
## 25% transparent background. Drawn into a transparent SubViewport, the alpha
## is applied twice (a² ends up in the texture), so 0.87 shows as ~0.75.
const BACKGROUND := Color(0.0, 0.03, 0.0, 0.87)

## Main (set by Main before adding the console to the window).
var main: Node

## name -> {"run": Callable, "usage": String, "help": String}
var _commands: Dictionary[String, Dictionary] = {}
var _history: PackedStringArray = []
var _history_index: int = 0
var _lines: PackedStringArray = []
var _was_paused: bool = false

## Covers the game area; draws _view through the CRT filter.
var _frame: SubViewportContainer
var _view: SubViewport
var _panel: PanelContainer
var _font: Font
var _log: Label
var _field: LineEdit
var _prompt: Label


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_register_commands()
	_print("Deepglow dev console. Type help or ? for the commands.")
	_frame.hide()


func _process(_delta: float) -> void:
	if _frame.visible:
		_fit_to_game()


func _input(event: InputEvent) -> void:
	# A click outside the terminal closes it, like Esc (and is not passed to the game).
	var click := event as InputEventMouseButton
	if click and click.pressed and _frame.visible:
		var panel_rect := Rect2(_frame.position + _panel.position, _panel.size)
		if not panel_rect.has_point(click.position):
			_set_open(false)
			get_viewport().set_input_as_handled()
		else:
			# Anywhere inside: back to typing (the click itself still reaches the field).
			_field.grab_focus.call_deferred()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	# Raw keys on purpose: this dev-only tool must not add actions to the game.
	var toggle := key.keycode == KEY_F1 or (key.keycode == KEY_SPACE and key.ctrl_pressed)
	if toggle:
		_set_open(not _frame.visible)
		get_viewport().set_input_as_handled()
	elif _frame.visible and key.keycode == KEY_ESCAPE:
		_set_open(false)
		get_viewport().set_input_as_handled()


## Runs one command line (also usable from code/tests).
func execute(line: String) -> void:
	var parts := line.strip_edges().split(" ", false)
	if parts.is_empty():
		return
	_print(PROMPT + line.strip_edges())
	var command := parts[0].to_lower()
	if not _commands.has(command):
		_print("Unknown command: %s (type help)" % command)
		return
	_commands[command]["run"].call(parts.slice(1))


# --- Commands -------------------------------------------------------------------

func _register_commands() -> void:
	_add("help", "help", "lists the commands", _cmd_help)
	_add("?", "?", "same as help", _cmd_help)
	_add("load_save", "load_save <NN>", "loads test save NN (01 = new run, 02-06 = biomes)", _cmd_load_save,
		_save_names)
	_add("set", "set <resource> <amount>", "sets a resource amount (e.g. set gold 372)", _cmd_set,
		_resource_ids)
	_add("intro", "intro", "plays the intro (over the game in a run)", _cmd_intro)
	_add("ending", "ending", "plays the ending (over the game in a run; nothing is bought)", _cmd_ending)
	_add("fullscreen", "fullscreen", "toggles fullscreen / window", _cmd_fullscreen)
	_add("mute", "mute", "toggles all sound on/off (not saved)", _cmd_mute)
	_add("clear_achievements", "clear_achievements", "forgets every achievement and badge", _cmd_clear_achievements)
	_add("reset", "reset", "closes and reopens the game (save and settings kept)", _cmd_reset)
	_add("clear_cfg", "clear_cfg", "deletes settings.cfg, closes and reopens the game", _cmd_clear_cfg)
	_add("exit", "exit", "quits the game", _cmd_exit)


## `values` (optional) lists the accepted arguments, shown under the command in help.
func _add(command: String, usage: String, help: String, run: Callable,
		values: Callable = Callable()) -> void:
	_commands[command] = {"run": run, "usage": usage, "help": help, "values": values}


func _cmd_help(_args: PackedStringArray) -> void:
	for command: String in _commands:
		if command != "?":
			_print("  %s - %s" % [_commands[command]["usage"], _commands[command]["help"]])
			var values: Callable = _commands[command]["values"]
			if values.is_valid():
				_print("      " + ", ".join(values.call() as PackedStringArray))


func _cmd_load_save(args: PackedStringArray) -> void:
	if args.size() != 1 or not args[0].is_valid_int():
		_print("Usage: load_save <NN>  (%s)" % ", ".join(_save_names()))
		return
	var prefix := "%02d_" % args[0].to_int()
	for file: String in _save_files():
		if file.begins_with(prefix):
			var save := SaveSystem.read(SAVES_DIR + file)
			if save == null:
				_print("Could not read " + file)
				return
			_print("Loading " + file)
			_set_open(false)
			get_tree().paused = false
			main.call(&"load_run", save)
			return
	_print("No save %s (%s)" % [args[0], ", ".join(_save_names())])


func _cmd_set(args: PackedStringArray) -> void:
	if args.size() != 2 or not args[1].is_valid_int() or args[1].to_int() < 0:
		_print("Usage: set <resource> <amount>  (%s)" % ", ".join(_resource_ids()))
		return
	var game := _game()
	if game == null:
		_print("Start or continue a run first.")
		return
	var id := StringName(args[0].to_lower())
	if game.database.get_resource(id) == null:
		_print("Unknown resource %s (%s)" % [id, ", ".join(_resource_ids())])
		return
	game.inventory.add(id, args[1].to_int() - game.inventory.get_amount(id))
	_print("%s = %d" % [id, game.inventory.get_amount(id)])
	# Between phases the run is saved and the tree screen shows the new amount.
	if game.upgrade_screen.visible:
		game.upgrade_screen.refresh()
		game.save_run()


func _cmd_fullscreen(_args: PackedStringArray) -> void:
	# Same as F11 / the Settings row (saved in settings.cfg).
	Settings.set_fullscreen(not Settings.fullscreen)
	_print("fullscreen = %s" % Settings.fullscreen)


func _cmd_intro(_args: PackedStringArray) -> void:
	_set_open(false)
	var game := _game()
	if game:
		game.play_cutscene()
	else:
		main.call(&"play_intro")


func _cmd_ending(_args: PackedStringArray) -> void:
	_set_open(false)
	var game := _game()
	if game:
		game.play_ending()
	else:
		main.call(&"play_ending")


func _cmd_mute(_args: PackedStringArray) -> void:
	# The Master bus (every other bus feeds it); volumes in Settings stay as they are.
	var master := AudioServer.get_bus_index(&"Master")
	AudioServer.set_bus_mute(master, not AudioServer.is_bus_mute(master))
	_print("sound %s" % ("off" if AudioServer.is_bus_mute(master) else "on"))


func _cmd_clear_achievements(_args: PackedStringArray) -> void:
	AchievementStore.new().clear()
	_print("Achievements and badges cleared.")


func _cmd_reset(_args: PackedStringArray) -> void:
	_reopen("Reopening...")


func _cmd_clear_cfg(_args: PackedStringArray) -> void:
	Settings.reset()
	_reopen("Settings deleted, reopening...")


## Closes and reopens the program: starts a new instance first, then quits.
## From the editor the new process runs on its own (outside the debugger), so it
## needs the project path. If the new instance cannot start, restarts in place.
func _reopen(message: String) -> void:
	var args := OS.get_cmdline_args()
	if OS.has_feature("editor"):
		args = PackedStringArray(["--path", ProjectSettings.globalize_path("res://")]) + args
	if OS.create_instance(args) <= 0:
		_print("Could not reopen the program, restarting in place...")
		_restart()
		return
	_print(message)
	main.call(&"quit")


## Fallback: reloads the main scene in the same process (the autoloads stay;
## the new Main creates a new console, so this one goes away).
func _restart() -> void:
	get_tree().paused = false
	Sound.stop_all()
	get_tree().reload_current_scene()
	queue_free()


func _cmd_exit(_args: PackedStringArray) -> void:
	main.call(&"quit")


# --- Helpers --------------------------------------------------------------------

func _game() -> Game:
	for child: Node in main.get_children():
		if child is Game:
			return child as Game
	return null


## Ids accepted by "set" (from the game database, also before a run starts).
func _resource_ids() -> PackedStringArray:
	var database := load("res://data/game_database.tres") as GameDatabase
	var ids: PackedStringArray = []
	for resource: ResourceType in database.resources:
		ids.append(String(resource.id))
	return ids


func _save_files() -> PackedStringArray:
	var files: PackedStringArray = []
	for file: String in DirAccess.get_files_at(SAVES_DIR):
		if file.ends_with(".json"):
			files.append(file)
	files.sort()
	return files


func _save_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for file: String in _save_files():
		names.append(file.get_basename())
	return names


func _set_open(open: bool) -> void:
	if open == _frame.visible:
		return
	_frame.visible = open
	if open:
		_apply_font_size()
		_was_paused = get_tree().paused
		get_tree().paused = true
		_field.clear()
		_field.grab_focus()
	else:
		_field.release_focus()
		get_tree().paused = _was_paused


func _print(text: String) -> void:
	for line: String in text.split("\n"):
		_lines.append(line)
	while _lines.size() > MAX_LINES:
		_lines.remove_at(0)
	if _log:
		_log.text = "\n".join(_lines)
		_scroll_to_end.call_deferred()


func _on_submitted(text: String) -> void:
	_field.clear()
	if text.strip_edges().is_empty():
		return
	_history.append(text)
	if _history.size() > HISTORY_SIZE:
		_history.remove_at(0)
	_history_index = _history.size()
	execute(text)
	if _frame.visible:
		_field.grab_focus.call_deferred()


func _on_input_gui(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or _history.is_empty():
		return
	if key.keycode == KEY_UP:
		_history_index = maxi(_history_index - 1, 0)
	elif key.keycode == KEY_DOWN:
		_history_index = mini(_history_index + 1, _history.size())
	else:
		return
	_field.text = _history[_history_index] if _history_index < _history.size() else ""
	_field.caret_column = _field.text.length()
	_field.accept_event()


func _build_ui() -> void:
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH) as Font
	else:
		var system_font := SystemFont.new()
		system_font.font_names = FONT_NAMES
		_font = system_font
	_frame = SubViewportContainer.new()
	_frame.stretch = true
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_view = SubViewport.new()
	_view.transparent_bg = true
	_view.disable_3d = true
	_frame.add_child(_view)
	var screen := _game_screen()
	if screen and screen.material is ShaderMaterial:
		var crt := (screen.material as ShaderMaterial).duplicate() as ShaderMaterial
		crt.set_shader_parameter(&"keep_alpha", true)
		_frame.material = crt
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_panel.anchor_bottom = HEIGHT
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var background := StyleBoxFlat.new()
	background.bg_color = BACKGROUND
	background.border_color = DIM_TEXT_COLOR
	background.border_width_bottom = 2
	background.set_content_margin_all(10)
	_panel.add_theme_stylebox_override(&"panel", background)
	_view.add_child(_panel)
	var stack := VBoxContainer.new()
	_panel.add_child(stack)
	_log = Label.new()
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.clip_text = true
	_log.add_theme_font_override(&"font", _font)
	_log.add_theme_color_override(&"font_color", TEXT_COLOR)
	stack.add_child(_log)
	# Command line: ">>> " prompt + a borderless field, like a shell.
	var command_line := HBoxContainer.new()
	command_line.add_theme_constant_override(&"separation", 0)
	stack.add_child(command_line)
	_prompt = Label.new()
	_prompt.text = PROMPT
	_prompt.add_theme_font_override(&"font", _font)
	_prompt.add_theme_color_override(&"font_color", TEXT_COLOR)
	command_line.add_child(_prompt)
	_field = LineEdit.new()
	_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field.context_menu_enabled = false
	# Keep typing after Enter (the next command goes in the same box).
	_field.keep_editing_on_text_submit = true
	var no_box := StyleBoxEmpty.new()
	for style: StringName in [&"normal", &"focus", &"read_only"]:
		_field.add_theme_stylebox_override(style, no_box)
	_field.add_theme_font_override(&"font", _font)
	_field.add_theme_color_override(&"font_color", TEXT_COLOR)
	_field.add_theme_color_override(&"font_placeholder_color", DIM_TEXT_COLOR)
	_field.add_theme_color_override(&"caret_color", TEXT_COLOR)
	_field.text_submitted.connect(_on_submitted)
	_field.gui_input.connect(_on_input_gui)
	command_line.add_child(_field)
	_log.text = "\n".join(_lines)
	_apply_font_size()


## The game image on screen (App's SubViewportContainer, scaled and centred).
func _game_screen() -> Control:
	return main.get_viewport().get_parent() as Control if main else null


## Keeps the terminal exactly over the game image and the filter in sync with
## the game's (F2 / Settings).
func _fit_to_game() -> void:
	var screen := _game_screen()
	if screen == null:
		return
	_frame.position = screen.global_position
	_frame.size = screen.size * screen.scale
	var crt := _frame.material as ShaderMaterial
	if crt:
		crt.set_shader_parameter(&"enabled", (screen.material as ShaderMaterial).get_shader_parameter(&"enabled"))


## Font size follows the game area height, so it reads the same at any resolution.
func _apply_font_size() -> void:
	_fit_to_game()
	var size := maxi(MIN_FONT_SIZE, int(_frame.size.y / FONT_DIVISOR))
	_log.add_theme_font_size_override(&"font_size", size)
	_field.add_theme_font_size_override(&"font_size", size)
	_prompt.add_theme_font_size_override(&"font_size", size)
	_scroll_to_end.call_deferred()


## Shows the newest lines: skips the ones that do not fit above them.
func _scroll_to_end() -> void:
	_log.lines_skipped = 0
	_log.lines_skipped = maxi(0, _log.get_line_count() - _log.get_visible_line_count())
