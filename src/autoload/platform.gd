extends Node
## Platform services (autoload "Platform"). Steam features are used only when the
## GodotSteam extension is installed (it registers the "Steam" singleton) AND the
## game was started through Steam; otherwise every call is a no-op, so one build
## also runs standalone (itch.io, tests, the editor). All Steam calls are dynamic
## (`call`), so this script compiles without the extension. See docs/publishing.md.

## Steam App ID (project setting). 0 = let GodotSteam read steam_appid.txt / the Steam client.
const APP_ID_SETTING := "deepglow/steam/app_id"

## True when Steam initialized successfully.
var steam_ready: bool = false

var _steam: Object
var _reported: Dictionary[StringName, bool] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	if not Engine.has_singleton(&"Steam"):
		return
	_steam = Engine.get_singleton(&"Steam")
	var app_id := int(ProjectSettings.get_setting(APP_ID_SETTING, 0))
	var result: Variant = _steam.call(&"steamInitEx", true, app_id)
	steam_ready = result is Dictionary and int((result as Dictionary).get("status", 1)) == 0
	if steam_ready:
		set_process(true)
	else:
		push_warning("Steam is not available: %s" % str(result))


func _process(_delta: float) -> void:
	_steam.call(&"run_callbacks")


## Unlocks platform achievements by API name (already reported ones are skipped).
func unlock_achievements(ids: Array[StringName]) -> void:
	var changed := false
	for id: StringName in ids:
		if _reported.has(id):
			continue
		_reported[id] = true
		if steam_ready:
			_steam.call(&"setAchievement", String(id))
			changed = true
	if changed:
		_steam.call(&"storeStats")
