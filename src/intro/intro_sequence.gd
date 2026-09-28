class_name IntroSequence
extends Resource
## The intro's shots in order (data/intro/intro.tres), played by the Intro screen.

@export var shots: Array[IntroShot] = []
## Narration of shot N (1-based, two digits) in a locale; a missing file = no
## voice for that shot/locale (the caption still plays).
@export var voice_path: String = "res://assets/audio/voice/{locale}/intro_{index}.ogg"


## Voice line of a shot for `locale`, or null when it was not recorded.
func get_voice(index: int, locale: String) -> AudioStream:
	var path := voice_path.format({"locale": locale, "index": "%02d" % (index + 1)})
	return load(path) as AudioStream if ResourceLoader.exists(path) else null


func get_total_duration() -> float:
	var total := 0.0
	for shot: IntroShot in shots:
		total += shot.duration
	return total
