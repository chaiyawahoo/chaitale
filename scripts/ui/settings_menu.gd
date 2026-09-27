extends Control


var unapplied_settings: Dictionary = {
		video = {},
		graphics = {},
		controls = {},
		gameplay = {},
	}
var dirty := false:
	set(value):
		dirty = value
		_refresh()

@onready var video_settings: Dictionary = Settings.settings.video
@onready var graphics_settings: Dictionary = Settings.settings.graphics
@onready var controls_settings: Dictionary = Settings.settings.controls
@onready var gameplay_settings: Dictionary = Settings.settings.gameplay


func _enter_tree() -> void:
	_bind_ui()
	
	%TabContainer.set_tab_hidden(3, true)


func _ready() -> void:
	_update_ui()
	reset_unapplied_settings()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back()
		get_viewport().set_input_as_handled()
		return


func _refresh() -> void:
	%ApplyButton.disabled = not dirty
	%DiscardButton.disabled = not dirty


func _bind_ui() -> void:
	%BackButton.pressed.connect(back)
	%ApplyButton.pressed.connect(apply_changes)
	%DiscardButton.pressed.connect(discard_changes)

	%WindowModeOption.item_selected.connect(update_window_mode.unbind(1))
	%CapFpsCheck.toggled.connect(update_fps_cap)
	%FpsInput.text_submitted.connect(update_max_fps)
	%FpsInput.text_changed.connect(update_max_fps)
	%FpsInput.focus_exited.connect(update_max_fps.bind(%FpsInput.text))
	%FpsSlider.value_changed.connect(update_max_fps)
	%VsyncCheck.toggled.connect(update_vsync)
	%FovInput.text_submitted.connect(update_fov)
	%FovInput.text_changed.connect(update_fov)
	%FovInput.focus_exited.connect(update_fov.bind(%FovInput.text))
	%FovSlider.value_changed.connect(update_fov)

	%ShadowFilterQualityOption.item_selected.connect(update_shadow_filter_quality)
	%ShadowHalfPrecisionCheck.toggled.connect(update_shadow_half_precision)
	%SSAOQualityCheck.item_selected.connect(update_ssao_quality)
	%AdaptiveAOInput.text_submitted.connect(update_ssao_adaptive_target)
	%AdaptiveAOInput.text_changed.connect(update_ssao_adaptive_target)
	%AdaptiveAOInput.focus_exited.connect(update_ssao_adaptive_target.bind(%AdaptiveAOInput.text))
	%AdaptiveAOSlider.value_changed.connect(update_ssao_adaptive_target)
	%AOHalfSizeCheck.toggled.connect(update_ssao_half_size)
	%SSILQualityOption.item_selected.connect(update_ssil_quality)
	%AdaptiveILInput.text_submitted.connect(update_ssil_adaptive_target)
	%AdaptiveILInput.text_changed.connect(update_ssil_adaptive_target)
	%AdaptiveILInput.focus_exited.connect(update_ssil_adaptive_target.bind(%AdaptiveILInput.text))
	%AdaptiveILSlider.value_changed.connect(update_ssil_adaptive_target)
	%ILHalfSizeCheck.toggled.connect(update_ssil_half_size)
	%MSAASamplesOption.item_selected.connect(update_msaa_samples)
	%SSAAOption.item_selected.connect(update_ssaa)
	%UseTAACheck.toggled.connect(update_use_taa)
	%UseDebandingCheck.toggled.connect(update_use_debanding)

	%SensitivityInput.text_submitted.connect(update_sensitivity)
	%SensitivityInput.text_changed.connect(update_sensitivity)
	%SensitivityInput.focus_exited.connect(update_sensitivity.bind(%SensitivityInput.text))
	%SensitivitySlider.value_changed.connect(update_sensitivity)
	%InvertScrollCheck.toggled.connect(update_invert_scroll)
	%ToggleSprintCheck.toggled.connect(update_toggle_sprint)
	%ToggleSneakCheck.toggled.connect(update_toggle_sneak)


func _update_ui() -> void:
	var window_mode: int
	match video_settings.window_mode:
		3: window_mode = 1
		4: window_mode = 2
		_: window_mode = 0
	%WindowModeOption.select(window_mode)
	%CapFpsCheck.button_pressed = video_settings.cap_fps
	%FramerateLabel.theme_type_variation = "" if video_settings.cap_fps else "DisabledLabel"
	%FpsInput.editable = video_settings.cap_fps
	%FpsSlider.editable = video_settings.cap_fps
	%FpsInput.text = "%d" % video_settings.max_fps
	%FpsSlider.value = video_settings.max_fps
	%VsyncCheck.button_pressed = false if video_settings.vsync_mode == DisplayServer.VSYNC_DISABLED else true
	%FovInput.text = "%d" % roundi(video_settings.fov)
	%FovSlider.value = video_settings.fov
	
	%ShadowFilterQualityOption.select(graphics_settings.shadow_filter_quality)
	%ShadowHalfPrecisionCheck.button_pressed = graphics_settings.shadow_half_precision
	%SSAOQualityCheck.select(graphics_settings.ssao_quality)
	%AdaptiveAOLabel.theme_type_variation = "" if graphics_settings.ssao_quality == 4 else "DisabledLabel"
	%AdaptiveAOInput.editable = graphics_settings.ssao_quality == 4
	%AdaptiveAOSlider.editable = graphics_settings.ssao_quality == 4
	%AdaptiveAOInput.text = "%.3f" % graphics_settings.ssao_adaptive_target
	%AdaptiveAOSlider.value = graphics_settings.ssao_adaptive_target
	%AOHalfSizeCheck.button_pressed = graphics_settings.ssao_half_size
	%SSILQualityOption.select(graphics_settings.ssil_quality)
	%AdaptiveILLabel.theme_type_variation = "" if graphics_settings.ssil_quality == 4 else "DisabledLabel"
	%AdaptiveILInput.editable = graphics_settings.ssil_quality == 4
	%AdaptiveILSlider.editable = graphics_settings.ssil_quality == 4
	%AdaptiveILInput.text = "%.3f" % graphics_settings.ssil_adaptive_target
	%AdaptiveILSlider.value = graphics_settings.ssil_adaptive_target
	%ILHalfSizeCheck.button_pressed = graphics_settings.ssil_half_size
	%MSAASamplesOption.select(graphics_settings.msaa_samples)
	%SSAAOption.select(graphics_settings.ssaa)
	%UseTAACheck.button_pressed = graphics_settings.use_taa
	%UseDebandingCheck.button_pressed = graphics_settings.use_debanding
	
	%SensitivityInput.text = "%.3f" % controls_settings.mouse_sensitivity
	%SensitivitySlider.value = controls_settings.mouse_sensitivity
	%InvertScrollCheck.button_pressed = controls_settings.invert_scroll
	%ToggleSprintCheck.button_pressed = controls_settings.toggle_sprint
	%ToggleSneakCheck.button_pressed = controls_settings.toggle_sneak


func update_window_mode() -> void:
	var selected: int = %WindowModeOption.get_selected_id()

	unapplied_settings.video.window_mode = selected
	dirty = true


func update_fov(value) -> void:
	if not value:
		value = %FovInput.text
	if not value is String:
		value = str(value)
	var corrected_text := "%d" % roundi(clampf(float(value), video_settings.fov_minimum, video_settings.fov_maximum))
	var corrected_float := float(corrected_text)
	if get_viewport().gui_get_focus_owner() != %FovInput:
		%FovInput.text = corrected_text
	%FovSlider.value = corrected_float

	unapplied_settings.video.fov = corrected_float
	dirty = true


func update_fps_cap(button_pressed: bool) -> void:
	%FpsInput.editable = button_pressed
	%FpsSlider.editable = button_pressed
	%FramerateLabel.theme_type_variation = "" if button_pressed else "DisabledLabel"

	unapplied_settings.video.cap_fps = button_pressed
	dirty = true


func update_max_fps(value) -> void:
	if not value is String:
		value = str(value)
	var corrected_text := "%d" % clampi(int(value), video_settings.fps_minimum, video_settings.fps_maximum)
	var corrected_int := float(corrected_text)
	if get_viewport().gui_get_focus_owner() != %FpsInput:
		%FpsInput.text = corrected_text
	%FpsSlider.value = corrected_int

	unapplied_settings.video.max_fps = corrected_int
	dirty = true


func update_vsync(button_pressed: bool) -> void:
	unapplied_settings.video.vsync_mode = DisplayServer.VSYNC_ENABLED if button_pressed else DisplayServer.VSYNC_DISABLED
	dirty = true


func update_shadow_filter_quality(index: int) -> void:
	unapplied_settings.graphics.shadow_filter_quality = index
	dirty = true


func update_shadow_half_precision(button_pressed: bool) -> void:
	unapplied_settings.graphics.shadow_half_precision = button_pressed
	dirty = true


func update_ssao_quality(index: int) -> void:
	%AdaptiveAOLabel.theme_type_variation = "" if index == 4 else "DisabledLabel"
	%AdaptiveAOInput.editable = index == 4
	%AdaptiveAOSlider.editable = index == 4

	unapplied_settings.graphics.ssao_quality = index
	dirty = true


func update_ssao_adaptive_target(value) -> void:
	if not value is String:
		value = str(value)
	var corrected_text := "%.3f" % clampf(float(value), 0, 1)
	var corrected_float := float(corrected_text)
	if get_viewport().gui_get_focus_owner() != %AdaptiveAOInput:
		%AdaptiveAOInput.text = corrected_text
	%AdaptiveAOSlider.value = corrected_float

	unapplied_settings.graphics.ssao_adaptive_target = corrected_float
	dirty = true


func update_ssao_half_size(button_pressed: bool) -> void:
	unapplied_settings.graphics.ssao_half_size = button_pressed
	dirty = true


func update_ssil_quality(index: int) -> void:
	%AdaptiveILLabel.theme_type_variation = "" if index == 4 else "DisabledLabel"
	%AdaptiveILInput.editable = index == 4
	%AdaptiveILSlider.editable = index == 4

	unapplied_settings.graphics.ssil_quality = index
	dirty = true


func update_ssil_adaptive_target(value) -> void:
	if not value is String:
		value = str(value)
	var corrected_text := "%.3f" % clampf(float(value), 0, 1)
	var corrected_float := float(corrected_text)
	if get_viewport().gui_get_focus_owner() != %AdaptiveILInput:
		%AdaptiveILInput.text = corrected_text
	%AdaptiveILSlider.value = corrected_float

	unapplied_settings.graphics.ssil_adaptive_target = corrected_float
	dirty = true


func update_ssil_half_size(button_pressed: bool) -> void:
	unapplied_settings.graphics.ssil_half_size = button_pressed
	dirty = true


func update_msaa_samples(index: int) -> void:
	unapplied_settings.graphics.msaa_samples = index
	dirty = true


func update_ssaa(index: int) -> void:
	unapplied_settings.graphics.ssaa = index
	dirty = true


func update_use_taa(button_pressed: bool) -> void:
	unapplied_settings.graphics.use_taa = button_pressed
	dirty = true


func update_use_debanding(button_pressed: bool) -> void:
	unapplied_settings.graphics.use_debanding = button_pressed
	dirty = true


func update_sensitivity(value) -> void:
	if not value is String:
		value = str(value)
	var corrected_text := "%.3f" % clampf(float(value), 0, 10)
	var corrected_float := float(corrected_text)
	if get_viewport().gui_get_focus_owner() != %SensitivityInput:
		%SensitivityInput.text = corrected_text
	%SensitivitySlider.value = corrected_float

	unapplied_settings.controls.mouse_sensitivity = corrected_float
	dirty = true


func update_invert_scroll(button_pressed: bool) -> void:
	unapplied_settings.controls.invert_scroll = button_pressed
	dirty = true


func update_toggle_sprint(button_pressed: bool) -> void:
	unapplied_settings.controls.toggle_sprint = button_pressed
	dirty = true


func update_toggle_sneak(button_pressed: bool) -> void:
	unapplied_settings.controls.toggle_sneak = button_pressed
	dirty = true


func reset_unapplied_settings() -> void:
	unapplied_settings.clear()
	unapplied_settings = {
		video = {},
		graphics = {},
		controls = {},
		gameplay = {},
	}
	dirty = false


func back() -> void:
	for section in unapplied_settings:
		if unapplied_settings[section].size() > 0:
			print("Unapplied settings.")
			break
	reset_unapplied_settings()
	queue_free()


func apply_changes() -> void:
	for section in unapplied_settings:
		for key in unapplied_settings[section]:
			Settings.settings[section][key] = unapplied_settings[section][key]
	Settings.update_settings()
	Settings.save_settings()
	reset_unapplied_settings()


func discard_changes() -> void:
	_update_ui()
	reset_unapplied_settings()
