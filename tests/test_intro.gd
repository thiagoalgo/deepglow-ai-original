extends RefCounted
## Intro data (data/intro/intro.tres): 9 shots with their narration keys.

const INTRO_PATH := "res://data/intro/intro.tres"


func test_intro_has_nine_shots_in_order() -> String:
	var sequence: IntroSequence = load(INTRO_PATH)
	if sequence.shots.size() != 9:
		return "expected 9 shots, got %d" % sequence.shots.size()
	for i: int in sequence.shots.size():
		var shot := sequence.shots[i]
		if shot.text_key != StringName("INTRO_%02d" % (i + 1)):
			return "shot %d has key %s" % [i + 1, shot.text_key]
		if shot.duration <= 0.0:
			return "shot %d has no duration" % (i + 1)
	return ""


func test_intro_lasts_about_a_minute() -> String:
	var total: float = (load(INTRO_PATH) as IntroSequence).get_total_duration()
	if total < 50.0 or total > 90.0:
		return "intro should last 50-90 s, got %.1f" % total
	return ""


func test_montage_shows_every_biome() -> String:
	var sequence: IntroSequence = load(INTRO_PATH)
	var db: GameDatabase = load("res://data/game_database.tres")
	var montage := sequence.shots[6].backgrounds
	if montage.size() != db.biomes.size():
		return "shot 7 should cut through all %d biomes" % db.biomes.size()
	for i: int in db.biomes.size():
		if montage[i] != db.biomes[i].background:
			return "montage frame %d is not %s" % [i, db.biomes[i].id]
	return ""


func test_voice_lines_exist() -> String:
	var sequence: IntroSequence = load(INTRO_PATH)
	for locale: String in ["pt_BR", "en"]:
		for i: int in sequence.shots.size():
			var path := sequence.voice_path.format({"locale": locale, "index": "%02d" % (i + 1)})
			if not ResourceLoader.exists(path):
				return "missing %s voice for shot %d" % [locale, i + 1]
	return ""


func test_other_languages_fall_back_to_english_voice() -> String:
	var sequence: IntroSequence = load(INTRO_PATH)
	var voice := sequence.get_voice(0, "fr")
	var english := sequence.get_voice(0, "en")
	if voice == null or voice.resource_path != english.resource_path:
		return "a language without recordings should get the English voice"
	return ""
