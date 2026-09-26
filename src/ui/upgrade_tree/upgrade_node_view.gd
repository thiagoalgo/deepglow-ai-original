class_name UpgradeNodeView
extends BaseButton
## One node of the drawn upgrade tree: icon in a frame whose color shows the
## node state, plus "level/max" underneath. Choice nodes are octagons.

enum NodeState { LOCKED, AVAILABLE, AFFORDABLE, PARTIAL, MAXED }

const FRAME_SIZE := 16
const STATE_COLORS := {
	NodeState.LOCKED: Palette.SHADOW_LIFTED,
	NodeState.AVAILABLE: Palette.STRUCTURE_MID_BLUE,
	NodeState.AFFORDABLE: Palette.VEGETATION_NEON_TEAL,
	NodeState.PARTIAL: Palette.LIGHT_AMBER,
	NodeState.MAXED: Palette.LIGHT_SULFUR_YELLOW,
}

var upgrade: UpgradeNode
var state: NodeState = NodeState.LOCKED
var level: int = 0

var _font: Font
var _font_size: int = 8


static func create(p_upgrade: UpgradeNode) -> UpgradeNodeView:
	var view := UpgradeNodeView.new()
	view.upgrade = p_upgrade
	view.custom_minimum_size = Vector2(FRAME_SIZE, FRAME_SIZE)
	view.size = view.custom_minimum_size
	view.focus_mode = Control.FOCUS_ALL
	view.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return view


func _ready() -> void:
	_font = get_theme_default_font()
	_font_size = get_theme_default_font_size()
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(grab_focus)


func refresh(progression: ProgressionState, inventory: Inventory) -> void:
	level = progression.get_level(upgrade.id)
	if progression.is_maxed(upgrade):
		state = NodeState.MAXED
	elif progression.can_buy(upgrade, inventory):
		state = NodeState.AFFORDABLE
	elif level > 0:
		state = NodeState.PARTIAL
	elif progression.is_available(upgrade):
		state = NodeState.AVAILABLE
	else:
		state = NodeState.LOCKED
	queue_redraw()


func get_state_color() -> Color:
	return STATE_COLORS[state]


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var color := get_state_color()
	var fill := Palette.SHADOW_DEEP if state != NodeState.LOCKED else Palette.SHADOW_BLUEBLACK
	if upgrade.choice_group.is_empty():
		draw_rect(rect, fill)
		draw_rect(rect.grow(-0.5), color, false, 1.0)
	else:
		var pts := _octagon(rect)
		draw_colored_polygon(pts, fill)
		draw_polyline(pts + PackedVector2Array([pts[0]]), color, 1.0)
	if upgrade.icon:
		var icon_pos := ((size - upgrade.icon.get_size()) / 2.0).floor()
		var tint := Color(1, 1, 1, 0.35) if state == NodeState.LOCKED else Color.WHITE
		draw_texture(upgrade.icon, icon_pos, tint)
	if has_focus():
		draw_rect(rect.grow(1.5), Palette.LIGHT_BLUE_WHITE, false, 1.0)
	# Level "n/max" under the node.
	var text := "%d/%d" % [level, upgrade.max_level]
	var text_width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x
	var baseline := Vector2(floorf((size.x - text_width) / 2.0), size.y + _font_size - 1)
	# Backdrop so connection lines never cross the text.
	draw_rect(Rect2(baseline.x - 1, size.y + 1, text_width + 2, _font_size - 1), Palette.SHADOW_BLUEBLACK)
	draw_string(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, color)


static func _octagon(rect: Rect2) -> PackedVector2Array:
	var c := 4.0
	var p := rect.position
	var s := rect.size
	return PackedVector2Array([
		p + Vector2(c, 0), p + Vector2(s.x - c, 0), p + Vector2(s.x, c), p + Vector2(s.x, s.y - c),
		p + Vector2(s.x - c, s.y), p + Vector2(c, s.y), p + Vector2(0, s.y - c), p + Vector2(0, c),
	])
