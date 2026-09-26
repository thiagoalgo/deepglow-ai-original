class_name ToolCursor
extends CanvasLayer
## Software mouse cursor rendered in the 640x360 viewport (pixel-perfect,
## scales with the game). Shows the contextual tool (docs/game-design.md §4).

@export var pointer_texture: Texture2D
@export var pointer_hotspot: Vector2i = Vector2i.ZERO
@export var lock_texture: Texture2D
@export var lock_hotspot: Vector2i = Vector2i(12, 12)

var _hotspot: Vector2i = Vector2i.ZERO

@onready var _sprite: Sprite2D = %Sprite


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	show_pointer()


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(_delta: float) -> void:
	_sprite.position = (get_viewport().get_mouse_position() - Vector2(_hotspot)).floor()


func show_pointer() -> void:
	_apply(pointer_texture, pointer_hotspot)


func show_tool(tool: ToolType) -> void:
	_apply(tool.cursor_texture, tool.cursor_hotspot)


func show_locked() -> void:
	_apply(lock_texture, lock_hotspot)


func _apply(texture: Texture2D, hotspot: Vector2i) -> void:
	_sprite.texture = texture
	_hotspot = hotspot
