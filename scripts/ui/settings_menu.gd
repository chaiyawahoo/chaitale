extends Control


var unapplied_settings: Dictionary = {
		video = {},
		graphics = {},
		controls = {},
		gameplay = {},
	}

@onready var video_settings: Dictionary = Settings.settings.video
@onready var graphics_settings: Dictionary = Settings.settings.graphics
@onready var controls_settings: Dictionary = Settings.settings.controls


func _enter_tree() -> void:
	%BackButton.pressed.connect(back)
	%ApplyButton.pressed.connect(apply_changes)
	%ApplyCloseButton.pressed.connect(apply_changes.bind(true))

	%WindowMode.item_selected.connect(update_window_mode.unbind(1))
	%FovSlider.value_changed.connect(update_fov)
	%FovInput.text_submitted.connect(update_fov)
	%CapFpsCheck.toggled.connect(update_fps_cap)
	%FpsSlider.value_changed.connect(update_max_fps)
	%FpsInput.text_submitted.connect(update_max_fps)
	%VsyncCheck.toggled.connect(update_vsync)

	%ShadowFilterQuality.item_selected.connect(update_shadow_filter_quality)
	%ShadowHalfPrecision.toggled.connect(update_shadow_half_precision)
	%SSAOQuality.item_selected.connect(update_ssao_quality)
	%AdaptiveAOInput.text_submitted.connect(update_ssao_adaptive_target)
	%AdaptiveAOSlider.value_changed.connect(update_ssao_adaptive_target)
	%AOHalfSize.toggled.connect(update_ssao_half_size)
	%SSILQuality.item_selected.connect(update_ssil_quality)
	%AdaptiveILInput.text_submitted.connect(update_ssil_adaptive_target)
	%AdaptiveILSlider.value_changed.connect(update_ssil_adaptive_target)
	%ILHalfSize.toggled.connect(update_ssil_half_size)
	%MSAASamples.item_selected.connect(update_msaa_samples)
	%SSAAOption.item_selected.connect(update_ssaa)
	%UseTAA.toggled.connect(update_use_taa)
	%UseDebanding.toggled.connect(update_use_debanding)

	%SensitivitySlider.value_changed.connect(update_sensitivity)
	%SensitivityInput.text_submitted.connect(update_sensitivity)
	%InvertScroll.toggled.connect(update_invert_scroll)


func _ready() -> void:
	var window_mode: int
	match video_settings.window_mode:
		3: window_mode = 1
		4: window_mode = 2
		_: window_mode = 0
	%WindowMode.select(window_mode)
	%FovSlider.value = video_settings.fov
	%FovInput.text = "%d" % roundi(video_settings.fov)
	%CapFpsCheck.button_pressed = video_settings.cap_fps
	%FramerateLabel.theme_type_variation = "" if video_settings.cap_fps else "DisabledLabel"
	%FpsInput.editable = video_settings.cap_fps
	%FpsSlider.editable = video_settings.cap_fps
	%FpsInput.text = "%d" % video_settings.max_fps
	%FpsSlider.value = video_settings.max_fps
	%VsyncCheck.button_pressed = false if video_settings.vsync_mode == DisplayServer.VSYNC_DISABLED else true

	%ShadowFilterQuality.select(graphics_settings.shadow_filter_quality)
	%ShadowHalfPrecision.button_pressed = graphics_settings.shadow_half_precision
	%SSAOQuality.select(graphics_settings.ssao_quality)
	%AdaptiveAOLabel.theme_type_variation = "" if graphics_settings.ssao_quality == 4 else "DisabledLabel"
	%AdaptiveAOInput.editable = graphics_settings.ssao_quality == 4
	%AdaptiveAOSlider.editable = graphics_settings.ssao_quality == 4
	%AdaptiveAOInput.text = "%.3f" % graphics_settings.ssao_adaptive_target
	%AdaptiveAOSlider.value = graphics_settings.ssao_adaptive_target
	%AOHalfSize.button_pressed = graphics_settings.ssao_half_size
	%SSILQuality.select(graphics_settings.ssil_quality)
	%AdaptiveILLabel.theme_type_variation = "" if graphics_settings.ssil_quality == 4 else "DisabledLabel"
	%AdaptiveILInput.editable = graphics_settings.ssil_quality == 4
	%AdaptiveILSlider.editable = graphics_settings.ssil_quality == 4
	%AdaptiveILInput.text = "%.3f" % graphics_settings.ssil_adaptive_target
	%AdaptiveILSlider.value = graphics_settings.ssil_adaptive_target
	%ILHalfSize.button_pressed = graphics_settings.ssil_half_size
	%MSAASamples.select(graphics_settings.msaa_samples)
	%SSAAOption.select(graphics_settings.ssaa)
	%UseTAA.button_pressed = graphics_settings.use_taa
	%UseDebanding.button_pressed = graphics_settings.use_debanding

	%SensitivitySlider.value = controls_settings.mouse_sensitivity
	%SensitivityInput.text = "%.3f" % controls_settings.mouse_sensitivity
	%InvertScroll.button_pressed = controls_settings.invert_scroll


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back()
		get_viewport().set_input_as_handled()


func update_window_mode() -> void:
	var selected = %WindowMode.get_selected_id()

	unapplied_settings.video.window_mode = selected


func update_fov(value: Variant) -> void:
	if not value is String:
		value = str(value)
	var corrected_text: String = "%d" % roundi(clampf(float(value), video_settings.fov_minimum, video_settings.fov_maximum))
	var corrected_float: float = float(corrected_text)
	%FovSlider.value = corrected_float
	%FovInput.text = corrected_text

	unapplied_settings.video.fov = corrected_float


func update_fps_cap(button_pressed: bool) -> void:
	%FpsInput.editable = button_pressed
	%FpsSlider.editable = button_pressed
	%FramerateLabel.theme_type_variation = "" if button_pressed else "DisabledLabel"

	unapplied_settings.video.cap_fps = button_pressed


func update_max_fps(value: Variant) -> void:
	if not value is String:
		value = str(value)
	var corrected_text: String = "%d" % clampi(int(value), video_settings.fps_minimum, video_settings.fps_maximum)
	var corrected_int: float = float(corrected_text)
	%FpsSlider.value = corrected_int
	%FpsInput.text = corrected_text

	unapplied_settings.video.max_fps = corrected_int


func update_vsync(button_pressed: bool) -> void:
	unapplied_settings.video.vsync_mode = DisplayServer.VSYNC_ENABLED if button_pressed else DisplayServer.VSYNC_DISABLED


func update_shadow_filter_quality(index: int) -> void:
	unapplied_settings.graphics.shadow_filter_quality = index


func update_shadow_half_precision(button_pressed: bool) -> void:
	unapplied_settings.graphics.shadow_half_precision = button_pressed


func update_ssao_quality(index: int) -> void:
	%AdaptiveAOLabel.theme_type_variation = "" if index == 4 else "DisabledLabel"
	%AdaptiveAOInput.editable = index == 4
	%AdaptiveAOSlider.editable = index == 4

	unapplied_settings.graphics.ssao_quality = index


func update_ssao_adaptive_target(value: Variant) -> void:
	if not value is String:
		value = str(value)
	var corrected_text: String = "%.3f" % clampf(float(value), 0, 1)
	var corrected_float: float = float(corrected_text)
	%AdaptiveAOInput.text = corrected_text
	%AdaptiveAOSlider.value = corrected_float

	unapplied_settings.graphics.ssao_adaptive_target = corrected_float


func update_ssao_half_size(button_pressed: bool) -> void:
	unapplied_settings.graphics.ssao_half_size = button_pressed


func update_ssil_quality(index: int) -> void:
	%AdaptiveILLabel.theme_type_variation = "" if index == 4 else "DisabledLabel"
	%AdaptiveILInput.editable = index == 4
	%AdaptiveILSlider.editable = index == 4

	unapplied_settings.graphics.ssil_quality = index


func update_ssil_adaptive_target(value: Variant) -> void:
	if not value is String:
		value = str(value)
	var corrected_text: String = "%.3f" % clampf(float(value), 0, 1)
	var corrected_float: float = float(corrected_text)
	%AdaptiveILInput.text = corrected_text
	%AdaptiveILSlider.value = corrected_float

	unapplied_settings.graphics.ssil_adaptive_target = corrected_float


func update_ssil_half_size(button_pressed: bool) -> void:
	unapplied_settings.graphics.ssil_half_size = button_pressed


func update_msaa_samples(index: int) -> void:
	unapplied_settings.graphics.msaa_samples = index


func update_ssaa(index: int) -> void:
	unapplied_settings.graphics.ssaa = index


func update_use_taa(button_pressed: bool) -> void:
	unapplied_settings.graphics.use_taa = button_pressed


func update_use_debanding(button_pressed: bool) -> void:
	unapplied_settings.graphics.use_debanding = button_pressed


func update_sensitivity(value: Variant) -> void:
	if not value is String:
		value = str(value)
	var corrected_text: String = "%.3f" % clampf(float(value), 0, 10)
	var corrected_float: float = float(corrected_text)
	%SensitivitySlider.value = corrected_float
	%SensitivityInput.text = corrected_text

	unapplied_settings.controls.mouse_sensitivity = corrected_float


func update_invert_scroll(button_pressed: bool) -> void:
	unapplied_settings.controls.invert_scroll = button_pressed


func reset_unapplied_settings() -> void:
	unapplied_settings.clear()
	unapplied_settings = {
		video = {},
		graphics = {},
		controls = {},
		gameplay = {},
	}


func back() -> void:
	for section in unapplied_settings:
		if unapplied_settings[section].size() > 0:
			print("Unapplied settings.")
			break
	reset_unapplied_settings()
	queue_free()


func apply_changes(close: bool = false) -> void:
	update_window_mode()
	update_sensitivity(%SensitivityInput.text)
	update_fov(%FovInput.text)
	update_fps_cap(%CapFpsCheck.button_pressed)
	update_max_fps(%FpsInput.text)
	update_vsync(%VsyncCheck.button_pressed)
	for section in unapplied_settings:
		for key in unapplied_settings[section]:
			Settings.settings[section][key] = unapplied_settings[section][key]
	Settings.update_settings()
	Settings.save_settings()
	reset_unapplied_settings()
	if close:
		back()
