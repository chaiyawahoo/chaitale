extends Node


var gravity_constant: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_axis: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
var starting_physics_ticks: float = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")

var window_mode: Window.Mode = Window.MODE_WINDOWED

var coarse_mouse_sensitivity: float = 0.5
var fine_mouse_sensitivity: float = 0.1
var mouse_sensitivity: float:
	get: return coarse_mouse_sensitivity * fine_mouse_sensitivity

var place_voxel_hold_delay: float = 0.2
var break_voxel_hold_delay: float = 0.2
var voxel_interaction_reach: float = 6.0

var vsync_physics_ticks_per_second: bool = true


func _enter_tree() -> void:
	load_settings()


func _ready() -> void:
	update_settings()


func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	var error: Error = config.load("user://settings.cfg")

	if error != OK:
		return
	
	window_mode = config.get_value("graphics", "window_mode")
	fine_mouse_sensitivity = config.get_value("controls", "mouse_sensitivity")
	vsync_physics_ticks_per_second = config.get_value("advanced", "physics_vsync")
	
	update_settings()


func update_settings() -> void:
	var config: ConfigFile = ConfigFile.new()

	if vsync_physics_ticks_per_second:
		Engine.set_physics_ticks_per_second(max(DisplayServer.screen_get_refresh_rate(), starting_physics_ticks))
	
	get_viewport().get_window().mode = window_mode

	config.set_value("graphics", "window_mode", window_mode)
	config.set_value("controls", "mouse_sensitivity", fine_mouse_sensitivity)
	config.set_value("advanced", "physics_vsync", vsync_physics_ticks_per_second)

	config.save("user://settings.cfg")
