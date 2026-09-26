class_name SourceCard
extends Node2D
## A source on the board: sprite + progress bar. Rarity is intentionally not
## shown (docs/game-design.md §3.1): the sprite itself communicates value.
## Holds the remaining "health" (clicks); game rules decide the damage.

signal depleted

const BAR_WIDTH := 14.0

var source: SourceType
var total_health: float = 1.0
var health: float = 1.0

var _shake_tween: Tween

@onready var _sprite: Sprite2D = %Sprite


func setup(p_source: SourceType, clicks: int) -> void:
	source = p_source
	total_health = float(clicks)
	health = total_health


func _ready() -> void:
	_sprite.texture = source.texture if source else null
	queue_redraw()


## Applies damage. Returns true when the source is depleted.
func hit(damage: float) -> bool:
	health = maxf(0.0, health - damage)
	queue_redraw()
	_shake()
	if health <= 0.0:
		depleted.emit()
		return true
	return false


## Plays the collected animation and frees the card.
func collect() -> void:
	if _shake_tween:
		_shake_tween.kill()
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, ^"scale", Vector2.ZERO, 0.15)
	tween.finished.connect(queue_free)


func _draw() -> void:
	if source == null:
		return
	if source.texture == null:
		draw_rect(Rect2(-5, -5, 10, 10), source.placeholder_color)
	if health < total_health:
		var bar := Rect2(-BAR_WIDTH / 2.0, 7, BAR_WIDTH, 2)
		draw_rect(bar, Palette.SHADOW_ABSOLUTE)
		draw_rect(Rect2(bar.position, Vector2(ceilf(BAR_WIDTH * health / total_health), 2)),
			Palette.VEGETATION_NEON_TEAL)


func _shake() -> void:
	if _shake_tween:
		_shake_tween.kill()
	_sprite.position = Vector2.ZERO
	_shake_tween = create_tween()
	_shake_tween.tween_property(_sprite, ^"position", Vector2(1, 0), 0.03)
	_shake_tween.tween_property(_sprite, ^"position", Vector2(-1, 0), 0.03)
	_shake_tween.tween_property(_sprite, ^"position", Vector2.ZERO, 0.03)
