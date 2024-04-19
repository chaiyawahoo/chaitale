extends Node


var gravity_constant: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_axis: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
var starting_physics_ticks: float = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")

var coarse_mouse_sensitivity: float = 0.5
var fine_mouse_sensitivity: float = 0.1
var mouse_sensitivity: float:
	get: return coarse_mouse_sensitivity * fine_mouse_sensitivity

var place_voxel_hold_delay: float = 0.2
var break_voxel_hold_delay: float = 0.2
var voxel_interaction_reach: float = 6.0

var vsync_physics_ticks_per_second: bool = true


func _enter_tree() -> void:
	if vsync_physics_ticks_per_second:
		Engine.set_physics_ticks_per_second(max(DisplayServer.screen_get_refresh_rate(), starting_physics_ticks))
