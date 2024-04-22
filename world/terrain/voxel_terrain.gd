extends VoxelTerrain


signal meshed

var loaded: bool = false
var highest_voxel_position: Vector3i = Vector3i.ZERO

var save_name: String = "world"
var world_seed: int = 1004


func _enter_tree() -> void:
	set_multiplayer_authority(multiplayer.get_unique_id(), true)
	Game.terrain = self
	Game.voxel_tool = get_voxel_tool()
	Game.voxel_types = mesher.library.models.size() - 1
	if Game.world_seed:
		world_seed = Game.world_seed
	if Game.save_name:
		save_name = Game.save_name
	SaveEngine.load_terrain_stream()


func _ready() -> void:
	wait_for_mesh()


# func _on_data_block_entered(info: VoxelDataBlockEnterInfo) -> void:
# 	if not info.are_voxels_edited():
# 		return
# 	# rpc info


# func _on_area_edited(area_origin: Vector3i, area_size: Vector3i) -> void:
# 	var peer_ids: PackedInt32Array = get_viewer_network_peer_ids_in_area(area_origin, area_size)
# 	var area_buffer: VoxelBuffer = VoxelBuffer.new()
# 	area_buffer.create(area_size.x, area_size.y, area_size.z)
# 	get_voxel_tool().copy(area_origin, area_buffer, 1 << VoxelBuffer.CHANNEL_TYPE)
# 	# rpc area buffer
# 	print(peer_ids)


func wait_for_mesh() -> void:
	var voxel_raycast_result: VoxelRaycastResult = Game.voxel_tool.raycast(bounds.size * Vector3.UP, Vector3.DOWN, bounds.size.y)
	if voxel_raycast_result:
		loaded = true
		highest_voxel_position = voxel_raycast_result.position
		meshed.emit()
		return
	await TickEngine.ticked
	wait_for_mesh()


# func receive_data_block(info: VoxelDataBlockEnterInfo) -> void:
# 	try_set_block_data(info.get_position(), info.get_voxels())


# func receive_area_edited(origin: Vector3i, buffer: VoxelBuffer) -> void:
# 	get_voxel_tool().paste(origin, buffer, 1 << VoxelBuffer.CHANNEL_TYPE)
# 	pass
