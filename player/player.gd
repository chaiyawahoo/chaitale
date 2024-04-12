class_name Player
extends CharacterBody3D


@export var walk_speed: float = 4.5
@export var sneak_speed_modifier: float = 0.5
@export var sprint_speed_modifier: float = 1.3
@export var jump_speed: float = 9.0
@export var mouse_sensitivity: float = 0.1
@export var third_person_camera_distance: float = 5.0
@export var fov_change_time: float = 0.1
@export var sprint_fov_modifier: float = 0.2
@export var reach = 6.0

var gravity_constant: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_axis: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")

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

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var default_fov: float = camera.fov


func _ready() -> void:
	Game.player = self
	set_physics_process(false)
	set_process(false)
	await Game.terrain.meshed
	set_physics_process(true)
	set_process(true)
	position.y = get_terrain_origin_y() + 5
	position.x = 0.5
	position.z = 0.5


func _process(delta: float) -> void:
	if Game.menu_opened:
		speed = 0
		return
	
	var fov_tween = create_tween()
	
	do_tween(camera, "fov", default_fov, fov_change_time, fov_tween)
	
	falling = not is_on_floor()
	
	_handle_process_input()
	
	if sprinting:
		speed = walk_speed * sprint_speed_modifier
		do_tween(camera, "fov", default_fov * (1 + sprint_fov_modifier), fov_change_time, fov_tween)
	elif sneaking:
		speed = walk_speed * sneak_speed_modifier
	else:
		walking = true
		speed = walk_speed
	
	if velocity == Vector3.ZERO:
		walking = false
		standing = true
		sprinting = false
	
	if velocity.x == 0 and velocity.z == 0:
		sprinting = false
	
	# gravity gets updated every physics step


func _physics_process(delta: float) -> void:
	velocity.x = input_direction.x * speed
	velocity.z = input_direction.z * speed
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
	if event.is_action("left_click"):
		if event.is_pressed():
			var result: VoxelRaycastResult = get_looking_raycast_result()
			if result:
				remove_voxel_at(result.position)
	if event.is_action("right_click"):
		if event.is_pressed():
			var result: VoxelRaycastResult = get_looking_raycast_result()
			if result:
				add_voxel_at(result.previous_position)
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


func do_tween(object: Object, property: String, new_value: float, duration: float, tween: Tween) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(object, property, new_value, duration)


func get_looking_raycast_result() -> VoxelRaycastResult:
	var result: VoxelRaycastResult = Game.voxel_tool.raycast(spring_arm.global_position, -spring_arm.global_transform.basis.z, reach)
	return result


func remove_voxel_at(voxel_position: Vector3i) -> void:
	if voxel_position.y == 0:
		print("Cannot break bedrock!")
		return
	Game.voxel_tool.set_voxel(voxel_position, 0)


func add_voxel_at(voxel_position: Vector3i) -> void:
	var voxel_area: AABB = AABB(voxel_position, Vector3.ONE)
	var player_area: AABB = collider.shape.get_debug_mesh().get_aabb()
	player_area.position = position - player_area.size / 2
	if voxel_area.intersects(player_area):
		print("Placing overlaps player!")
		return
	Game.voxel_tool.set_voxel(voxel_position, 1)


func get_terrain_origin_y() -> int:
	var terrain_bounds: AABB = Game.terrain.bounds
	for i in range(terrain_bounds.position.y + terrain_bounds.size.y, terrain_bounds.position.y, -1):
		var voxel: int = Game.voxel_tool.get_voxel(Vector3i(0, i, 0))
		if voxel:
			return i
	return int(terrain_bounds.position.y + terrain_bounds.size.y)
