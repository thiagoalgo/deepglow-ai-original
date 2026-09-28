class_name IntroSequence
extends Resource
## The intro's shots in order (data/intro/intro.tres), played by the Intro screen.

@export var shots: Array[IntroShot] = []


func get_total_duration() -> float:
	var total := 0.0
	for shot: IntroShot in shots:
		total += shot.duration
	return total
