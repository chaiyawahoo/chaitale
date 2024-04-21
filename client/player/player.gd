class_name Player
extends CharacterBody3D


@export var walk_speed: float = 4.5
@export var sneak_speed_modifier: float = 0.5
@export var sprint_speed_modifier: float = 1.3
@export var jump_speed: float = 9.0
@export var sprint_stop_threshold: float = 3.0
@export var jitter_interpolation: float = 40.0

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

@onready var body_node: Node3D = $Body
@onready var camera: Camera3D = $Body/SpringArm3D/Camera3D
@onready var collider: CollisionShape3D = $BodyCollider
@onready var sneaking_collider_generator: Node3D = $SneakingColliderGenerator
@onready var player_area: AABB = AABB(Vector3.ZERO, collider.shape.size)


func _enter_tree() -> void:
	Game.player = self
	SaveEngine.loaded.connect(_on_save_loaded)


func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	set_process(true)
	set_physics_process(true)
	Game.instance.hide_loading_screen()
	Game.instance.show_hud()


func _process(delta: float) -> void:
	smooth_player_movement(delta)

	falling = not is_on_floor()

	if Game.is_paused:
		speed = 0
		sprinting = false
		sneaking = false
		jumping = false
		return
	
	player_area.position = position - player_area.size / 2
	
	body_node.rotation.y = deg_to_rad(camera.horizontal_look)
	
	raw_input_vector = Input.get_vector("move_backward", "move_forward", "move_left", "move_right")
	input_direction.x = raw_input_vector.x
	input_direction.z = raw_input_vector.y
	input_direction = input_direction.rotated(Vector3.UP, deg_to_rad(camera.horizontal_look))
	
	if sprinting:
		speed = walk_speed * sprint_speed_modifier
	elif sneaking:
		speed = walk_speed * sneak_speed_modifier
	else:
		walking = true
		speed = walk_speed
	
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
		var input_vector: Vector3 = input_direction * speed
		input_velocity.x = input_vector.x
		input_velocity.z = input_vector.z
	if falling:
		external_velocity += Settings.gravity_axis * Settings.gravity_constant * delta
	elif jumping:
		external_velocity.y = 0
		input_velocity.y = jump_speed
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
	var save_data: Dictionary = SaveEngine.save_data
	position = save_data.player.position
	camera.horizontal_look = save_data.player.horizontal_look
	body_node.rotation.y = deg_to_rad(camera.horizontal_look)
	camera.vertical_look = save_data.player.vertical_look
	external_velocity = save_data.player.external_velocity
	
