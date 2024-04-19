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


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back()
		get_viewport().set_input_as_handled()


func _on_window_mode_selected(_index: int):
	update_window_mode()

func _on_sensitivity_text_submitted(new_text: String) -> void:
	update_sensitivity(new_text)


func _on_sensitivity_slider_changed(value: float) -> void:
	update_sensitivity(str(value))


func _on_fov_text_submitted(new_text: String) -> void:
	update_fov(new_text)


func _on_fov_slider_changed(value: float) -> void:
	update_fov(str(value))


func _on_button_back() -> void:
	back()


func _on_button_apply() -> void:
	apply_changes()


func _on_button_apply_close() -> void:
	apply_changes()
	back()


func update_window_mode():
	var selected = %WindowMode.get_selected_id()
	if selected == Settings.window_mode:
		return
	unapplied_settings.window_mode = selected


func update_sensitivity(value: String):
	var corrected_text: String = "%.3f" % clampf(float(value), 0, 10)
	var corrected_float: float = float(corrected_text)
	%SensitivitySlider.value = corrected_float
	%SensitivityInput.text = corrected_text

	if corrected_float == Settings.mouse_sensitivity:
		return	
	unapplied_settings.mouse_sensitivity = corrected_float


func update_fov(value: String):
	var corrected_text: String = "%d" % roundi(clampf(float(value), Settings.fov_minimum, Settings.fov_maximum))
	var corrected_float: float = float(corrected_text)
	%FovSlider.value = corrected_float
	%FovInput.text = corrected_text

	if corrected_float == Settings.fov:
		return
	unapplied_settings.fov = corrected_float


func back() -> void:
	if unapplied_settings.size() > 0:
		print("unapplied changes")
	unapplied_settings.clear()
	queue_free()


func apply_changes() -> void:
	update_window_mode()
	update_sensitivity(%SensitivityInput.text)
	update_fov(%FovInput.text)
	for setting_key in unapplied_settings:
		Settings.set(setting_key, unapplied_settings[setting_key])
	Settings.update_settings()
	unapplied_settings.clear()
