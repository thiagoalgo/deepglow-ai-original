class_name ToolCursor
extends CanvasLayer
## Software mouse cursor rendered in the 640x360 viewport (pixel-perfect,
## scales with the game). Shows the contextual tool (docs/game-design.md §4).

@export var pointer_texture: Texture2D
@export var pointer_hotspot: Vector2i = Vector2i.ZERO
@export var lock_texture: Texture2D
@export var lock_hotspot: Vector2i = Vector2i(12, 12)

var _hotspot: Vector2i = Vector2i.ZERO
## Keys/gamepad placed the cursor (place_at); cleared as soon as the mouse moves.
var _placed: bool = false
var _placed_position: Vector2 = Vector2.ZERO

@onready var _sprite: Sprite2D = %Sprite


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	show_pointer()


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_placed = false


func _process(_delta: float) -> void:
	var pointer := _placed_position if _placed else get_viewport().get_mouse_position()
	_sprite.position = (pointer - Vector2(_hotspot)).floor()


## Puts the cursor's hotspot at `pointer` (viewport coordinates) until the mouse moves.
func place_at(pointer: Vector2) -> void:
	_placed = true
	_placed_position = pointer


func show_pointer() -> void:
	_apply(pointer_texture, pointer_hotspot)


func show_tool(tool: ToolType) -> void:
	_apply(tool.cursor_texture, tool.cursor_hotspot)


func show_locked() -> void:
	_apply(lock_texture, lock_hotspot)


func _apply(texture: Texture2D, hotspot: Vector2i) -> void:
	_sprite.texture = texture
	_hotspot = hotspot
