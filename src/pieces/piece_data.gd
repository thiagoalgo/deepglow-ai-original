class_name PieceData
extends Resource
## Data definition of a piece type. One .tres per piece in data/pieces/.
## Piece nodes read from here — never hardcode stats in scenes/scripts.
## Player-facing text comes from translation keys derived from `id`
## (see localization/translations.csv), never from literal strings.

enum Category { TREE, ROCK, ORE, GEM, PLANT, MUSHROOM, STRUCTURE, ITEM }

@export var id: StringName
@export var category: Category = Category.ITEM
## Piece sprite (16x16, Deepglow palette). May be null while prototyping.
@export var texture: Texture2D
## Color used by the placeholder while there is no texture.
@export var placeholder_color: Color = Palette.LIGHT_BLUE_WHITE
@export var tags: PackedStringArray


## Translation key for the piece name, e.g. &"gem_violet" -> "PIECE_GEM_VIOLET_NAME".
func get_name_key() -> StringName:
	return StringName("PIECE_%s_NAME" % String(id).to_upper())


## Localized piece name for the current locale.
func get_display_name() -> String:
	return TranslationServer.translate(get_name_key())
