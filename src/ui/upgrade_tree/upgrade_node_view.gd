class_name UpgradeNodeView
extends BaseButton
## One node of the drawn upgrade tree: icon (20x20, never scaled) in a frame
## whose color shows the node state, plus one pip per level underneath (filled
## = bought). Choice nodes are octagons.

enum NodeState { LOCKED, AVAILABLE, AFFORDABLE, PARTIAL, MAXED }

const FRAME_SIZE := 28
## Frame and selection ring line width.
const BORDER := 1
const PIP := 4
const PIP_GAP := 2
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



static func create(p_upgrade: UpgradeNode) -> UpgradeNodeView:
	var view := UpgradeNodeView.new()
	view.upgrade = p_upgrade
	view.custom_minimum_size = Vector2(FRAME_SIZE, FRAME_SIZE)
	view.size = view.custom_minimum_size
	view.focus_mode = Control.FOCUS_ALL
	view.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return view


func _ready() -> void:
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
	var steps := PackedInt32Array([2, 1]) if upgrade.choice_group.is_empty() \
		else PackedInt32Array([6, 5, 4, 3, 2, 1])
	PixelStyleBox.create(fill, color, BORDER, steps, 1).draw(get_canvas_item(), rect)
	if upgrade.icon:
		var icon_pos := ((size - upgrade.icon.get_size()) / 2.0).floor()
		var tint := Color(1, 1, 1, 0.35) if state == NodeState.LOCKED else Color.WHITE
		draw_texture(upgrade.icon, icon_pos, tint)
	if blocked:
		_draw_cross(rect.grow(-6), Palette.LIGHT_PINK)
	if selected or has_focus():
		var ring := PixelStyleBox.create(Color.TRANSPARENT, Palette.LIGHT_BLUE_WHITE, BORDER, steps, 1)
		ring.draw_center = false
		ring.draw(get_canvas_item(), rect.grow(3))
	# One pip per level under the node: filled = bought.
	var total := upgrade.max_level * PIP + (upgrade.max_level - 1) * PIP_GAP
	var x := floorf((size.x - total) / 2.0)
	for i: int in upgrade.max_level:
		var pip := Rect2(x + i * (PIP + PIP_GAP), size.y + 3, PIP, PIP)
		draw_rect(pip.grow(1), Palette.SHADOW_ABSOLUTE)
		draw_rect(pip, color if i < level else Palette.SHADOW_LIFTED)


## Pixel "X" of 2x2 blocks (no antialiased diagonal lines) over a blocked node.
func _draw_cross(area: Rect2, color: Color) -> void:
	var steps := int(area.size.x / 2.0)
	for i: int in steps:
		var offset := Vector2(i * 2, i * 2)
		draw_rect(Rect2(area.position + offset, Vector2(2, 2)), color)
		draw_rect(Rect2(Vector2(area.end.x - 2 - i * 2, area.position.y + i * 2), Vector2(2, 2)), color)
