extends CanvasLayer


func _ready() -> void:
	%ResumeButton.pressed.connect(_on_button_resume)
	%SettingsButton.pressed.connect(_on_button_settings)
	%QuitButton.pressed.connect(_on_button_quit)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and Game.terrain:
		toggle_pause()


func _on_button_resume() -> void:
	toggle_pause()


func _on_button_settings() -> void:
	open_settings()


func _on_button_quit() -> void:
	if multiplayer.is_server():
		save()
		if Game.terrain:
			await SaveEngine.save_success
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
