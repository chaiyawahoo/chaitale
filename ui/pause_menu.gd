extends CanvasLayer


func _ready() -> void:
	%ResumeButton.pressed.connect(_on_button_resume)
	%SettingsButton.pressed.connect(_on_button_settings)
	%SaveButton.pressed.connect(_on_button_save)
	%SaveQuitButton.pressed.connect(_on_button_save_and_quit)
	%QuitNoSaveButton.pressed.connect(_on_button_quit_no_save)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and Game.terrain:
		toggle_pause()


func _on_button_resume() -> void:
	toggle_pause()


func _on_button_settings() -> void:
	open_settings()


func _on_button_save() -> void:
	save()


func _on_button_save_and_quit() -> void:
	save()
	if Game.terrain:
		await SaveEngine.save_success
	quit()


func _on_button_quit_no_save() -> void:
	quit()


func open_settings() -> void:
	add_child(UI.settings_scene.instantiate())


func save() -> void:
	SaveEngine.save_game()


func quit() -> void:
	Main.close_level()


func toggle_pause() -> void:
	visible = not visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED
