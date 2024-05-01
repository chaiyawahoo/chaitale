extends VoxelTerrain


signal meshed

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


func wait_for_mesh_under_player(player: Player, peer_id: int = 1) -> void:
	if peer_id != multiplayer.get_unique_id():
		return
	var result: Dictionary = {}
	while result.size() == 0:
		await TickEngine.ticked
		var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		var relative_ground_distance: float = 2
		if player.falling or player.flying or player.is_new_to_save:
			relative_ground_distance = player.position.y
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(player.position), Vector3(player.position.x, player.position.y - relative_ground_distance, player.position.z), 1)
		result = space_state.intersect_ray(query)
	if player.position.y - result.position.y < 1.5:
		player.position.y = result.position.y + 1.5
	loaded = true
	meshed.emit()
