class_name FloatingText
extends Node2D
## "+2 [icon]" popup that rises and fades, then frees itself. Alert popups
## (weak hits, reduced yields) use the `FloatingAlertLabel` theme variation.

const RISE := 20.0
const DURATION := 0.8


static func spawn(parent: Node, at: Vector2, text: String, icon: Texture2D = null,
		variation: StringName = &"FloatingLabel") -> FloatingText:
	var popup := FloatingText.new()
	popup.position = at.floor()
	popup.z_index = 20
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.position = Vector2(-20, -28)
	popup.add_child(label)
	if icon:
		var sprite := Sprite2D.new()
		sprite.texture = icon
		sprite.centered = false
		sprite.position = Vector2(8, -20)
		popup.add_child(sprite)
	parent.add_child(popup)
	popup._animate()
	return popup


func _animate() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, ^"position:y", position.y - RISE, DURATION)
	tween.tween_property(self, ^"modulate:a", 0.0, DURATION).set_delay(DURATION * 0.4)
	tween.chain().tween_callback(queue_free)
