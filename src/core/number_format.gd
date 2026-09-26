class_name NumberFormat
extends RefCounted
## Compact number formatting for the tiny 320x180 UI (1234 -> "1.2k").


static func compact(value: int) -> String:
	var magnitude := absi(value)
	if magnitude < 1000:
		return str(value)
	if magnitude < 10000:
		return "%.1fk" % (value / 1000.0)
	if magnitude < 1000000:
		return "%dk" % (value / 1000)
	return "%.1fM" % (value / 1000000.0)
