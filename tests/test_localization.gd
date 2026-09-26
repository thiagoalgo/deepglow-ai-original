extends RefCounted
## Localization tests: translation table completeness and locale matching.

const CSV_PATH := "res://localization/translations.csv"
const CATALOG_PATH := "res://data/pieces/catalog.tres"
const SETTINGS_PATH := "res://src/autoload/settings.gd"


func _read_table() -> Dictionary:
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	var header := file.get_csv_line()
	var table := {"header": header, "rows": {}}
	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() > 1:
			table["rows"][line[0]] = line
	return table


func test_every_key_has_all_locales() -> String:
	var table := _read_table()
	var header: PackedStringArray = table["header"]
	for key: String in table["rows"]:
		var row: PackedStringArray = table["rows"][key]
		if row.size() != header.size():
			return "row '%s' has %d columns, expected %d" % [key, row.size(), header.size()]
		for i: int in range(1, row.size()):
			if row[i].strip_edges().is_empty():
				return "key '%s' missing '%s' translation" % [key, header[i]]
	return ""


func test_supported_locales_match_csv_columns() -> String:
	var header: PackedStringArray = _read_table()["header"]
	var settings: GDScript = load(SETTINGS_PATH)
	var supported: Dictionary = settings.get("SUPPORTED_LOCALES")
	for locale: String in supported:
		if not header.has(locale):
			return "locale '%s' has no column in %s" % [locale, CSV_PATH]
	return ""


func test_every_piece_has_name_key() -> String:
	var rows: Dictionary = _read_table()["rows"]
	var catalog: Resource = load(CATALOG_PATH)
	for data: Resource in catalog.get("pieces"):
		var key := String(data.call("get_name_key"))
		if not rows.has(key):
			return "missing translation key %s" % key
	return ""


func test_match_supported_locale() -> String:
	var settings: GDScript = load(SETTINGS_PATH)
	var cases := {"pt_BR": "pt_BR", "pt_PT": "pt_BR", "pt": "pt_BR", "en_US": "en", "fr_FR": "en"}
	for input: String in cases:
		var got: String = settings.call("match_supported_locale", input)
		if got != cases[input]:
			return "%s -> %s (expected %s)" % [input, got, cases[input]]
	return ""
