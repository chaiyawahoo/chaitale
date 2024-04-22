class_name Player
extends CharacterBody3D


@export var walk_speed: float = 4.0
@export var sneak_speed_modifier: float = 0.5
@export var sprint_speed_modifier: float = 1.3
@export var fly_speed_modifier: float = 2.0
@export var jump_speed: float = 9.0
@export var sprint_stop_threshold: float = 3.0
@export var jitter_interpolation: float = 40.0

var double_tap_speed: float = 0.25 # seconds before double tap resets
var jump_double_tap_timer: float = 0
var tapped_jump: bool = false

var raw_input_vector: Vector2 = Vector2.ZERO
var input_direction: Vector3 = Vector3.ZERO
var speed: float = 0

var external_velocity: Vector3 = Vector3.ZERO
var input_velocity: Vector3 = Vector3.ZERO

var jumping: bool = false
var falling: bool = true
var sneaking: bool = false
var sprinting: bool = false
var walking: bool = true
var standing: bool = true
var flying: bool = false

var player_name: String = ""

@onready var body_node: Node3D = $Body
@onready var camera: Camera3D = %Camera3D
@onready var voxel_editor: Node3D = $VoxelEditor
@onready var voxel_viewer: VoxelViewer = %VoxelViewer
@onready var collider: CollisionShape3D = $BodyCollider
@onready var sneaking_collider_generator: Node3D = $SneakingColliderGenerator
@onready var player_area: AABB = AABB(Vector3.ZERO, collider.shape.size)


func _enter_tree() -> void:
	player_name = Multiplayer.player_info.name
	Game.player = self
	SaveEngine.loaded.connect(_on_save_loaded)


func _ready() -> void:
	voxel_viewer.set_network_peer_id(multiplayer.get_unique_id())
	await Game.terrain.wait_for_mesh_under_player(self)
	Game.instance.hide_loading_screen()
	Game.instance.show_hud()


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
	
	voxel_editor.handle_process()
	
	player_area.position = position - player_area.size / 2
	
	body_node.rotation.y = deg_to_rad(camera.horizontal_look)
	
	raw_input_vector = Input.get_vector("move_backward", "move_forward", "move_left", "move_right")
	input_direction.x = raw_input_vector.x
	input_direction.z = raw_input_vector.y
	input_direction = input_direction.rotated(Vector3.UP, deg_to_rad(camera.horizontal_look))
	
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
	
	var forward_velocity: float = velocity.rotated(Vector3.UP, deg_to_rad(-camera.horizontal_look)).x

	if forward_velocity <= sprint_stop_threshold:
		sprinting = false

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
		
	if event.is_action("sneak"):
		sneaking = event.is_pressed()
		sprinting = false if sneaking else sprinting
		walking = false if sneaking else walking
	
	if event.is_action_pressed("sprint"):
		sprinting = true
		sneaking = false
		walking = false
	
	voxel_editor.handle_input(event)


func _on_save_loaded():
	load_save()


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
	if not player_name in SaveEngine.save_data:
		return
	var save_data: Dictionary = SaveEngine.save_data[player_name]
	position = save_data.position
	camera.horizontal_look = save_data.horizontal_look
	body_node.rotation.y = deg_to_rad(camera.horizontal_look)
	camera.vertical_look = save_data.vertical_look
	external_velocity = save_data.external_velocity
	flying = save_data.flying


func send_save_data() -> void:
	var save_data: Dictionary = {
		position = position,
		horizontal_look = camera.horizontal_look,
		vertical_look = camera.vertical_look,
		external_velocity = external_velocity,
		flying = flying
	}
	SaveEngine.save_data[player_name] = save_data
