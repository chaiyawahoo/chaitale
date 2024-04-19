class_name Player
extends CharacterBody3D


@export var walk_speed: float = 4.5
@export var sneak_speed_modifier: float = 0.5
@export var sprint_speed_modifier: float = 1.3
@export var jump_speed: float = 9.0
@export var sprint_stop_threshold: float = 3.0

var raw_input_vector: Vector2 = Vector2.ZERO
var input_direction: Vector3 = Vector3.ZERO
var speed: float = 0

var jumping: bool = false
var falling: bool = false
var sneaking: bool = false
var sprinting: bool = false
var walking: bool = false
var standing: bool = false

@onready var body_node: Node3D = $Body
@onready var camera: Camera3D = $Body/SpringArm3D/Camera3D
@onready var collider: CollisionShape3D = $BodyCollider
@onready var player_area: AABB = AABB(Vector3.ZERO, collider.shape.size)


func _ready() -> void:
	position.y = Game.terrain.bounds.position.y + Game.terrain.bounds.size.y
	Game.player = self
	set_physics_process(false)
	set_process(false)
	await Game.terrain.meshed
	set_physics_process(true)
	set_process(true)
	position.y = Game.terrain.highest_voxel_position.y + 5
	position.x = 0.5
	position.z = 0.5


func _process(_delta: float) -> void:
	if Game.pause_menu.visible:
		speed = 0
		sprinting = false
		sneaking = false
		return
	
	player_area.position = position - player_area.size / 2
	
	falling = not is_on_floor()
	
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


func _physics_process(delta: float) -> void:
	var input_vector: Vector3 = input_direction * speed
	velocity.x = input_vector.x
	velocity.z = input_vector.z
	if falling:
		velocity += Settings.gravity_axis * Settings.gravity_constant * delta
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
