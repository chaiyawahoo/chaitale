extends CanvasLayer


func _ready() -> void:
	if not Game.pause_menu:
		Game.pause_menu = self
	%ResumeButton.pressed.connect(_on_button_resume)
	%SaveButton.pressed.connect(_on_button_save)
	%SaveQuitButton.pressed.connect(_on_button_save_and_quit)
	%QuitNoSaveButton.pressed.connect(_on_button_quit_no_save)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		toggle_menu()


func _on_button_resume() -> void:
	toggle_menu()


func _on_button_save() -> void:
	save()


func _on_button_save_and_quit() -> void:
	save()
	if Game.terrain:
		await Game.terrain.save_success
	quit()


func _on_button_quit_no_save() -> void:
	quit()


func save() -> void:
	if not Game.terrain:
		return
	Game.terrain.save()


func quit() -> void:
	get_tree().quit()


func toggle_menu() -> void:
	visible = not visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED
