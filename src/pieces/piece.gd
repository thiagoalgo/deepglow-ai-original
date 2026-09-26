class_name Piece
extends Node2D
## Visual representation of a piece on the board.
## Data comes from PieceData; the logical position (cell) is owned by Board.

signal move_finished

const MOVE_DURATION := 0.15

@export var data: PieceData:
	set(value):
		data = value
		if is_node_ready():
			_apply_data()

var cell: Vector2i

var _tween: Tween

@onready var _sprite: Sprite2D = %Sprite
@onready var _animation_player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	_apply_data()


func _apply_data() -> void:
	_sprite.texture = data.texture if data else null
	queue_redraw()


func _draw() -> void:
	# Placeholder until art exists: diamond in the piece color.
	if _sprite.texture != null or data == null:
		return
	var c := data.placeholder_color
	var pts := PackedVector2Array([Vector2(0, -6), Vector2(6, 0), Vector2(0, 6), Vector2(-6, 0)])
	draw_colored_polygon(pts, c)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Palette.SHADOW_ABSOLUTE, 1.0)


func play_spawn() -> void:
	if _animation_player.has_animation(&"spawn"):
		_animation_player.play(&"spawn")


func move_to(target: Vector2) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"position", target, MOVE_DURATION)
	_tween.finished.connect(move_finished.emit)


func despawn() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, ^"scale", Vector2.ZERO, 0.1)
	_tween.finished.connect(queue_free)
