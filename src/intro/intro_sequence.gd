class_name IntroSequence
extends Resource
## The intro's shots in order (data/intro/intro.tres), played by the Intro screen.

@export var shots: Array[IntroShot] = []
## Narration of shot N (1-based, two digits) in a locale.
@export var voice_path: String = "res://assets/audio/voice/{locale}/intro_{index}.ogg"
## Languages without their own recording are narrated in this one (with the
## captions in the player's language).
@export var fallback_voice_locale: String = "en"


## Voice line of a shot for `locale` (or the fallback language), or null.
func get_voice(index: int, locale: String) -> AudioStream:
	for candidate: String in [locale, fallback_voice_locale]:
		var path := voice_path.format({"locale": candidate, "index": "%02d" % (index + 1)})
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null


func get_total_duration() -> float:
	var total := 0.0
	for shot: IntroShot in shots:
		total += shot.duration
	return total
