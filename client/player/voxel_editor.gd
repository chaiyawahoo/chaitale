extends Node3D


var selected_type: int = 1

var breaking: bool = false
var placing: bool = false

var break_voxel_timer: SceneTreeTimer
var place_voxel_timer: SceneTreeTimer


func handle_process() -> void:
	if breaking:
		break_voxel()
	
	if placing:
		place_voxel()


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
		place_voxel(true)


func remove_voxel_at(voxel_position: Vector3i) -> void:
	if voxel_position.y == 0:
		print("Cannot break bedrock!")
		return
	Game.voxel_tool.set_voxel(voxel_position, 0)


func add_voxel_at(voxel_position: Vector3i) -> void:
	var voxel_area: AABB = AABB(voxel_position, Vector3.ONE)
	if voxel_area.intersects(Game.player.player_area):
		print("Placing overlaps player!")
		return
	Game.voxel_tool.set_voxel(voxel_position, selected_type)


func break_voxel(forced: bool = false) -> void:
	if break_voxel_timer and not forced:
		if break_voxel_timer.time_left > 0:
			return
	var result: VoxelRaycastResult = Game.camera_raycast_result
	if not result:
		return
	remove_voxel_at(result.position)
	break_voxel_timer = get_tree().create_timer(Settings.break_voxel_hold_delay)


func place_voxel(forced: bool = false) -> void:
	if selected_type > Game.voxel_types or selected_type <= 0:
		return
	if place_voxel_timer and not forced:
		if place_voxel_timer.time_left > 0:
			return
	var result: VoxelRaycastResult = Game.camera_raycast_result
	if not result:
		return
	add_voxel_at(result.previous_position)
	place_voxel_timer = get_tree().create_timer(Settings.place_voxel_hold_delay)
