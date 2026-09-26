class_name StateMachine
extends Node
## Generic node-based state machine.
## Every direct child extending `State` is a state; the node name is its id.

signal state_changed(from_state: StringName, to_state: StringName)

@export var initial_state: State

var current_state: State
var _states: Dictionary[StringName, State] = {}


func _ready() -> void:
	for child: Node in get_children():
		if child is State:
			var state := child as State
			state.owner_node = owner
			state.transition_requested.connect(_on_transition_requested)
			_states[state.name] = state
	assert(initial_state != null, "StateMachine '%s' has no initial_state." % name)
	# Wait for the owner's _ready before entering the first state.
	await owner.ready
	current_state = initial_state
	current_state.enter()


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func transition_to(to_state: StringName, payload: Dictionary = {}) -> void:
	if not _states.has(to_state):
		push_error("Unknown state: %s" % to_state)
		return
	var from_name: StringName = current_state.name if current_state else &""
	if current_state:
		current_state.exit()
	current_state = _states[to_state]
	current_state.enter(payload)
	state_changed.emit(from_name, to_state)


func _on_transition_requested(to_state: StringName, payload: Dictionary) -> void:
	transition_to(to_state, payload)
