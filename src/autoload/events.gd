extends Node
## Global signal bus (autoload "Events").
##
## Use ONLY for communication between systems that don't know each other
## (e.g. game states -> HUD). Parent/child communication must use direct
## signals or method calls. Never store state here.

@warning_ignore_start("unused_signal")

# --- Board ---
signal cell_hovered(cell: Vector2i)
signal cell_hover_exited
signal cell_selected(cell: Vector2i)

# --- Phase ---
signal phase_started(phase_number: int, duration: float)
signal phase_time_changed(time_left: float)
signal phase_ended(phase_number: int)
## Every valid click on a source (before it may be collected).
signal source_hit(source: SourceType, cell: Vector2i)
signal source_collected(source: SourceType, amount: int, cell: Vector2i)

# --- Player state ---
signal needs_changed(hunger: float, thirst: float)
signal inventory_changed(resource_id: StringName, amount: int)

@warning_ignore_restore("unused_signal")
