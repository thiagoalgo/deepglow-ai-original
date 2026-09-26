extends Node
## Entry point and screen flow: LanguageSelect -> Game.
## Screens are PackedScene exports so the flow can grow (title, options,
## results) without touching the screens themselves.

@export var language_select_scene: PackedScene
@export var game_scene: PackedScene

var _current_screen: Node


func _ready() -> void:
	_show_language_select()


func _show_language_select() -> void:
	var screen := language_select_scene.instantiate() as LanguageSelect
	screen.language_confirmed.connect(_on_language_confirmed, CONNECT_ONE_SHOT)
	_switch_to(screen)


func _switch_to(screen: Node) -> void:
	if _current_screen:
		_current_screen.queue_free()
	_current_screen = screen
	add_child(screen)


func _on_language_confirmed(_locale: String) -> void:
	_switch_to(game_scene.instantiate())
