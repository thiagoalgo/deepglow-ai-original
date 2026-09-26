extends Node
## Entry point and screen flow: LanguageSelect -> Game (+ HUD).
## Screens are PackedScene exports so the flow can grow (title, options,
## results) without touching the screens themselves.

@export var language_select_scene: PackedScene
@export var game_scene: PackedScene
@export var hud_scene: PackedScene

var _current_screens: Array[Node] = []


func _ready() -> void:
	_show_language_select()


func _show_language_select() -> void:
	var screen := language_select_scene.instantiate() as LanguageSelect
	screen.language_confirmed.connect(_on_language_confirmed, CONNECT_ONE_SHOT)
	_switch_to([screen])


func _start_game() -> void:
	_switch_to([game_scene.instantiate(), hud_scene.instantiate()])


func _switch_to(screens: Array[Node]) -> void:
	for node: Node in _current_screens:
		node.queue_free()
	_current_screens = screens
	for node: Node in screens:
		add_child(node)


func _on_language_confirmed(_locale: String) -> void:
	_start_game()
