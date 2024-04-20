extends Control


func _ready() -> void:
	%QuitButton.pressed.connect(_on_button_quit)
	%SelectWorldButton.pressed.connect(_on_button_select_world)
	%SettingsButton.pressed.connect(_on_button_settings)


func _on_button_select_world() -> void:
	open_world_select()


func _on_button_settings() -> void:
	open_settings()


func _on_button_quit() -> void:
	quit()


func open_world_select() -> void:
	add_child(UI.world_selector_scene.instantiate())


func open_settings() -> void:
	add_child(UI.settings_scene.instantiate())


func quit() -> void:
	print("Quitting.")
	get_tree().quit()
