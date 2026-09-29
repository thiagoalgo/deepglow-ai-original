extends Node
## Entry point and screen flow:
##   first launch: LanguageSelect -> TitleMenu;  later launches: TitleMenu
##   TitleMenu -> Game (continue the saved run) / Intro -> Game (new game) /
##   Intro -> TitleMenu ("Watch intro" / "Watch ending") / SettingsScreen / AchievementsScreen
##   Game "Menu" -> TitleMenu
## Screens are PackedScene exports that only emit signals; Main swaps them.

## Developer console, only in the editor and in exports with the "dev" feature
## tag (release presets exclude src/dev/, so it cannot ship by accident).
const DEV_CONSOLE := "res://src/dev/dev_console.gd"

@export var language_select_scene: PackedScene
@export var title_menu_scene: PackedScene
@export var settings_scene: PackedScene
@export var achievements_scene: PackedScene
@export var game_scene: PackedScene
@export var intro_scene: PackedScene
## Played by "Watch ending" (the Game plays it itself when the story ends).
@export var ending_sequence: IntroSequence
## Music for the menus (the Game switches tracks itself, see GameAudio).
@export var menu_music: AudioStream
## Night ambience, under the menus (in a run, the current biome's ambience).
@export var ambience: AudioStream

var _current_screen: Node


func _ready() -> void:
	# Closing the window goes through _quit() too (audio must stop first).
	get_tree().set_auto_accept_quit(false)
	if (OS.has_feature("editor") or OS.has_feature("dev")) and ResourceLoader.exists(DEV_CONSOLE):
		# In the root window (full resolution), outside the 640x360 game viewport.
		var console := (load(DEV_CONSOLE) as GDScript).new() as Node
		console.set(&"main", self)
		get_tree().root.add_child.call_deferred(console)
	Sound.play_ambience(ambience)
	if Settings.has_saved_locale():
		_show_title_menu()
	else:
		_show_language_select()


func _show_language_select() -> void:
	var screen := language_select_scene.instantiate() as LanguageSelect
	screen.language_confirmed.connect(_on_language_confirmed, CONNECT_ONE_SHOT)
	_switch_to(screen)


## `focus`: the sub-screen we come back from (its button keeps the focus).
func _show_title_menu(focus: StringName = &"") -> void:
	Sound.play_music(menu_music)
	Sound.play_ambience(ambience)
	var save := SaveSystem.read()
	var screen := title_menu_scene.instantiate() as TitleMenu
	var ending_unlocked := AchievementStore.new().has_achievement(Game.STORY_ACHIEVEMENT)
	screen.setup(save.phase_number + 1 if save else 0, focus, ending_unlocked)
	screen.continue_requested.connect(_start_game.bind(save), CONNECT_ONE_SHOT)
	screen.new_game_requested.connect(_on_new_game_requested, CONNECT_ONE_SHOT)
	screen.settings_requested.connect(_show_settings, CONNECT_ONE_SHOT)
	screen.achievements_requested.connect(_show_achievements, CONNECT_ONE_SHOT)
	screen.intro_requested.connect(_play_intro.bind(_show_title_menu), CONNECT_ONE_SHOT)
	screen.ending_requested.connect(play_ending, CONNECT_ONE_SHOT)
	screen.quit_requested.connect(_quit, CONNECT_ONE_SHOT)
	_switch_to(screen)


func _show_settings() -> void:
	var screen := settings_scene.instantiate() as SettingsScreen
	screen.closed.connect(_show_title_menu.bind(&"settings"), CONNECT_ONE_SHOT)
	_switch_to(screen)


func _show_achievements() -> void:
	var screen := achievements_scene.instantiate() as AchievementsScreen
	screen.closed.connect(_show_title_menu.bind(&"achievements"), CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	_switch_to(screen)


## Plays the intro, then calls `then` (skipping it also calls `then`).
func _play_intro(then: Callable) -> void:
	var intro := intro_scene.instantiate() as Intro
	intro.finished.connect(then, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	_switch_to(intro)


## Plays the intro (dev console), then back to the title menu.
func play_intro() -> void:
	_play_intro(_show_title_menu)


## Plays the ending ("Watch ending", dev console), then back to the title menu.
func play_ending() -> void:
	var intro := intro_scene.instantiate() as Intro
	intro.sequence = ending_sequence
	intro.finished.connect(_show_title_menu.bind(&"ending"), CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	_switch_to(intro)


## Starts the game screen; `save` null = new run.
func _start_game(save: SaveGame) -> void:
	var game := game_scene.instantiate() as Game
	if save:
		game.resume_from(save)
	game.exit_requested.connect(_show_title_menu, CONNECT_ONE_SHOT)
	_switch_to(game)


## Makes `save` the current run and opens it (dev console: load_save).
func load_run(save: SaveGame) -> void:
	SaveSystem.write(save)
	_start_game(save)


## Quits like closing the window (dev console: exit, clear_cfg).
func quit() -> void:
	_quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit()


## Stops the audio and waits a few frames so the audio server can release its
## playbacks before the engine shuts down.
func _quit() -> void:
	Sound.stop_all()
	for i: int in 3:
		await get_tree().process_frame
	get_tree().quit()


func _switch_to(screen: Node) -> void:
	if _current_screen:
		_current_screen.queue_free()
	_current_screen = screen
	add_child(screen)


func _on_language_confirmed(_locale: String) -> void:
	_show_title_menu()


func _on_new_game_requested() -> void:
	SaveSystem.delete()
	_play_intro(_start_game.bind(null))
