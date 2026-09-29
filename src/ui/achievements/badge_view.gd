class_name BadgeView
extends BaseButton
## A badge: pixel-art shield (heraldic "brasão") with an icon in the middle.
## Unlocked = colored border + icon; locked = dark shield + icon silhouette.
## Focusable (keyboard/gamepad) and hoverable; the screen shows its details.

## Shield size; the lower part narrows to a point in 2 px steps.
const SIZE := Vector2i(36, 42)
## Rows (from the top) that keep the full width before the point starts.
const STRAIGHT := 24
const BORDER := 2
const SILHOUETTE := preload("res://src/fx/silhouette.gdshader")

var unlocked: bool = false
var border_color: Color = Palette.LIGHT_AMBER
var icon: Texture2D

var _icon_rect: TextureRect


static func create(p_icon: Texture2D, p_border: Color, p_unlocked: bool) -> BadgeView:
	var badge := BadgeView.new()
	badge.icon = p_icon
	badge.border_color = p_border
	badge.unlocked = p_unlocked
	badge.custom_minimum_size = Vector2(SIZE)
	badge.focus_mode = Control.FOCUS_ALL
	return badge


func _ready() -> void:
	_icon_rect = TextureRect.new()
	_icon_rect.texture = icon
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon:
		_icon_rect.size = icon.get_size()
		_icon_rect.position = (Vector2(SIZE.x, STRAIGHT + 4) - icon.get_size()) / 2.0
		_icon_rect.position = _icon_rect.position.floor()
	if not unlocked:
		var silhouette := ShaderMaterial.new()
		silhouette.shader = SILHOUETTE
		silhouette.set_shader_parameter(&"tint", Palette.STRUCTURE_DEEP_BLUE)
		_icon_rect.material = silhouette
	add_child(_icon_rect)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func _draw() -> void:
	var highlighted := has_focus() or is_hovered()
	if highlighted:
		_draw_shield(-2, Palette.LIGHT_BLUE_WHITE)
	_draw_shield(0, border_color if unlocked else Palette.SHADOW_LIFTED)
	_draw_shield(BORDER, Palette.SHADOW_DEEP if unlocked else Palette.SHADOW_BLUEBLACK)
	if unlocked:
		# A lit band under the top edge (light from the top-left).
		_draw_band(BORDER, Palette.SHADOW_LIFTED)


## The shield shape shrunk by `inset` pixels (negative = grown), row by row.
func _draw_shield(inset: int, color: Color) -> void:
	for y: int in range(inset, SIZE.y - inset):
		var side := _side(y) + inset
		var width := SIZE.x - side * 2
		if width > 0:
			draw_rect(Rect2(side, y, width, 1), color)


func _draw_band(inset: int, color: Color) -> void:
	for y: int in range(inset, inset + 2):
		var side := _side(y) + inset
		draw_rect(Rect2(side, y, SIZE.x - side * 2, 1), color)


## Horizontal cut of the outline at row `y`: cut top corners, then the point.
func _side(y: int) -> int:
	if y < 2:
		return 2 - y
	if y < STRAIGHT:
		return 0
	# Narrow by 2 px every 2 rows (a stepped 45° edge) down to the point.
	return (floori((y - STRAIGHT) / 2.0) + 1) * 2 - 1
