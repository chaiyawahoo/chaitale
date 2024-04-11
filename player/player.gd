class_name Player
extends CharacterBody3D


var speed: float = 5.0
var gravity_constant: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_axis: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
var input_direction: Vector3 = Vector3.ZERO
var jumping: bool = false


func _process(delta: float) -> void:
	var raw_input_vector: Vector2 = Input.get_vector("move_backward", "move_forward", "move_left", "move_right")
	input_direction.x = raw_input_vector.x
	input_direction.z = raw_input_vector.y


func _physics_process(delta: float) -> void:
	velocity = input_direction * speed
	velocity += gravity_axis * gravity_constant
	move_and_slide()


func _input(event) -> void:
	if event.is_action("jump"):
		jumping = true
