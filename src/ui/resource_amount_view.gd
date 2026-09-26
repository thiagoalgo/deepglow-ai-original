class_name ResourceAmountView
extends HBoxContainer
## "[icon] 12" widget. Optional warning color (e.g. unaffordable cost).


static func create(resource: ResourceType, text: String, warning: bool = false) -> ResourceAmountView:
	var view := ResourceAmountView.new()
	view.add_theme_constant_override(&"separation", 2)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = resource.icon
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	view.add_child(icon)
	var label := Label.new()
	label.text = text
	if warning:
		label.theme_type_variation = &"AlertLabel"
	view.add_child(label)
	return view
