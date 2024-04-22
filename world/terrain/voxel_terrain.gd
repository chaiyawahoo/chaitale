extends VoxelTerrain


var loaded: bool = false
var highest_voxel_position: Vector3i = Vector3i.ZERO

var save_name: String = "world"
var world_seed: int = 1004


func _enter_tree() -> void:
	Game.terrain = self
	Game.voxel_tool = get_voxel_tool()
	Game.voxel_types = mesher.library.models.size() - 1
	if Game.world_seed:
		world_seed = Game.world_seed
	if Game.save_name:
		save_name = Game.save_name
	SaveEngine.load_terrain_stream()


func _ready() -> void:
	pass

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


func wait_for_mesh_under_player(player: Player) -> void:
	var player_aabb_position: Vector3 = Vector3(floor(player.position.x - 1), bounds.position.y, floor(player.position.z - 1))
	var player_aabb_size: Vector3 = Vector3(ceil(player.position.x + 1), bounds.position.y + bounds.size.y, ceil(player.position.z + 1))
	while not is_area_meshed(AABB(player_aabb_position, player_aabb_size)):
		await TickEngine.ticked
		continue
	var voxel_raycast_result: VoxelRaycastResult = Game.voxel_tool.raycast(Vector3(player.position.x, bounds.position.y + bounds.size.y, player.position.z), Vector3.DOWN, bounds.size.y)
	if voxel_raycast_result:
		if player.position.y - voxel_raycast_result.position.y < 3:
			player.position.y = voxel_raycast_result.position.y + 2.25
		return


# func receive_data_block(info: VoxelDataBlockEnterInfo) -> void:
# 	try_set_block_data(info.get_position(), info.get_voxels())


# func receive_area_edited(origin: Vector3i, buffer: VoxelBuffer) -> void:
# 	get_voxel_tool().paste(origin, buffer, 1 << VoxelBuffer.CHANNEL_TYPE)
# 	pass
