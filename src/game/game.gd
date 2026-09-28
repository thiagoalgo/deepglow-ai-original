class_name Game
extends Node2D
## Run root. Owns the run state (inventory, progression, needs) and the
## scene parts the states drive. Rules live in the states under states/.
## Saving (M5): the run is saved between phases (see UpgradeState) and after each
## purchase; a loaded run resumes at the upgrade screen.

## The player asked to go back to the title menu (the run is already saved).
signal exit_requested

@export var database: GameDatabase
@export var card_scene: PackedScene

var inventory: Inventory
var progression: ProgressionState
var needs: Needs
var phase_number: int = 0
var run_seed: int
var current_plan: PhasePlan
## Biome shown on the background (reached by the levels invested in the tree).
var biome: Biome

var _pending_save: SaveGame

@onready var background: Sprite2D = %Background
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
		if achievement.is_unlocked(progression):
			unlocked.append(achievement.id)
	Platform.unlock_achievements(unlocked)


## Shows the current biome's background. Returns true when a new biome was
## reached since the last call (never on the first call of a run).
func apply_biome() -> bool:
	var current := progression.get_biome()
	var changed := biome != null and current != biome
	biome = current
	if current and current.background:
		background.texture = current.background
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
	apply_biome()


func _center_board() -> void:
	var viewport_size := get_viewport_rect().size
	var board_size := Vector2(board.config.get_pixel_size())
	board.position = ((viewport_size - board_size) / 2.0).floor()


func _on_board_cell_navigated(cell: Vector2i) -> void:
	tool_cursor.place_at(board.position + board.cell_to_local(cell))


func _on_upgrade_purchased(_upgrade: UpgradeNode, _new_level: int) -> void:
	game_audio.play_purchase()
	save_run()
	report_achievements()
