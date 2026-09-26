@tool
class_name PixelStyleBox
extends StyleBox
## Pixel-art box: flat fill, solid border and stepped ("pixel rounded") corners.
## Everything is drawn as axis-aligned rects on whole pixels, so there is no
## antialiasing and no off-palette blending. Used by the theme (panels, buttons)
## and by custom-drawn nodes (board cells, upgrade nodes, bars) via draw().

@export var bg_color: Color = Palette.SHADOW_BLUEBLACK
@export var draw_center: bool = true
@export var border_color: Color = Palette.STRUCTURE_INDIGO
@export_range(0, 8) var border_width: int = 2
## Horizontal cut of each corner step, from the outermost row inwards.
## [4, 2] cuts 4 px on the first `step` rows and 2 px on the next `step` rows.
@export var corner_steps: PackedInt32Array = PackedInt32Array([4, 2])
## Height (in pixels) of each corner step.
@export_range(1, 8) var step: int = 2


static func create(fill: Color, border: Color, width: int = 2,
		steps: PackedInt32Array = PackedInt32Array([2]), step_size: int = 2) -> PixelStyleBox:
	var box := PixelStyleBox.new()
	box.bg_color = fill
	box.border_color = border
	box.border_width = width
	box.corner_steps = steps
	box.step = step_size
	return box


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var r := Rect2i(Vector2i(rect.position.round()), Vector2i(rect.size.round()))
	if r.size.x <= 0 or r.size.y <= 0:
		return
	# Rows are grouped into runs with identical spans to keep the draw calls low.
	var run_start := 0
	var run_key := _row_spans(r.size, 0)
	for y: int in range(1, r.size.y + 1):
		var key: Array = _row_spans(r.size, y) if y < r.size.y else []
		if key != run_key:
			_draw_run(to_canvas_item, r, run_start, y - run_start, run_key)
			run_start = y
			run_key = key


## Left inset of the outer shape on row y.
func _inset(h: int, y: int) -> int:
	if y < 0 or y >= h:
		return 1 << 20
	var from_edge := mini(y, h - 1 - y)
	var index := from_edge / step
	return corner_steps[index] if index < corner_steps.size() else 0


## [outer_left, outer_right, inner_left, inner_right] for row y (inner = -1 if none).
func _row_spans(size: Vector2i, y: int) -> Array:
	var outer := _inset(size.y, y)
	var spans := [outer, size.x - 1 - outer, -1, -1]
	if border_width <= 0:
		spans[2] = outer
		spans[3] = size.x - 1 - outer
		return spans
	if y < border_width or y >= size.y - border_width:
		return spans
	var inner := 0
	for d: int in range(-border_width, border_width + 1):
		inner = maxi(inner, _inset(size.y, y + d))
	inner += border_width
	if inner <= size.x - 1 - inner:
		spans[2] = inner
		spans[3] = size.x - 1 - inner
	return spans


func _draw_run(ci: RID, r: Rect2i, y: int, h: int, spans: Array) -> void:
	if spans.is_empty() or h <= 0:
		return
	var top := r.position.y + y
	var x0: int = r.position.x
	var ol: int = spans[0]
	var orr: int = spans[1]
	var il: int = spans[2]
	var ir: int = spans[3]
	if ol > orr:
		return
	if il < 0:
		if border_width > 0:
			RenderingServer.canvas_item_add_rect(ci, Rect2(x0 + ol, top, orr - ol + 1, h), border_color)
		return
	if border_width > 0:
		if il > ol:
			RenderingServer.canvas_item_add_rect(ci, Rect2(x0 + ol, top, il - ol, h), border_color)
		if orr > ir:
			RenderingServer.canvas_item_add_rect(ci, Rect2(x0 + ir + 1, top, orr - ir, h), border_color)
	if draw_center:
		RenderingServer.canvas_item_add_rect(ci, Rect2(x0 + il, top, ir - il + 1, h), bg_color)
