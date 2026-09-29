class_name AmbientEffect
extends Resource
## One layer of ambient particles for a biome (fireflies, spores, embers,
## snow…), drawn by AmbientParticles. Pixel art only: blocks of whole pixels,
## palette colors that change in steps (never alpha fades).

enum Motion {
	## Wander on a closed Lissajous path and blink (fireflies).
	WANDER,
	## Move with a velocity (+ gravity and sideways sway) until the life ends,
	## then respawn (spores, embers, snow, bubbles, drops).
	FLOW,
	## Stay put and twinkle once per life, then reappear somewhere else.
	TWINKLE,
}

enum Shape {
	## One block.
	BLOCK,
	## A block with four arms at its brightest step (crystal glints).
	GLINT,
	## Four blocks around an empty center (bubbles).
	RING,
}

@export var motion: Motion = Motion.FLOW
@export var shape: Shape = Shape.BLOCK
## How many particles are alive at once.
@export var count: int = 12
## Block size in pixels (the backgrounds are drawn at 2 px per art pixel).
@export var block: Vector2i = Vector2i(2, 2)
## Where particles appear (and, for WANDER, the area of their path centers).
@export var spawn_area: Rect2 = Rect2(0, 0, 640, 360)
## Colors over one life (FLOW/TWINKLE) or the blink steps (WANDER), bright first
## for FLOW (it cools down), in order for TWINKLE (dim → bright → dim).
@export var colors: Array[Color] = [Palette.LIGHT_SULFUR_YELLOW]
## Life in seconds (random between x and y).
@export var life: Vector2 = Vector2(3.0, 6.0)
## FLOW: initial velocity in px/s (random between min and max per axis).
@export var velocity_min: Vector2 = Vector2(0, -20)
@export var velocity_max: Vector2 = Vector2(0, -10)
## FLOW: acceleration in px/s² (drops fall faster and faster).
@export var gravity: Vector2 = Vector2.ZERO
## FLOW: sideways sway (amplitude in px, frequency in Hz).
@export var sway: Vector2 = Vector2.ZERO
## FLOW: the last frames of a life draw a small burst (bubble/spore pop, splash).
@export var pop: bool = false
## Color of the pop (defaults to the first color when transparent).
@export var pop_color: Color = Color.TRANSPARENT
## Seconds without the effect between the end of a life and the next spawn.
@export var rest: Vector2 = Vector2(0.0, 0.0)
