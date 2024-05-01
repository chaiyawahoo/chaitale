extends Node3D


var current_voxel_id: int = 1

var breaking: bool = false
var placing: bool = false

var break_voxel_timer: SceneTreeTimer
var place_voxel_timer: SceneTreeTimer


func handle_process() -> void:
	if breaking:
		break_voxel()
	
	if placing:
		place_voxel(current_voxel_id)


func handle_input(event: InputEvent):
	if event.is_action("left_click"):
		if not event.is_pressed():
			breaking = false
			return
		if breaking:
			return
		placing = false
		breaking = true
		break_voxel(true)
	
	if event.is_action("right_click"):
		if not event.is_pressed():
			placing = false
			return
		if placing:
			return
		breaking = false
		placing = true
		place_voxel(current_voxel_id, true)


@rpc("any_peer", "call_local")
func remove_voxel_at(voxel_position: Vector3i) -> void:
	if not multiplayer.is_server():
		return
	Game.voxel_tool.set_voxel(voxel_position, 0)


@rpc("any_peer", "call_local")
func add_voxel_at(voxel_position: Vector3i, voxel_id: int = 1) -> void:
	if not multiplayer.is_server():
		return
	Game.voxel_tool.set_voxel(voxel_position, voxel_id)


func break_voxel(forced: bool = false) -> void:
	if break_voxel_timer and not forced:
		if break_voxel_timer.time_left > 0:
			return
	var result: VoxelRaycastResult = Game.camera_raycast_result
	if not result:
		return
	if result.position.y == 0:
		print("Cannot break bedrock!")
		return
	remove_voxel_at.rpc_id(1, result.position)
	break_voxel_timer = get_tree().create_timer(Settings.break_voxel_hold_delay)


func place_voxel(voxel_id: int = 1, forced: bool = false) -> void:
	if voxel_id > Game.voxel_types or voxel_id <= 0:
		return
	if place_voxel_timer and not forced:
		if place_voxel_timer.time_left > 0:
			return
	var result: VoxelRaycastResult = Game.camera_raycast_result
	if not result:
		return
	var voxel_area: AABB = AABB(result.previous_position, Vector3.ONE)
	if voxel_area.intersects(Game.player.player_area):
		print("Placing overlaps player!")
		return
	else:
		add_voxel_at.rpc_id(1, result.previous_position, voxel_id)
		place_voxel_timer = get_tree().create_timer(Settings.place_voxel_hold_delay)
