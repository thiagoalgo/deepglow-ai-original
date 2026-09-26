class_name Game
extends Node2D
## Run root. Owns the run state (inventory, progression, needs) and the
## scene parts the states drive. Rules live in the states under states/.

@export var database: GameDatabase
@export var card_scene: PackedScene

var inventory: Inventory
var progression: ProgressionState
var needs: Needs
var phase_number: int = 0
var run_seed: int
var current_plan: PhasePlan

@onready var board: Board = %Board
@onready var effects: Node2D = %Effects
@onready var state_machine: StateMachine = %StateMachine
@onready var phase_timer: Timer = %PhaseTimer
@onready var hud: Hud = %Hud
@onready var phase_summary: PhaseSummary = %PhaseSummary
@onready var upgrade_screen: UpgradeTreeScreen = %UpgradeTreeScreen
@onready var tool_cursor: ToolCursor = %ToolCursor


func _ready() -> void:
	assert(database != null, "Game requires a GameDatabase.")
	assert(card_scene != null, "Game requires card_scene.")
	_center_board()
	new_run()


## Resets all run state. Called on start (and in the future by "new game").
func new_run(p_seed: int = 0) -> void:
	run_seed = p_seed if p_seed != 0 else randi()
	phase_number = 0
	inventory = Inventory.new()
	progression = ProgressionState.new(database)
	needs = Needs.new()
	# Relay model signals to the global bus for decoupled UI.
	inventory.changed.connect(Events.inventory_changed.emit)
	needs.changed.connect(Events.needs_changed.emit)
	hud.setup(database, inventory)


## Seed for a given phase: stable per run, different per phase.
func get_phase_seed(number: int) -> int:
	return hash([run_seed, number])


func _center_board() -> void:
	var viewport_size := get_viewport_rect().size
	var board_size := Vector2(board.config.get_pixel_size())
	board.position = ((viewport_size - board_size) / 2.0).floor()
