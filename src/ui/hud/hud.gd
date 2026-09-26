class_name Hud
extends CanvasLayer
## Debug/prototype HUD. Reacts only to Events (decoupled from Game).

@onready var _turn_label: Label = %TurnLabel
@onready var _cell_label: Label = %CellLabel


func _ready() -> void:
	Events.turn_started.connect(_on_turn_started)
	Events.cell_hovered.connect(_on_cell_hovered)
	Events.cell_hover_exited.connect(_on_cell_hover_exited)
	_turn_label.text = ""
	_cell_label.text = ""


func _on_turn_started(turn_number: int) -> void:
	_turn_label.text = tr(&"HUD_TURN") % turn_number


func _on_cell_hovered(cell: Vector2i) -> void:
	_cell_label.text = "%s%d" % [char(65 + cell.x), cell.y + 1]


func _on_cell_hover_exited() -> void:
	_cell_label.text = ""
