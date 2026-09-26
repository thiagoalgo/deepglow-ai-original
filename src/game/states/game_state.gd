class_name GameState
extends State
## Base state with typed access to Game.

var game: Game:
	get:
		return owner_node as Game
