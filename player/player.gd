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
@export var sneaking_prevents_falling: bool = false
@export var maximize_fps: bool = true
@export var place_voxel_delay: float = 0.2
@export var break_voxel_delay: float = 0.2

var gravity_constant: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_axis: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
var starting_physics_ticks: float = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")

var invisible_wall: StaticBody3D = null

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

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var collider: CollisionShape3D = $Body
@onready var default_fov: float = camera.fov
@onready var default_camera_height: float = camera.position.y
@onready var player_area: AABB = collider.shape.get_debug_mesh().get_aabb()


func _ready() -> void:
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
	if Game.menu_opened:
		speed = 0
		return
	
	var fov_tween = create_tween()
	
	do_tween(camera, "fov", default_fov, fov_change_time, fov_tween)
	camera.position.y = default_camera_height
	
	player_area.position = position - player_area.size / 2
	
	falling = not is_on_floor()
	
	_handle_process_input()
	
	if sprinting:
		speed = walk_speed * sprint_speed_modifier
		do_tween(camera, "fov", default_fov * (1 + sprint_fov_modifier), fov_change_time, fov_tween)
	elif sneaking:
		speed = walk_speed * sneak_speed_modifier
		camera.position.y = default_camera_height - sneak_height_decrement
	else:
		walking = true
		speed = walk_speed
		camera.position.y = default_camera_height
	
	if placing:
		place_voxel()
	
	if breaking:
		break_voxel()
	
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
	
	if sneaking and not falling and Engine.get_process_frames() % 2 and sneaking_prevents_falling:
		if invisible_wall:
			invisible_wall.queue_free()
		invisible_wall = StaticBody3D.new()
		var neighbors: Array[int] = []
		var wall_distance = 1.75
		var shape_size = Vector3(1, 2, 1)
		var invisible_wall_collider_base: CollisionShape3D = CollisionShape3D.new()
		var voxels_under_player: Array[Vector3i] = get_voxel_positions_under_player()
		var highest_voxel_position_under_player: Vector3i = Vector3i.ZERO
		if voxels_under_player.size() > 0:
			highest_voxel_position_under_player = voxels_under_player[0]
		invisible_wall_collider_base.shape = BoxShape3D.new()
		invisible_wall_collider_base.shape.size = shape_size
		# TODO: get other highest voxel positions, and check if on top of any of those
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
			invisible_wall_collider.position = neighbor_transform * wall_distance
			invisible_wall.add_child(invisible_wall_collider)
		# TODO: optimize
		# draw corners...
		for i in range(9):
			if neighbors[i]:
				continue
			
			match i:
				0:
					if not neighbors[1]:
						var invisible_wall_collider: CollisionShape3D = invisible_wall_collider_base.duplicate()
						invisible_wall_collider.position = Vector3.FORWARD * wall_distance + Vector3.LEFT
						invisible_wall.add_child(invisible_wall_collider)
					if not neighbors[3]:
						var invisible_wall_collider: CollisionShape3D = invisible_wall_collider_base.duplicate()
						invisible_wall_collider.position = Vector3.LEFT * wall_distance + Vector3.FORWARD
						invisible_wall.add_child(invisible_wall_collider)
				2:
					if not neighbors[1]:
						var invisible_wall_collider: CollisionShape3D = invisible_wall_collider_base.duplicate()
						invisible_wall_collider.position = Vector3.FORWARD * wall_distance + Vector3.RIGHT
						invisible_wall.add_child(invisible_wall_collider)
					if not neighbors[5]:
						var invisible_wall_collider: CollisionShape3D = invisible_wall_collider_base.duplicate()
						invisible_wall_collider.position = Vector3.RIGHT * wall_distance + Vector3.FORWARD
						invisible_wall.add_child(invisible_wall_collider)
				6:
					if not neighbors[3]:
						var invisible_wall_collider: CollisionShape3D = invisible_wall_collider_base.duplicate()
						invisible_wall_collider.position = Vector3.LEFT * wall_distance + Vector3.BACK
						invisible_wall.add_child(invisible_wall_collider)
					if not neighbors[7]:
						var invisible_wall_collider: CollisionShape3D = invisible_wall_collider_base.duplicate()
						invisible_wall_collider.position = Vector3.BACK * wall_distance + Vector3.LEFT
						invisible_wall.add_child(invisible_wall_collider)
				8:
					if not neighbors[7]:
						var invisible_wall_collider: CollisionShape3D = invisible_wall_collider_base.duplicate()
						invisible_wall_collider.position = Vector3.BACK * wall_distance + Vector3.RIGHT
						invisible_wall.add_child(invisible_wall_collider)
					if not neighbors[5]:
						var invisible_wall_collider: CollisionShape3D = invisible_wall_collider_base.duplicate()
						invisible_wall_collider.position = Vector3.RIGHT * wall_distance + Vector3.BACK
						invisible_wall.add_child(invisible_wall_collider)
		invisible_wall.position = Vector3(highest_voxel_position_under_player) + Vector3.ONE * 0.5
		get_parent().add_child(invisible_wall)
	
	# gravity gets updated every physics step


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
	if Game.menu_opened:
		return
	if event.is_action("jump"):
		jumping = event.is_pressed()
	if event.is_action("sneak"):
		sneaking = event.is_pressed()
		sprinting = false if sneaking else sprinting
		walking = false if sneaking else walking
	if event is InputEventMouseMotion:
		if Game.menu_opened:
			return
		var angle_change: Vector2 = -event.relative * mouse_sensitivity
		horizontal_look += angle_change.x
		rotation.y += deg_to_rad(angle_change.x)
		if abs(angle_change.y + vertical_look) < 89:
			vertical_look += angle_change.y
			spring_arm.global_rotation.x += deg_to_rad(angle_change.y)


func _handle_process_input() -> void:
	raw_input_vector = Input.get_vector("move_backward", "move_forward", "move_left", "move_right")
	input_direction.x = raw_input_vector.x
	input_direction.z = raw_input_vector.y
	input_direction = input_direction.rotated(Vector3.UP, deg_to_rad(horizontal_look))
	if Input.is_action_just_pressed("camera_mode"):
		if spring_arm.spring_length == 0:
			spring_arm.spring_length = third_person_camera_distance
		else:
			spring_arm.spring_length = 0
	if Input.is_action_just_pressed("sprint"):
		if not sprinting:
			sprinting = true
			sneaking = false
			walking = false
	if Input.is_action_pressed("left_click"):
		breaking = true
	if Input.is_action_pressed("right_click"):
		placing = true
	if Input.is_action_just_pressed("select_1"):
		selected_voxel_type = 1
	if Input.is_action_just_pressed("select_2"):
		selected_voxel_type = 2


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


func break_voxel() -> void:
	breaking = false
	if break_voxel_timer:
		if break_voxel_timer.time_left > 0:
			return
	var result: VoxelRaycastResult = get_looking_raycast_result()
	if not result:
		return
	remove_voxel_at(result.position)
	break_voxel_timer = get_tree().create_timer(break_voxel_delay)


func place_voxel() -> void:
	placing = false
	if place_voxel_timer:
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
	var raycast_result: VoxelRaycastResult = Game.voxel_tool.raycast(global_position, Vector3.DOWN, 1.25)
	if raycast_result:
		voxel_positions.append(raycast_result.position)
	var steps: int = 16
	for i in range(steps):
		var raycast_origin: Vector3 = global_position
		var angle: float = 2 * i * PI / steps
		raycast_origin.x += cos(angle) * 0.44
		raycast_origin.z += sin(angle) * 0.44
		raycast_result = Game.voxel_tool.raycast(raycast_origin, Vector3.DOWN, 1.25)
		if not raycast_result:
			continue
		if not raycast_result.position in voxel_positions:
			voxel_positions.append(raycast_result.position)
	return voxel_positions
