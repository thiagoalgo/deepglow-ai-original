class_name PieceCatalog
extends Resource
## Collection of PieceData available in the game (data/pieces/catalog.tres).

@export var pieces: Array[PieceData] = []


func get_by_id(id: StringName) -> PieceData:
	for data: PieceData in pieces:
		if data.id == id:
			return data
	return null


func get_by_category(category: PieceData.Category) -> Array[PieceData]:
	var result: Array[PieceData] = []
	result.assign(pieces.filter(func(d: PieceData) -> bool: return d.category == category))
	return result


func pick_random() -> PieceData:
	return pieces.pick_random() as PieceData
