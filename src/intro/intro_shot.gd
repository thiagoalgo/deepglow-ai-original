class_name IntroShot
extends Resource
## One shot of the intro (docs/intro script: Project doc "claude/introducao-roteiro.md").
## Shots change with a pixel dissolve (src/fx/pixel_dissolve.gdshader).
## A shot shows a picture (a biome background, a 2x close-up of part of one, or
## a montage of several) and types its narration line in the caption panel.
## A shot showing the same picture as the previous one keeps it (only the line
## changes). Until the intro's own art
## exists, every shot reuses the biome backgrounds.

enum Motion {
	HOLD,     ## still picture (a montage when there are several backgrounds)
	FLICKER,  ## the light flickers and almost goes out (the last light)
}

## Narration line (translation key).
@export var text_key: StringName
## Seconds on screen (estimated from the narration; the player can advance).
@export var duration: float = 6.0
@export var motion: Motion = Motion.HOLD
## Background art. More than one = montage: equal intervals, each picture
## dissolving into the next.
@export var backgrounds: Array[Texture2D] = []
## Close-up: this 320x180 region of the background shown at 2x (a zoom done as
## a cut, never continuous). Empty = the whole picture.
@export var close_up: Rect2i
