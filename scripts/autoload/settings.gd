extends Node


var gravity_constant: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_axis: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
var physics_ticks_per_second: float = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")

var place_voxel_hold_delay: float = 0.2
var break_voxel_hold_delay: float = 0.2
var voxel_interaction_reach: float = 6.0

var settings: Dictionary = {
	video = {
		window_mode = Window.MODE_WINDOWED,
		fov = 75.0,
		fov_minimum = 30.0,
		fov_maximum = 110.0,
		cap_fps = false,
		max_fps = 60,
		fps_minimum = 30,
		fps_maximum = 500,
		vsync_mode = DisplayServer.VSYNC_ENABLED,
	},
	graphics = {
		shadow_filter_quality = 2,
		shadow_half_precision = true,
		ssao_quality = 2,
		ssao_adaptive_target = 0.5,
		ssao_half_size = true,
		ssil_quality = 2,
		ssil_adaptive_target = 0.5,
		ssil_half_size = true,
		msaa_samples = 0,
		ssaa = 0,
		use_taa = false,
		use_debanding = false,
	},
	controls = {
		mouse_sensitivity_coefficient = 0.5,
		mouse_sensitivity = 0.1,
		invert_scroll = false,
	},
	gameplay = {
		
	},
}


func _enter_tree() -> void:
	load_settings()


func _ready() -> void:
	update_settings()


func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	var error: Error = config.load("user://settings.cfg")

	if error != OK:
		return
	
	for section in config.get_sections():
		for key in config.get_section_keys(section):
			settings[section][key] = config.get_value(section, key, settings[section][key])

	update_settings()
	save_settings()


func save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()

	for section in settings:
		for key in settings[section]:
			config.set_value(section, key, settings[section][key])

	config.save("user://settings.cfg")

func update_settings() -> void:
	var viewport_rid = get_viewport().get_viewport_rid()
	get_viewport().get_window().mode = settings.video.window_mode
	DisplayServer.window_set_vsync_mode(settings.video.vsync_mode)
	Engine.max_fps = settings.video.max_fps if settings.video.cap_fps else 0
	RenderingServer.directional_soft_shadow_filter_set_quality(settings.graphics.shadow_filter_quality)
	RenderingServer.positional_soft_shadow_filter_set_quality(settings.graphics.shadow_filter_quality)
	RenderingServer.directional_shadow_atlas_set_size(4096, settings.graphics.shadow_half_precision)
	RenderingServer.viewport_set_positional_shadow_atlas_size(viewport_rid, 4096, settings.graphics.shadow_half_precision)
	RenderingServer.environment_set_ssao_quality(settings.graphics.ssao_quality, settings.graphics.ssao_half_size, settings.graphics.ssao_adaptive_target, 2, 50, 300)
	RenderingServer.environment_set_ssil_quality(settings.graphics.ssil_quality, settings.graphics.ssil_half_size, settings.graphics.ssil_adaptive_target, 4, 50, 300)
	RenderingServer.viewport_set_msaa_2d(viewport_rid, settings.graphics.msaa_samples)
	RenderingServer.viewport_set_msaa_3d(viewport_rid, settings.graphics.msaa_samples)
	RenderingServer.viewport_set_screen_space_aa(viewport_rid, settings.graphics.ssaa)
	RenderingServer.viewport_set_use_taa(viewport_rid, settings.graphics.use_taa)
	RenderingServer.viewport_set_use_debanding(viewport_rid, settings.graphics.use_debanding)
