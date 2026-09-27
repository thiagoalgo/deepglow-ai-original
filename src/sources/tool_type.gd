class_name ToolType
extends Resource
## A tool shown as the contextual cursor (axe, hand, cup…).
## Name key: TOOL_<ID>_NAME.

@export var id: StringName
## Cursor image (24x24, hotspot at `cursor_hotspot`).
@export var cursor_texture: Texture2D
@export var cursor_hotspot: Vector2i = Vector2i(1, 1)
## Available from the start. Otherwise an UNLOCK_TOOL upgrade targeting this id is required.
@export var unlocked_by_default: bool = false
## Played on every click on a source that uses this tool (the material's sound).
@export var hit_sound: AudioStream
## Chips thrown on each hit, bright to dark (palette colors; a particle steps
## through them as it ages instead of fading).
@export var particle_colors: PackedColorArray = []
