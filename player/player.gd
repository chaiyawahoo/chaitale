class_name Player
extends CharacterBody3D


@export var walk_speed: float = 5.0
@export var sneak_speed_modifier: float = 0.5
@export var sprint_speed_modifier: float = 1.5
@export var jump_speed: float = 10
@export var mouse_sensitivity: float = 0.1
@export var third_person_camera_distance: float = 5.0

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


func _ready() -> void:
	set_physics_process(false)
	# TODO: await terrain load
	await get_tree().create_timer(.25).timeout
	set_physics_process(true)


func _process(delta: float) -> void:
	if Game.menu_opened:
		input_direction = Vector3.ZERO
		return
		
	falling = not is_on_floor()
	
	_handle_process_input()
	
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
	
	if raw_input_vector == Vector2.ZERO:
		sprinting = false
	
	velocity.x = input_direction.x * speed
	velocity.z = input_direction.z * speed
	
	# gravity gets updated every physics step


func _physics_process(delta: float) -> void:
	if falling:
		velocity += gravity_axis * gravity_constant * delta
	elif jumping:
		velocity.y = jump_speed
	else:
		velocity.y = 0
	
	move_and_slide()
	


func _input(event) -> void:
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
		if abs(angle_change.y + vertical_look) < 50:
			vertical_look += angle_change.y
			spring_arm.global_rotation.x += deg_to_rad(angle_change.y)


func _handle_process_input() -> void:
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
		else:
			sprinting = false
	
	raw_input_vector = Input.get_vector("move_backward", "move_forward", "move_left", "move_right")
	input_direction.x = raw_input_vector.x
	input_direction.z = raw_input_vector.y
	input_direction = input_direction.rotated(Vector3.UP, deg_to_rad(horizontal_look))
