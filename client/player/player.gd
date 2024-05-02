class_name Player
extends CharacterBody3D


@export var walk_speed: float = 4.0
@export var sneak_speed_modifier: float = 0.5
@export var sprint_speed_modifier: float = 1.3
@export var fly_speed_modifier: float = 2.0
@export var jump_speed: float = 9.0
@export var sprint_stop_threshold: float = 3.0
@export var jitter_interpolation: float = 40.0

var third_person_camera_distance: float = 3.0
var sprint_fov: float:
	get: return Settings.fov + 20
var fov_change_time: float = 0.1
var default_eye_level: float = 0.5
var sneaking_eye_level: float = 0.3

var double_tap_speed: float = 0.25 # seconds before double tap resets
var jump_double_tap_timer: float = 0
var tapped_jump: bool = false

var raw_input_vector: Vector2 = Vector2.ZERO
var input_direction: Vector3 = Vector3.ZERO
var speed: float = 0

@export var external_velocity: Vector3 = Vector3.ZERO
@export var input_velocity: Vector3 = Vector3.ZERO

@export var jumping: bool = false
@export var falling: bool = false
@export var sneaking: bool = false
@export var sprinting: bool = false
@export var walking: bool = true
@export var standing: bool = true
@export var flying: bool = false

var loaded = false
var is_new_to_save = false

@export var vertical_look: float = 0:
	set(value):
		vertical_look = value
		if spring_arm:
			spring_arm.global_rotation.x = deg_to_rad(value)
@export var horizontal_look: float = 0

@export var player_name: String = ""

@onready var body_node: Node3D = $Body
@onready var camera: Camera3D = %Camera3D
@onready var spring_arm: SpringArm3D = %SpringArm3D
@onready var voxel_viewer: VoxelViewer = %VoxelViewer
@onready var collider: CollisionShape3D = $BodyCollider
@onready var sneaking_collider_generator: Node3D = $SneakingColliderGenerator
@onready var player_area: AABB = AABB(Vector3.ZERO, collider.shape.size)


func _enter_tree() -> void:
	if multiplayer.is_server():
		player_name = Multiplayer.players[get_multiplayer_authority()].name	
		SaveEngine.loaded.connect(_on_save_loaded)
	elif is_multiplayer_authority():
		is_new_to_save = true
		player_name = Multiplayer.player_info.name
		load_save()


func _ready() -> void:
	if is_multiplayer_authority():
		camera.make_current()
		Game.player = self
		voxel_viewer.set_network_peer_id(get_multiplayer_authority())
	elif not multiplayer.is_server():
		voxel_viewer.queue_free()
	else:
		voxel_viewer.requires_visuals = false
		voxel_viewer.requires_collisions = false
		voxel_viewer.set_network_peer_id(get_multiplayer_authority())
	set_process(false)
	set_physics_process(false)
	if not Game.terrain.loaded:
		Game.terrain.wait_for_mesh_under_player(self, get_multiplayer_authority())
	await Game.terrain.meshed
	set_process(is_multiplayer_authority())
	set_physics_process(is_multiplayer_authority())
	if is_multiplayer_authority():
		camera.fov = Settings.fov
		%NameLabel.text = player_name
		while is_new_to_save and not is_on_floor():
			await TickEngine.ticked
		is_new_to_save = false
		UI.loading_screen.visible = false
		UI.hud.visible = true
	if multiplayer.is_server():
		SaveEngine.save_game()


func _process(delta: float) -> void:
	if tapped_jump:
		jump_double_tap_timer += delta
		if jump_double_tap_timer >= double_tap_speed:
			jump_double_tap_timer = 0
			tapped_jump = false

	smooth_player_movement(delta)

	if Game.is_paused:
		speed = 0
		sprinting = false
		sneaking = false
		jumping = false
		return
	
	if Input.is_action_just_pressed("jump"):
		if tapped_jump:
			flying = not flying
			if not flying:
				input_velocity.y = 0
			tapped_jump = false
			jump_double_tap_timer = 0
		else:
			tapped_jump = true

	falling = not is_on_floor() and not flying

	if flying and is_on_floor():
		flying = false
	
	VoxelEditor.handle_process()
	
	player_area.position = position - player_area.size / 2
	
	body_node.rotation.y = deg_to_rad(horizontal_look)
	
	raw_input_vector = Input.get_vector("move_backward", "move_forward", "move_left", "move_right")
	input_direction.x = raw_input_vector.x
	input_direction.z = raw_input_vector.y
	input_direction = input_direction.rotated(Vector3.UP, deg_to_rad(horizontal_look))
	
	var speed_modifier: float = 1.0
	if flying:
		speed_modifier *= fly_speed_modifier
	if sprinting:
		speed_modifier *= sprint_speed_modifier
	elif sneaking:
		speed_modifier *= sneak_speed_modifier
	else:
		walking = true
	speed = walk_speed * speed_modifier
	
	if velocity == Vector3.ZERO:
		walking = false
		standing = true
		sprinting = false
	
	var forward_velocity: float = velocity.rotated(Vector3.UP, deg_to_rad(-horizontal_look)).x

	if forward_velocity <= sprint_stop_threshold:
		sprinting = false
	
	update_sprint_fov()
	update_sneak_eye_level()

	sneaking_collider_generator.generate_sneaking_collision()


func _physics_process(delta: float) -> void:
	if not (Game.is_paused and falling): # removed "and falling" once block drag is properly implmeneted
		input_velocity.x = input_direction.x * speed
		input_velocity.z = input_direction.z * speed
	if falling:
		external_velocity += Settings.gravity_axis * Settings.gravity_constant * delta
	elif jumping: # (and not falling)
		if not flying:
			external_velocity.y = 0
			input_velocity.y = jump_speed
		else:
			external_velocity.y = 0
			input_velocity.y = speed
	elif flying and sneaking:
		input_velocity.y = -speed * 2
	else:
		external_velocity.y = 0
		input_velocity.y = 0
	
	velocity = external_velocity + input_velocity
	
	move_and_slide()


func _input(event) -> void:
	if Game.is_paused:
		return
	
	if event.is_action("jump"):
		jumping = event.is_pressed()
		return
		
	if event.is_action("sneak"):
		sneaking = event.is_pressed()
		sprinting = false if sneaking else sprinting
		walking = false if sneaking else walking
		return
	
	if event.is_action_pressed("sprint"):
		sprinting = true
		sneaking = false
		walking = false
		return
	
	if event.is_action_pressed("camera_mode"):
		if spring_arm.spring_length == 0:
			spring_arm.spring_length = third_person_camera_distance
			camera.cull_mask += 2
		else:
			spring_arm.spring_length = 0
			camera.cull_mask -= 2

	if event is InputEventMouseMotion:
		look_around(event.relative)
	
	VoxelEditor.handle_input(event)


func look_around(relative_motion: Vector2):
	vertical_look = rad_to_deg(spring_arm.global_rotation.x)
	var angle_change: Vector2 = -relative_motion * Settings.mouse_sensitivity * Settings.mouse_sensitivity_coefficient
	horizontal_look += angle_change.x
	if abs(angle_change.y + vertical_look) > 89:
		return
	vertical_look += angle_change.y


func get_looking_raycast_result() -> VoxelRaycastResult:
	var reach: float = Settings.voxel_interaction_reach + spring_arm.spring_length
	var result: VoxelRaycastResult = Game.voxel_tool.raycast(camera.global_position, -camera.global_transform.basis.z, reach)
	return result


func update_sprint_fov() -> void:
	var new_fov: float = sprint_fov if sprinting else Settings.fov
	if new_fov == camera.fov:
		return
	Game.do_tween(camera, "fov", new_fov, fov_change_time, create_tween())


func update_sneak_eye_level() -> void:
	spring_arm.position.y = sneaking_eye_level if sneaking else default_eye_level


# source: Garbaj: "Fixing Jittery Movement In Godot" (https://www.youtube.com/watch?v=pqrD3B75yKo)
func smooth_player_movement(delta: float) -> void:
	var fps: float = Engine.get_frames_per_second()
	if fps > Settings.physics_ticks_per_second:	
		var lerp_interval: Vector3 = input_direction / fps
		var lerp_position: Vector3 = global_position + lerp_interval
		body_node.top_level = true
		body_node.global_position = body_node.position.lerp(lerp_position, jitter_interpolation * delta)
	elif body_node.top_level:
		body_node.global_position = global_position
		body_node.top_level = false


func load_save() -> void:
	if not multiplayer.is_server():
		SaveEngine.request_server_save_data.rpc_id(1)
		await SaveEngine.server_data_received
		if not is_multiplayer_authority():
			return
	if not player_name in SaveEngine.save_data:
		print("%s not found in save" % player_name)
		is_new_to_save = true
		return
	var save_data: Dictionary = SaveEngine.save_data[player_name]
	position = save_data.position
	horizontal_look = save_data.horizontal_look
	body_node.rotation.y = deg_to_rad(horizontal_look)
	vertical_look = save_data.vertical_look
	external_velocity = save_data.external_velocity
	flying = save_data.flying
	falling = save_data.falling
	loaded = true


func send_save_data() -> void:
	if not loaded:
		load_save()
	var save_data: Dictionary = {
		position = position,
		horizontal_look = horizontal_look,
		vertical_look = vertical_look,
		external_velocity = external_velocity,
		falling = falling,
		flying = flying
	}
	SaveEngine.save_data[player_name] = save_data


func _on_save_loaded():
	load_save()
