extends Node
## Global signal bus (autoload "Events").
##
## Use ONLY for communication between systems that don't know each other
## (e.g. Board -> HUD). Parent/child communication must use direct signals
## or method calls. Never store state here.

@warning_ignore_start("unused_signal")

# --- Board ---
signal cell_hovered(cell: Vector2i)
signal cell_hover_exited
signal cell_selected(cell: Vector2i)

# --- Pieces ---
signal piece_placed(piece: Piece, cell: Vector2i)
signal piece_removed(piece: Piece, cell: Vector2i)

# --- Game flow ---
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal game_over(result: Dictionary)

@warning_ignore_restore("unused_signal")
