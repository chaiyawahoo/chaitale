extends VoxelTerrain


func _ready() -> void:
	if not Game.terrain:
		Game.terrain = self
