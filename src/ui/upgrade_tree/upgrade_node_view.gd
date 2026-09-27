class_name UpgradeNodeView
extends BaseButton
## One node of the drawn upgrade tree: icon in a frame whose color shows the
## node state, plus "level/max" underneath. Choice nodes are octagons.

enum NodeState { LOCKED, AVAILABLE, AFFORDABLE, PARTIAL, MAXED }

const FRAME_SIZE := 32
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
## Mutually exclusive node whose rival was bought: drawn with a cross.
var blocked: bool = false
## Shown with the highlight ring (independent of keyboard focus).
var selected: bool = false:
	set(v):
		selected = v
		queue_redraw()

var _font: Font
var _font_size: int = 16


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


func refresh(progression: ProgressionState, inventory: Inventory) -> void:
	level = progression.get_level(upgrade.id)
	blocked = progression.is_blocked_by_choice(upgrade)
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
	# Choice nodes (mutually exclusive) get deeper stepped corners, a pixel "octagon".
	var steps := PackedInt32Array([2]) if upgrade.choice_group.is_empty() else PackedInt32Array([8, 6, 4, 2])
	PixelStyleBox.create(fill, color, 2, steps).draw(get_canvas_item(), rect)
	if upgrade.icon:
		var icon_pos := ((size - upgrade.icon.get_size()) / 2.0).floor()
		var tint := Color(1, 1, 1, 0.35) if state == NodeState.LOCKED else Color.WHITE
		draw_texture(upgrade.icon, icon_pos, tint)
	if blocked:
		_draw_cross(rect.grow(-6), Palette.LIGHT_PINK)
	if selected or has_focus():
		var ring := PixelStyleBox.create(Color.TRANSPARENT, Palette.LIGHT_BLUE_WHITE, 2, steps)
		ring.draw_center = false
		ring.draw(get_canvas_item(), rect.grow(4))
	# Level "n/max" under the node.
	var text := "%d/%d" % [level, upgrade.max_level]
	var text_width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x
	var baseline := Vector2(floorf((size.x - text_width) / 2.0), size.y + _font_size - 2)
	# Backdrop so connection lines never cross the text.
	draw_rect(Rect2(baseline.x - 2, size.y + 2, text_width + 4, _font_size - 2), Palette.SHADOW_BLUEBLACK)
	draw_string(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, color)


## Pixel "X" of 2x2 blocks (no antialiased diagonal lines) over a blocked node.
func _draw_cross(area: Rect2, color: Color) -> void:
	var steps := int(area.size.x / 2.0)
	for i: int in steps:
		var offset := Vector2(i * 2, i * 2)
		draw_rect(Rect2(area.position + offset, Vector2(2, 2)), color)
		draw_rect(Rect2(Vector2(area.end.x - 2 - i * 2, area.position.y + i * 2), Vector2(2, 2)), color)
