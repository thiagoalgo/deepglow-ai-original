class_name App
extends Control
## Window root. The whole game (Main) renders into a fixed 640x360 SubViewport,
## shown integer-scaled and centred. Drawing it through a SubViewportContainer
## lets the optional CRT shader (crt.gdshader) run at the window resolution,
## so the curvature and scanlines stay smooth while the game pixels stay crisp.
## App (and so the viewport) always processes, so input keeps reaching the pause
## menu while the tree is paused; Main is set back to "pausable" in app.tscn.

## Game resolution (the pixel-art canvas).
const BASE_SIZE := Vector2i(640, 360)

@onready var _screen: SubViewportContainer = %Screen
@onready var _viewport: SubViewport = %GameViewport


func _ready() -> void:
	_viewport.size = BASE_SIZE
	get_viewport().size_changed.connect(_fit_screen)
	Settings.crt_changed.connect(_apply_crt)
	_apply_crt(Settings.crt_enabled)
	_fit_screen()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_crt"):
		Settings.set_crt_enabled(not Settings.crt_enabled)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"toggle_fullscreen"):
		Settings.set_fullscreen(not Settings.fullscreen)
		get_viewport().set_input_as_handled()


## Largest integer scale that fits the window; the rest is black letterbox.
func _fit_screen() -> void:
	var window := get_viewport_rect().size
	var factor := maxi(1, floori(minf(window.x / BASE_SIZE.x, window.y / BASE_SIZE.y)))
	_screen.size = Vector2(BASE_SIZE)
	_screen.scale = Vector2(factor, factor)
	_screen.position = ((window - Vector2(BASE_SIZE * factor)) / 2.0).floor()


func _apply_crt(enabled: bool) -> void:
	(_screen.material as ShaderMaterial).set_shader_parameter(&"enabled", enabled)
