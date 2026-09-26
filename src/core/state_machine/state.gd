class_name State
extends Node
## Base state for StateMachine. Extend it and override the virtual methods.
## To change state, emit `transition_requested` with the target node name.

signal transition_requested(to_state: StringName, payload: Dictionary)

## The machine's "owner" (e.g. Game). Set by the StateMachine.
var owner_node: Node


func enter(_payload: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass


func update(_delta: float) -> void:
	pass


func request_transition(to_state: StringName, payload: Dictionary = {}) -> void:
	transition_requested.emit(to_state, payload)
