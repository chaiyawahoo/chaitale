extends Node3D


var invisible_wall: StaticBody3D = null
var invisible_wall_distance: float = 1.49


func _process(_delta: float) -> void:
	if not Game.player.sneaking or Game.player.falling:
		if invisible_wall:
			invisible_wall.queue_free()
		invisible_wall = null
	
	generate_sneaking_collision()


func generate_sneaking_collision() -> void:
	if Game.player.sneaking and not Game.player.falling and Engine.get_process_frames() % 2:
		if invisible_wall:
			invisible_wall.queue_free()
		invisible_wall = StaticBody3D.new()
		var neighbors: Array[int] = []
		var shape_size = Vector3(1, 2, 1)
		var invisible_wall_collider_base: CollisionShape3D = CollisionShape3D.new()
		var voxels_under_player: Array[Vector3i] = get_voxel_positions_under_player()
		var highest_voxel_position_under_player: Vector3i = Vector3i.ZERO
		if voxels_under_player.size() > 0:
			highest_voxel_position_under_player = get_voxel_position_standing_on_most()
		else:
			return
		invisible_wall_collider_base.shape = BoxShape3D.new()
		invisible_wall_collider_base.shape.size = shape_size
		for i in range(9):
			var neighbor_transform: Vector3i = Vector3i.ZERO
			var neighbor_value: int = 0
			neighbor_transform.x += (i % 3) - 1
			neighbor_transform.z += int(i / 3.0) - 1
			neighbor_value = Game.voxel_tool.get_voxel(highest_voxel_position_under_player + neighbor_transform)
			neighbors.append(neighbor_value)
			if neighbor_value or not i % 2:
				continue
			var invisible_wall_collider: CollisionShape3D = invisible_wall_collider_base.duplicate()
			invisible_wall_collider.position = neighbor_transform * invisible_wall_distance
			invisible_wall.add_child(invisible_wall_collider)
		# draw corners...
		var neighbor_position = {
			0: Vector3(-1, 0, -1),
			2: Vector3(1, 0, -1),
			6: Vector3(-1, 0, 1),
			8: Vector3(1, 0, 1)
		}
		var invisible_wall_colliders: Array[CollisionShape3D] = []
		if not neighbors[0]:
			invisible_wall_colliders += generate_corner_shape_from_base(
					invisible_wall_collider_base, neighbor_position[0], invisible_wall_distance,
					neighbors[3], neighbors[1]
				)
		if not neighbors[2]:
			invisible_wall_colliders += generate_corner_shape_from_base(
					invisible_wall_collider_base, neighbor_position[2], invisible_wall_distance,
					neighbors[5], neighbors[1]
				)
		if not neighbors[6]:
			invisible_wall_colliders += generate_corner_shape_from_base(
					invisible_wall_collider_base, neighbor_position[6], invisible_wall_distance,
					neighbors[3], neighbors[7]
				)
		if not neighbors[8]:
			invisible_wall_colliders += generate_corner_shape_from_base(
					invisible_wall_collider_base, neighbor_position[8], invisible_wall_distance,
					neighbors[5], neighbors[7]
				)
		for wall_collider in invisible_wall_colliders:
			invisible_wall.add_child(wall_collider)
		invisible_wall.position = Vector3(highest_voxel_position_under_player) + Vector3.ONE * 0.5
		Game.instance.add_child(invisible_wall)
	

func generate_corner_shape_from_base(base_shape: CollisionShape3D, corner_vector: Vector3, distance: float, neighbor_x: bool, neighbor_z: bool) -> Array[CollisionShape3D]:
	var output: Array[CollisionShape3D] = []
	output.append(generate_shape_from_base(base_shape, corner_vector * distance))
	if not neighbor_x:
		corner_vector.x *= distance
		output.append(generate_shape_from_base(base_shape, corner_vector))
		corner_vector.x /= distance
	if not neighbor_z:
		corner_vector.z *= distance
		output.append(generate_shape_from_base(base_shape, corner_vector))
		corner_vector.z /= distance
	return output


func generate_shape_from_base(base_shape: CollisionShape3D, shape_position: Vector3) -> CollisionShape3D:
	var output: CollisionShape3D = base_shape.duplicate()
	output.position = shape_position
	return output


func get_voxel_positions_under_player() -> Array[Vector3i]:
	var voxel_positions: Array[Vector3i] = []
	var raycast_result: VoxelRaycastResult = Game.voxel_tool.raycast(global_position + Vector3.DOWN * (Game.player.player_area.size.y / 2), Vector3.DOWN, 1)
	if raycast_result:
		voxel_positions.append(raycast_result.position)
	var corners: Array[Vector3] = [
		Vector3(-1, -1, -1), 
		Vector3(1, -1, -1), 
		Vector3(1, -1, 1), 
		Vector3(-1, -1, 1)]
	for i in range(4):
		var raycast_origin: Vector3 = global_position + corners[i] * (Game.player.player_area.size / 2)
		raycast_result = Game.voxel_tool.raycast(raycast_origin, Vector3.DOWN, 1)
		if not raycast_result:
			continue
		if not raycast_result.position in voxel_positions:
			voxel_positions.append(raycast_result.position)
	return voxel_positions


func get_voxel_position_standing_on_most() -> Vector3i:
	var voxel_positions: Array[Vector3i] = get_voxel_positions_under_player()
	if voxel_positions.size() == 0:
		return Vector3i.ZERO
	if voxel_positions.size() == 1:
		return voxel_positions[0]
	var voxel_areas: Array[AABB] = []
	var area_intersection_volumes: Array[float] = []
	var largest_volume: float = 0
	var feet_position: Vector3 = global_position - Game.player.player_area.size / 2
	feet_position -= Vector3.UP * 0.5
	var feet_area: AABB = AABB(feet_position, Game.player.player_area.size)
	var index_of_greatest_intersection: int = 0
	for voxel_position in voxel_positions:
		voxel_areas.append(AABB(Vector3(voxel_position) + Game.terrain.global_position, Vector3.ONE))
	for voxel_area in voxel_areas:
		area_intersection_volumes.append(voxel_area.intersection(feet_area).get_volume())
	largest_volume = area_intersection_volumes.reduce(func(accum, volume): return max(accum, volume))
	index_of_greatest_intersection = area_intersection_volumes.find(largest_volume)
	return voxel_positions[index_of_greatest_intersection]
