extends VoxelTerrain


signal meshed


var loaded := false
var highest_voxel_position := Vector3i.ZERO

var save_name := "world"
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
	var result := {}
	while result.is_empty():
		await TickEngine.ticked
		var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		# this can break things!
		var ground_point: float = player.position.y - 2.0
		if player.falling or player.flying or player.is_new_to_save:
			ground_point = -256
		var query := PhysicsRayQueryParameters3D.create(Vector3(player.position), Vector3(player.position.x, ground_point, player.position.z), 1)
		result = space_state.intersect_ray(query)
	if player.position.y - result.position.y < player.player_area.size.y / 2 or player.standing:
		player.position.y = result.position.y + player.player_area.size.y / 2
	loaded = true
	meshed.emit()
