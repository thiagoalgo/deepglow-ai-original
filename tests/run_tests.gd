extends SceneTree
## Minimal headless test runner (no addons).
## Usage: godot --headless --path . -s res://tests/run_tests.gd
## Each tests/test_*.gd file extends RefCounted and exposes test_*() methods
## returning "" on success or a failure message.

var _failures: int = 0
var _passed: int = 0


func _initialize() -> void:
	var dir := DirAccess.open("res://tests")
	for file: String in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			_run_file("res://tests/" + file)
	print("\n%d passed, %d failed" % [_passed, _failures])
	quit(1 if _failures > 0 else 0)


func _run_file(path: String) -> void:
	var script := load(path) as GDScript
	var suite: Object = script.new()
	for method: Dictionary in script.get_script_method_list():
		var method_name: String = method["name"]
		if not method_name.begins_with("test_"):
			continue
		var error: String = suite.call(method_name)
		if error.is_empty():
			_passed += 1
			print("  ok   %s::%s" % [path.get_file(), method_name])
		else:
			_failures += 1
			printerr("  FAIL %s::%s -> %s" % [path.get_file(), method_name, error])
