extends Control


var unapplied_settings: Dictionary = {}


func _enter_tree() -> void:
	%BackButton.pressed.connect(_on_button_back)
	%ApplyButton.pressed.connect(_on_button_apply)
	%ApplyCloseButton.pressed.connect(_on_button_apply_close)
	%WindowMode.item_selected.connect(_on_window_mode_selected)
	%SensitivitySlider.value_changed.connect(_on_sensitivity_slider_changed)
	%SensitivityInput.text_submitted.connect(_on_sensitivity_text_submitted)
	%FovSlider.value_changed.connect(_on_fov_slider_changed)
	%FovInput.text_submitted.connect(_on_fov_text_submitted)
	%CapFpsCheck.toggled.connect(_on_cap_fps_toggled)
	%FpsSlider.value_changed.connect(_on_max_fps_slider_changed)
	%FpsInput.text_submitted.connect(_on_max_fps_text_submitted)
	%VsyncCheck.toggled.connect(_on_vsync_toggled)


func _ready() -> void:
	var window_mode: int
	match Settings.window_mode:
		3: window_mode = 1
		4: window_mode = 2
		_: window_mode = 0
	%WindowMode.select(window_mode)
	%SensitivitySlider.value = Settings.mouse_sensitivity
	%SensitivityInput.text = "%.3f" % Settings.mouse_sensitivity
	%FovSlider.value = Settings.fov
	%FovInput.text = "%d" % roundi(Settings.fov)
	%CapFpsCheck.button_pressed = Settings.cap_fps
	%FpsInput.editable = Settings.cap_fps
	%FpsSlider.editable = Settings.cap_fps
	%FramerateLabel.theme_type_variation = "" if Settings.cap_fps else "DisabledLabel"
	%FpsSlider.value = Settings.max_fps
	%FpsInput.text = "%d" % Settings.max_fps
	%VsyncCheck.button_pressed = false if Settings.vsync_mode == DisplayServer.VSYNC_DISABLED else true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back()
		get_viewport().set_input_as_handled()


func _on_window_mode_selected(_index: int) -> void:
	update_window_mode()


func _on_sensitivity_text_submitted(new_text: String) -> void:
	update_sensitivity(new_text)


func _on_sensitivity_slider_changed(value: float) -> void:
	update_sensitivity(str(value))


func _on_fov_text_submitted(new_text: String) -> void:
	update_fov(new_text)


func _on_fov_slider_changed(value: float) -> void:
	update_fov(str(value))


func _on_cap_fps_toggled(button_pressed: bool) -> void:
	update_fps_cap(button_pressed)


func _on_max_fps_text_submitted(new_text: String) -> void:
	update_max_fps(new_text)


func _on_max_fps_slider_changed(value: float) -> void:
	update_max_fps(str(value))


func _on_vsync_toggled(button_pressed: bool) -> void:
	update_vsync(button_pressed)


func _on_button_back() -> void:
	back()


func _on_button_apply() -> void:
	apply_changes()


func _on_button_apply_close() -> void:
	apply_changes()
	back()


func update_window_mode() -> void:
	var selected = %WindowMode.get_selected_id()

	unapplied_settings.window_mode = selected


func update_sensitivity(value: String) -> void:
	var corrected_text: String = "%.3f" % clampf(float(value), 0, 10)
	var corrected_float: float = float(corrected_text)
	%SensitivitySlider.value = corrected_float
	%SensitivityInput.text = corrected_text

	unapplied_settings.mouse_sensitivity = corrected_float


func update_fov(value: String) -> void:
	var corrected_text: String = "%d" % roundi(clampf(float(value), Settings.fov_minimum, Settings.fov_maximum))
	var corrected_float: float = float(corrected_text)
	%FovSlider.value = corrected_float
	%FovInput.text = corrected_text

	unapplied_settings.fov = corrected_float


func update_fps_cap(button_pressed: bool) -> void:
	%FpsInput.editable = button_pressed
	%FpsSlider.editable = button_pressed
	%FramerateLabel.theme_type_variation = "" if button_pressed else "DisabledLabel"

	unapplied_settings.cap_fps = button_pressed


func update_max_fps(value: String) -> void:
	var corrected_text: String = "%d" % clampi(int(value), Settings.fps_minimum, Settings.fps_maximum)
	var corrected_int: float = float(corrected_text)
	%FpsSlider.value = corrected_int
	%FpsInput.text = corrected_text

	unapplied_settings.max_fps = corrected_int

func update_vsync(button_pressed: bool) -> void:
	unapplied_settings.vsync_mode = DisplayServer.VSYNC_ENABLED if button_pressed else DisplayServer.VSYNC_DISABLED


func back() -> void:
	if unapplied_settings.size() > 0:
		print("Unapplied changes")
	unapplied_settings.clear()
	queue_free()


func apply_changes() -> void:
	update_window_mode()
	update_sensitivity(%SensitivityInput.text)
	update_fov(%FovInput.text)
	update_fps_cap(%CapFpsCheck.button_pressed)
	update_max_fps(%FpsInput.text)
	update_vsync(%VsyncCheck.button_pressed)
	for setting_key in unapplied_settings:
		Settings.set(setting_key, unapplied_settings[setting_key])
	Settings.update_settings()
	unapplied_settings.clear()
