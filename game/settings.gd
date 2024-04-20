extends Node


var gravity_constant: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_axis: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
var physics_ticks_per_second: float = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")

var place_voxel_hold_delay: float = 0.2
var break_voxel_hold_delay: float = 0.2
var voxel_interaction_reach: float = 6.0

var window_mode: Window.Mode = Window.MODE_WINDOWED

var cap_fps: bool = false
var max_fps: int = 60
var fps_minimum: int = 30
var fps_maximum: int = 500
var vsync_mode: DisplayServer.VSyncMode = DisplayServer.VSYNC_ENABLED

var fov: float = 75
var fov_minimum: float = 30
var fov_maximum: float = 110

var mouse_sensitivity_coefficient: float = 0.5
var mouse_sensitivity: float = 0.1


func _enter_tree() -> void:
	load_settings()


func _ready() -> void:
	update_settings()


func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	var error: Error = config.load("user://settings.cfg")

	if error != OK:
		return
	
	window_mode = config.get_value("video", "window_mode", window_mode)
	fov = config.get_value("video", "fov", fov)
	cap_fps = config.get_value("video", "cap_fps", cap_fps)
	max_fps = config.get_value("video", "max_fps", max_fps)
	vsync_mode = config.get_value("video", "vsync_mode", vsync_mode)
	mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", mouse_sensitivity)

	update_settings()


func update_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	
	get_viewport().get_window().mode = window_mode
	DisplayServer.window_set_vsync_mode(vsync_mode)
	Engine.max_fps = max_fps
	if not cap_fps:
		Engine.max_fps = 0
		

	config.set_value("video", "window_mode", window_mode)
	config.set_value("video", "fov", fov)
	config.set_value("video", "cap_fps", cap_fps)
	config.set_value("video", "max_fps", max_fps)
	config.set_value("video", "vsync_mode", vsync_mode)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)

	config.save("user://settings.cfg")
