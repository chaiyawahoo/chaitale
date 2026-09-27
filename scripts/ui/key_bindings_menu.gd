extends Control


signal dirtied


var settings_menu: Control
var is_rebinding := false
var rebind_action_name := ""
var action_buttons := {} # { String: Button }
var revert_buttons := {} # { String: Button }
var pending_rebinds := {} # { String: InputEvent }
var custom_input_actions := {
	"move_left": "Move Left",
	"move_right": "Move Right",
	"move_forward": "Move Forward",
	"move_backward": "Move Backward",
	"jump": "Jump",
	"pause": "Pause",
	"camera_mode": "Cycle Camera",
	"sprint": "Sprint",
	"sneak": "Sneak",
	"left_click": "Attack",
	"right_click": "Use",
	"select_1": "Hotbar Slot 1",
	"select_2": "Hotbar Slot 2",
	"select_3": "Hotbar Slot 3",
	"select_4": "Hotbar Slot 4",
	"select_5": "Hotbar Slot 5",
	"select_6": "Hotbar Slot 6",
	"select_7": "Hotbar Slot 7",
	"select_8": "Hotbar Slot 8",
	"select_9": "Hotbar Slot 9",
	"toggle_debug": "Toggle Debug",
	"toggle_ui": "Toggle UI",
}


func _enter_tree() -> void:
	refresh_all_key_bindings()


func _input(event: InputEvent) -> void:
	if not is_rebinding:
		return
	
	if event is InputEventKey or (event is InputEventMouseButton and event.is_pressed()):
		pending_rebinds[rebind_action_name] = event
		action_buttons[rebind_action_name].text = event.as_text().trim_suffix(" (Physical)").trim_suffix(" - All Devices")
		revert_buttons[rebind_action_name].disabled = false
		is_rebinding = false
		dirtied.emit()
		accept_event()
		return

func _populate_key_bindings_container() -> void:
	for node in get_children():
		node.queue_free()
	
	for action_name in InputMap.get_actions():
		if not custom_input_actions.has(action_name):
			continue
		
		var action_container := HBoxContainer.new()
		var button_container := HBoxContainer.new()
		var action_label := Label.new()
		var action_button := Button.new()
		var clear_button := Button.new()
		var revert_button := Button.new()
		
		action_label.text = custom_input_actions[action_name]
		action_button.text = get_action_event_name(action_name)
		clear_button.text = "Clear"
		revert_button.text = "Revert"
		revert_button.disabled = true
		
		action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		action_button.pressed.connect(_on_action_button_pressed.bind(action_name))
		clear_button.pressed.connect(_on_clear_button_pressed.bind(action_name))
		revert_button.pressed.connect(_on_revert_button_pressed.bind(action_name))
		
		action_container.add_child(action_label)
		action_container.add_child(button_container)
		button_container.add_child(action_button)
		button_container.add_child(clear_button)
		button_container.add_child(revert_button)
		
		action_buttons[action_name] = action_button
		revert_buttons[action_name] = revert_button
		
		add_child(action_container)
	
	var reset_button := Button.new()
	reset_button.text = "Reset Key Bindings to Default"
	reset_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	reset_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	reset_button.pressed.connect(_on_reset_button_pressed)
	
	add_child(reset_button)


func get_action_event_name(action_name: String) -> String:
	if not InputMap.has_action(action_name):
		return "(Unset)"
	
	var events: Array[InputEvent] = InputMap.action_get_events(action_name)
	
	if events.is_empty():
		return "(Unset)"
	
	return events[0].as_text().trim_suffix(" (Physical)").trim_suffix(" - All Devices")


func get_key_bindings_from_settings() -> void:
	var key_bindings = Settings.settings.key_bindings
	for action_name in key_bindings:
		if key_bindings[action_name].type == "none":
			InputMap.action_erase_events(action_name)
			continue
		
		var event: InputEvent
		
		if key_bindings[action_name].type == "Key":
			event = InputEventKey.new()
			event.physical_keycode = key_bindings[action_name].value

		
		if key_bindings[action_name].type == "MouseButton":
			event = InputEventMouseButton.new()
			event.button_index = key_bindings[action_name].value
		
		InputMap.action_erase_events(action_name)
		InputMap.action_add_event(action_name, event)


func apply_key_bindings() -> void:
	for action_name in custom_input_actions:
		if not InputMap.has_action(action_name):
			continue
		
		var input_event: InputEvent
		var input_type: String = "none"
		var input_value: int = -1
		
		if pending_rebinds.has(action_name):
			input_event = pending_rebinds[action_name]
		else:
			var events = InputMap.action_get_events(action_name)
			if not events.is_empty():
				input_event = events[0]
		
		if input_event is InputEventKey:
			input_type = "Key"
			input_value = input_event.physical_keycode
		
		if input_event is InputEventMouseButton:
			input_type = "MouseButton"
			input_value = input_event.button_index
		
		InputMap.action_erase_events(action_name)
		
		if input_type != "none":
			InputMap.action_add_event(action_name, input_event)
		
		Settings.settings.key_bindings[action_name] = { type = input_type, value = input_value }
	
	Settings.save_settings()
	Settings.update_settings()
	reset_all_key_bindings()


func refresh_all_key_bindings() -> void:
	InputMap.load_from_project_settings()
	get_key_bindings_from_settings()
	apply_key_bindings()
	_populate_key_bindings_container()


func reset_all_key_bindings() -> void:
	pending_rebinds.clear()
	_populate_key_bindings_container()


func _on_action_button_pressed(action_name: String) -> void:
	action_buttons[action_name].text = "Press Any Button..."
	rebind_action_name = action_name
	is_rebinding = true


func _on_clear_button_pressed(action_name: String) -> void:
	if get_action_event_name(action_name) == "(Unset)" or action_buttons[action_name].text == "(Unset)":
		return
	
	pending_rebinds[action_name] = InputEventAction.new()
	action_buttons[action_name].text = "(Unset)"
	revert_buttons[action_name].disabled = false
	dirtied.emit()


func _on_revert_button_pressed(action_name: String) -> void:
	if pending_rebinds.erase(action_name):
		action_buttons[action_name].text = get_action_event_name(action_name)
		revert_buttons[action_name].disabled = true
		dirtied.emit()


func _on_reset_button_pressed() -> void:
	InputMap.load_from_project_settings()
	for action_name in custom_input_actions:
		if not InputMap.has_action(action_name):
			continue
		
		var events = InputMap.action_get_events(action_name)
		if not events.is_empty():
			pending_rebinds[action_name] = events[0]
		
		if revert_buttons.has(action_name):
			revert_buttons[action_name].disabled = false
		
		if action_buttons.has(action_name):
			action_buttons[action_name].text = get_action_event_name(action_name)
		
	get_key_bindings_from_settings() # in case discard changes doesnt get called
	dirtied.emit()
