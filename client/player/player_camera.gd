extends Camera3D


var default_fov: float = 75
var sprint_fov: float = default_fov * 1.2
var third_person_camera_distance: float = 3.0
var fov_change_time: float = 0.1
var default_eye_level: float = 0.5
var sneaking_eye_level: float = 0.3

var vertical_look: float = 0
var horizontal_look: float = 0

@onready var spring_arm: SpringArm3D = get_parent()


func _enter_tree() -> void:
	fov = default_fov


func _process(_delta: float) -> void:
	_update_sprint_fov()
	_update_sneak_eye_level()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_mode"):
		if spring_arm.spring_length == 0:
			spring_arm.spring_length = third_person_camera_distance
			cull_mask += 2
		else:
			spring_arm.spring_length = 0
			cull_mask -= 2
	
	if event is InputEventMouseMotion:
		if Game.pause_menu.visible:
			return
		look_around(event.relative)


func look_around(relative_motion: Vector2):
	var angle_change: Vector2 = -relative_motion * Settings.mouse_sensitivity * Settings.mouse_sensitivity_coefficient
	horizontal_look += angle_change.x
	if abs(angle_change.y + vertical_look) > 89:
		return
	vertical_look += angle_change.y
	spring_arm.global_rotation.x += deg_to_rad(angle_change.y)


func get_looking_raycast_result() -> VoxelRaycastResult:
	var reach: float = Settings.voxel_interaction_reach + spring_arm.spring_length
	var result: VoxelRaycastResult = Game.voxel_tool.raycast(global_position, -global_transform.basis.z, reach)
	return result


func _update_sprint_fov() -> void:
	var fov_tween: Tween = create_tween()
	var new_fov: float = sprint_fov if Game.player.sprinting else default_fov
	Game.do_tween(self, "fov", new_fov, fov_change_time, fov_tween)


func _update_sneak_eye_level() -> void:
	spring_arm.position.y = sneaking_eye_level if Game.player.sneaking else default_eye_level
