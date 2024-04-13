extends VoxelTerrain


signal meshed

var loaded: bool = false
var requested: bool = false


func _ready() -> void:
	if not Game.terrain:
		Game.terrain = self
	if not Game.voxel_tool:
		Game.voxel_tool = get_voxel_tool()


func _process(delta: float) -> void:
	if loaded:
		return
	# SLOW
#	print(is_area_meshed(AABB(Vector3.ZERO, Vector3.ONE)))
	# TODO: this is hacky, find a better method to detect loaded
	if requested:
		if get_statistics().time_request_blocks_to_load == 0:
			loaded = true
			meshed.emit()
	if get_statistics().time_request_blocks_to_load > 0:
		requested = true
		
