class_name Game
extends Node2D
## Run root. Owns the run state (inventory, progression, needs) and the
## scene parts the states drive. Rules live in the states under states/.
## Saving (M5): the run is saved between phases (see UpgradeState) and after each
## purchase; a loaded run resumes at the upgrade screen.
## Buying the story's last node (UpgradeNode.ends_story, the Heart of Deepglow)
## plays the ending over the tree (game paused), then the choice groups open.
## Demo builds (Demo): reaching the gate of the first biome after the demo plays
## the demo ending, then the "thanks for playing" screen.

## The player asked to go back to the title menu (the run is already saved).
signal exit_requested

## Unlocked by finishing the story in any run: shows "Watch ending" on the title.
const STORY_ACHIEVEMENT := &"ACH_HEART_OF_DEEPGLOW"
## Drawn above the tree, the toasts and the HUD (the software cursor is hidden).
const ENDING_LAYER := 40

@export var database: GameDatabase
@export var card_scene: PackedScene
## The ending (an Intro screen playing `ending_sequence`).
@export var intro_scene: PackedScene
@export var ending_sequence: IntroSequence
@export var demo_ending_sequence: IntroSequence

var inventory: Inventory
var progression: ProgressionState
var needs: Needs
var phase_number: int = 0
var run_seed: int
var current_plan: PhasePlan
## Biome shown on the background (reached by the levels invested in the tree).
var biome: Biome

var _pending_save: SaveGame
## Demo: the demo ending already played in this run (or the save was past it).
var _demo_end_seen: bool = false

@onready var background: Sprite2D = %Background
@onready var ambient_particles: AmbientParticles = %AmbientParticles
@onready var board: Board = %Board
@onready var effects: Node2D = %Effects
@onready var state_machine: StateMachine = %StateMachine
@onready var phase_timer: Timer = %PhaseTimer
@onready var hud: Hud = %Hud
@onready var phase_summary: PhaseSummary = %PhaseSummary
@onready var upgrade_screen: UpgradeTreeScreen = %UpgradeTreeScreen
@onready var tool_cursor: ToolCursor = %ToolCursor
@onready var game_audio: GameAudio = %GameAudio
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var achievement_toast: AchievementToast = %AchievementToast
@onready var demo_end_screen: DemoEndScreen = %DemoEndScreen


func _ready() -> void:
	assert(database != null, "Game requires a GameDatabase.")
	assert(card_scene != null, "Game requires card_scene.")
	_center_board()
	board.cell_navigated.connect(_on_board_cell_navigated)
	if _pending_save:
		load_run(_pending_save)
		_pending_save = null
	else:
		new_run()


func _process(delta: float) -> void:
	# The Game is pausable: pause menu, cutscenes and the dev console don't count.
	if progression:
		progression.play_seconds += delta


## Applies Demo.get_last_biome() to the run (new/loaded run; dev console "demo").
func apply_demo() -> void:
	progression.demo_last_biome = Demo.get_last_biome()
	_demo_end_seen = progression.is_demo_complete()
	apply_biome()
	if upgrade_screen.visible:
		upgrade_screen.refresh()


## Call before the Game enters the tree to continue a saved run instead of a new one.
func resume_from(save: SaveGame) -> void:
	_pending_save = save


## Resets all run state (new game).
func new_run(p_seed: int = 0) -> void:
	_create_run_state(p_seed if p_seed != 0 else randi())
	_bind_run_state()


## Restores a saved run. The Setup state then opens the upgrade screen.
func load_run(save: SaveGame) -> void:
	_create_run_state(save.run_seed)
	phase_number = save.phase_number
	save.apply_to(inventory, progression)
	_bind_run_state()


## Reports every achievement the current progress meets (Platform ignores repeats).
func report_achievements() -> void:
	var unlocked: Array[StringName] = []
	for achievement: Achievement in database.achievements:
		if achievement.on_steam and achievement.is_unlocked(progression):
			unlocked.append(achievement.id)
	Platform.unlock_achievements(unlocked)
	# "My achievements" (kept across runs): announce only what is new.
	for new_unlock: Dictionary in AchievementStore.new().update(database, progression):
		Events.achievement_unlocked.emit(new_unlock["badge"], new_unlock["id"])


## Shows the current biome's background. Returns true when a new biome was
## reached since the last call (never on the first call of a run).
func apply_biome() -> bool:
	var current := progression.get_biome()
	var changed := biome != null and current != biome
	biome = current
	if current and current.background:
		background.texture = current.background
	if current and (changed or ambient_particles.effects.is_empty()):
		var layers: Array[AmbientEffect] = []
		for effect: Resource in current.ambient_effects:
			layers.append(effect as AmbientEffect)
		ambient_particles.effects = layers
	if current:
		board.set_ground(current.ground)
	if current and current.ambience:
		Sound.play_ambience(current.ambience)
	return changed


## Writes the current run to the save slot and shows the save badge on the
## upgrade screen (saves only happen between phases).
func save_run() -> void:
	var err := SaveSystem.write(SaveGame.capture(run_seed, phase_number, inventory, progression))
	if err != OK:
		push_error("Failed to save the run: %s" % error_string(err))
	upgrade_screen.show_save(err == OK)


## Seed for a given phase: stable per run, different per phase.
func get_phase_seed(number: int) -> int:
	return hash([run_seed, number])


func _create_run_state(p_seed: int) -> void:
	run_seed = p_seed
	phase_number = 0
	inventory = Inventory.new()
	progression = ProgressionState.new(database)
	needs = Needs.new()


func _bind_run_state() -> void:
	# Relay model signals to the global bus for decoupled UI.
	inventory.changed.connect(Events.inventory_changed.emit)
	needs.changed.connect(Events.needs_changed.emit)
	progression.upgrade_purchased.connect(_on_upgrade_purchased)
	hud.setup(database, inventory)
	biome = null
	apply_demo()


func _center_board() -> void:
	var viewport_size := get_viewport_rect().size
	var board_size := Vector2(board.config.get_pixel_size())
	board.position = ((viewport_size - board_size) / 2.0).floor()


func _on_board_cell_navigated(cell: Vector2i) -> void:
	tool_cursor.place_at(board.position + board.cell_to_local(cell))


## Plays the ending over the paused game. Awaitable (finishes when it is over).
## In a demo build, the demo ending.
func play_ending() -> void:
	await play_cutscene(demo_ending_sequence if Demo.is_active() else ending_sequence)


## Plays an Intro screen over the paused game; `sequence` null = the intro
## (dev console: intro / ending). Awaitable.
func play_cutscene(sequence: IntroSequence = null) -> void:
	var layer := CanvasLayer.new()
	layer.layer = ENDING_LAYER
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var intro := intro_scene.instantiate() as Intro
	if sequence:
		intro.sequence = sequence
	layer.add_child(intro)
	tool_cursor.hide()
	get_tree().paused = true
	add_child(layer)
	await intro.finished
	layer.queue_free()
	get_tree().paused = false
	tool_cursor.show()


func _on_upgrade_purchased(upgrade: UpgradeNode, new_level: int) -> void:
	game_audio.play_purchase()
	save_run()
	if upgrade.ends_story and new_level == 1:
		await play_ending()
		report_achievements()
		achievement_toast.notify(tr(&"UI_NEW_PATHS_TITLE"), tr(&"UI_NEW_PATHS_TEXT"))
		return
	if not _demo_end_seen and progression.is_demo_complete():
		_demo_end_seen = true
		await play_ending()
		report_achievements()
		upgrade_screen.hide_details()
		demo_end_screen.open(progression.play_seconds, progression.phases_played)
		return
	report_achievements()
