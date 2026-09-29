class_name Demo
extends RefCounted
## Demo build switch. The demo is the same project exported with the "demo"
## feature tag (its own export preset, no branch): only the biomes up to
## `deepglow/demo/last_biome` can be played; reaching the next biome's gate plays
## the demo ending and the "thanks for playing" screen. The save carries over to
## the full game. Settings live in Project Settings → deepglow/demo/*.

const LAST_BIOME_SETTING := "deepglow/demo/last_biome"
const FEEDBACK_URL_SETTING := "deepglow/demo/feedback_url"

## Dev console "demo": plays the demo rules in the editor / dev builds.
static var forced: bool = false


static func is_active() -> bool:
	return forced or OS.has_feature("demo")


## Id of the last playable biome, or &"" in the full game.
static func get_last_biome() -> StringName:
	if not is_active():
		return &""
	return StringName(str(ProjectSettings.get_setting(LAST_BIOME_SETTING, "glow_swamp")))


## Feedback form opened from the demo end screen ("" = no button).
static func get_feedback_url() -> String:
	return str(ProjectSettings.get_setting(FEEDBACK_URL_SETTING, ""))
