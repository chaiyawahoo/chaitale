extends Node


var gravity_constant: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_axis: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
var physics_ticks_per_second: float = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")

var window_mode: Window.Mode = Window.MODE_WINDOWED

var mouse_sensitivity_coefficient: float = 0.5
var mouse_sensitivity: float = 0.1

var place_voxel_hold_delay: float = 0.2
var break_voxel_hold_delay: float = 0.2
var voxel_interaction_reach: float = 6.0


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
	mouse_sensitivity = config.get_value("controls", "mouse_sensitivity")

	update_settings()


func update_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	
	get_viewport().get_window().mode = window_mode

	config.set_value("graphics", "window_mode", window_mode)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)

	config.save("user://settings.cfg")
