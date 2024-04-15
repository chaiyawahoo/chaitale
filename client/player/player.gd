class_name Player
extends CharacterBody3D


@export var walk_speed: float = 4.5
@export var sneak_speed_modifier: float = 0.5
@export var sprint_speed_modifier: float = 1.3
@export var jump_speed: float = 9.0
@export var mouse_sensitivity: float = 0.1
@export var third_person_camera_distance: float = 3.0
@export var fov_change_time: float = 0.1
@export var sprint_fov_modifier: float = 0.2
@export var sneak_height_decrement: float = 0.2
@export var reach: float = 6.0
@export var sneaking_prevents_falling: bool = true
@export var maximize_fps: bool = true
@export var place_voxel_delay: float = 0.2
@export var break_voxel_delay: float = 0.2

var gravity_constant: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_axis: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
var starting_physics_ticks: float = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")

var invisible_wall: StaticBody3D = null
var invisible_wall_distance: float = 1.49

var raw_input_vector: Vector2 = Vector2.ZERO
var input_direction: Vector3 = Vector3.ZERO
var vertical_look: float = 0
var horizontal_look: float = 0
var speed: float = 0

var jumping: bool = false
var falling: bool = false
var sneaking: bool = false
var sprinting: bool = false
var walking: bool = false
var standing: bool = false
var placing: bool = false
var breaking: bool = false

var selected_voxel_type: int = 1
var can_place_voxel: bool = true
var can_break_voxel: bool = true
var place_voxel_timer: SceneTreeTimer
var break_voxel_timer: SceneTreeTimer

@onready var spring_arm: SpringArm3D = $Body/SpringArm3D
@onready var body_node: Node3D = $Body
@onready var camera: Camera3D = $Body/SpringArm3D/Camera3D
@onready var collider: CollisionShape3D = $BodyCollider
@onready var hover_cube: MeshInstance3D = $HoverCube
@onready var default_fov: float = camera.fov
@onready var default_camera_height: float = spring_arm.position.y
@onready var player_area: AABB = collider.shape.get_debug_mesh().get_aabb()


func _ready() -> void:
	hover_cube.top_level = true
	if maximize_fps:
		Engine.set_physics_ticks_per_second(max(DisplayServer.screen_get_refresh_rate(), starting_physics_ticks))
	Game.player = self
	set_physics_process(false)
	set_process(false)
	await Game.terrain.meshed
	set_physics_process(true)
	set_process(true)
	position.y = get_terrain_origin_y() + 5
	position.x = 0.5
	position.z = 0.5


func _process(_delta: float) -> void:
	var fov_tween = create_tween()
	do_tween(camera, "fov", default_fov, fov_change_time, fov_tween)
	spring_arm.position.y = default_camera_height
	
	if Game.pause_menu.visible:
		speed = 0
		sprinting = false
		sneaking = false
		return
	
	player_area.position = position - player_area.size / 2
	
	falling = not is_on_floor()
	
	raw_input_vector = Input.get_vector("move_backward", "move_forward", "move_left", "move_right")
	input_direction.x = raw_input_vector.x
	input_direction.z = raw_input_vector.y
	input_direction = input_direction.rotated(Vector3.UP, deg_to_rad(horizontal_look))
	
	draw_hover_cube()
	
	if sprinting:
		speed = walk_speed * sprint_speed_modifier
		do_tween(camera, "fov", default_fov * (1 + sprint_fov_modifier), fov_change_time, fov_tween)
	elif sneaking:
		speed = walk_speed * sneak_speed_modifier
		spring_arm.position.y = default_camera_height - sneak_height_decrement
	else:
		walking = true
		speed = walk_speed
	
	if breaking:
		break_voxel()
	
	if placing:
		place_voxel()
	
	if velocity == Vector3.ZERO:
		walking = false
		standing = true
		sprinting = false
	
	if velocity.x == 0 and velocity.z == 0:
		sprinting = false
	
	if not sneaking or falling and sneaking_prevents_falling:
		if invisible_wall:
			invisible_wall.queue_free()
		invisible_wall = null
	
	generate_sneaking_collision()


func _physics_process(delta: float) -> void:
	var input_vector: Vector3 = input_direction * speed
	velocity.x = input_vector.x
	velocity.z = input_vector.z
	if falling:
		velocity += gravity_axis * gravity_constant * delta
	elif jumping:
		velocity.y = jump_speed
	else:
		velocity.y = 0
	
	move_and_slide()


func _input(event) -> void:
	if Game.pause_menu.visible:
		return
	if event.is_action("jump"):
		jumping = event.is_pressed()
	if event.is_action("sneak"):
		sneaking = event.is_pressed()
		sprinting = false if sneaking else sprinting
		walking = false if sneaking else walking
	if event.is_action_pressed("sprint"):
		sprinting = true
		sneaking = false
		walking = false
	if event.is_action_pressed("select_1"):
		selected_voxel_type = 1
	if event.is_action_pressed("select_2"):
		selected_voxel_type = 2
	if event.is_action_pressed("camera_mode"):
		if spring_arm.spring_length == 0:
			spring_arm.spring_length = third_person_camera_distance
			camera.cull_mask += 2
		else:
			spring_arm.spring_length = 0
			camera.cull_mask -= 2
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
	if event is InputEventMouseMotion:
		if Game.pause_menu.visible:
			return
		var angle_change: Vector2 = -event.relative * mouse_sensitivity
		horizontal_look += angle_change.x
		body_node.rotation.y += deg_to_rad(angle_change.x)
		if abs(angle_change.y + vertical_look) < 89:
			vertical_look += angle_change.y
			spring_arm.global_rotation.x += deg_to_rad(angle_change.y)


func generate_sneaking_collision() -> void:
	if sneaking and not falling and Engine.get_process_frames() % 2 and sneaking_prevents_falling:
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
		get_parent().add_child(invisible_wall)
	

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


func do_tween(object: Object, property: String, new_value: Variant, duration: float, tween: Tween) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(object, property, new_value, duration)


func get_looking_raycast_result() -> VoxelRaycastResult:
	var result: VoxelRaycastResult = Game.voxel_tool.raycast(camera.global_position, -camera.global_transform.basis.z, reach + spring_arm.spring_length)
	return result


func remove_voxel_at(voxel_position: Vector3i) -> void:
	if voxel_position.y == 0:
		print("Cannot break bedrock!")
		return
	Game.voxel_tool.set_voxel(voxel_position, 0)


func add_voxel_at(voxel_position: Vector3i) -> void:
	var voxel_area: AABB = AABB(voxel_position, Vector3.ONE)
	if voxel_area.intersects(player_area):
		print("Placing overlaps player!")
		return
	Game.voxel_tool.set_voxel(voxel_position, selected_voxel_type)


func break_voxel(forced: bool = false) -> void:
	if break_voxel_timer and not forced:
		if break_voxel_timer.time_left > 0:
			return
	var result: VoxelRaycastResult = get_looking_raycast_result()
	if not result:
		return
	remove_voxel_at(result.position)
	break_voxel_timer = get_tree().create_timer(break_voxel_delay)


func place_voxel(forced: bool = false) -> void:
	if place_voxel_timer and not forced:
		if place_voxel_timer.time_left > 0:
			return
	var result: VoxelRaycastResult = get_looking_raycast_result()
	if not result:
		return
	add_voxel_at(result.previous_position)
	place_voxel_timer = get_tree().create_timer(place_voxel_delay)


func get_terrain_origin_y() -> int:
	var terrain_bounds: AABB = Game.terrain.bounds
	for i in range(terrain_bounds.position.y + terrain_bounds.size.y, terrain_bounds.position.y, -1):
		var voxel: int = Game.voxel_tool.get_voxel(Vector3i(0, i, 0))
		if voxel:
			return i
	return int(terrain_bounds.position.y + terrain_bounds.size.y)


func get_voxel_positions_under_player() -> Array[Vector3i]:
	var voxel_positions: Array[Vector3i] = []
	var raycast_result: VoxelRaycastResult = Game.voxel_tool.raycast(global_position + Vector3.DOWN * (player_area.size.y / 2), Vector3.DOWN, 1)
	if raycast_result:
		voxel_positions.append(raycast_result.position)
	var corners: Array[Vector3] = [
		Vector3(-1, -1, -1), 
		Vector3(1, -1, -1), 
		Vector3(1, -1, 1), 
		Vector3(-1, -1, 1)]
	for i in range(4):
		var raycast_origin: Vector3 = global_position + corners[i] * (player_area.size / 2)
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
	var feet_position: Vector3 = global_position - player_area.size / 2
	feet_position -= Vector3.UP * 0.5
	var feet_area: AABB = AABB(feet_position, player_area.size)
	var index_of_greatest_intersection: int = 0
	for voxel_position in voxel_positions:
		voxel_areas.append(AABB(Vector3(voxel_position) + Game.terrain.global_position, Vector3.ONE))
	for voxel_area in voxel_areas:
		area_intersection_volumes.append(voxel_area.intersection(feet_area).get_volume())
	largest_volume = area_intersection_volumes.reduce(func(accum, volume): return max(accum, volume))
	index_of_greatest_intersection = area_intersection_volumes.find(largest_volume)
	return voxel_positions[index_of_greatest_intersection]


func draw_hover_cube() -> void:
	var result: VoxelRaycastResult = get_looking_raycast_result()
	if not result:
		hover_cube.visible = false
		return
	hover_cube.position = Vector3(result.position) + Game.terrain.global_position - Vector3.ONE * 0.0005
	hover_cube.visible = true
