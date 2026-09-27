class_name SaveSystem
extends RefCounted
## Reads and writes the single save slot (user://save.json, human-readable JSON).
## Writes go to a temporary file first and are then renamed over the old save,
## so a crash mid-write never leaves a half-written save behind.

const SAVE_PATH := "user://save.json"


static func exists(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)


static func write(save: SaveGame, path: String = SAVE_PATH) -> Error:
	var temp_path := path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(save.to_dict(), "\t"))
	file.close()
	return DirAccess.rename_absolute(temp_path, path)


## The saved run, or null when there is none or it cannot be read.
static func read(path: String = SAVE_PATH) -> SaveGame:
	if not FileAccess.file_exists(path):
		return null
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		push_warning("Ignoring unreadable save: %s" % path)
		return null
	var save := SaveGame.from_dict(data as Dictionary)
	if save == null:
		push_warning("Ignoring save with an unsupported version: %s" % path)
	return save


static func delete(path: String = SAVE_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
