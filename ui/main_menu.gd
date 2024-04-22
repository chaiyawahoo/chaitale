extends Control


func _ready() -> void:
	%QuitButton.pressed.connect(_on_button_quit)
	%SelectWorldButton.pressed.connect(_on_button_select_world)
	%SettingsButton.pressed.connect(_on_button_settings)
	%LoginButton.pressed.connect(_on_button_login)
	%JoinWorldButton.pressed.connect(_on_button_join_world)


func _on_button_select_world() -> void:
	open_world_select()


func _on_button_settings() -> void:
	open_settings()


func _on_button_quit() -> void:
	quit()


func _on_button_login() -> void:
	set_username(%UsernameInput.text)
	show_post_login()


func _on_button_join_world() -> void:
	Multiplayer.join_server()


func set_username(username: String) -> void:
	Multiplayer.player_info.name = username


func open_world_select() -> void:
	add_child(UI.world_selector_scene.instantiate())


func open_settings() -> void:
	add_child(UI.settings_scene.instantiate())


func quit() -> void:
	print("Quitting.")
	get_tree().quit()


func show_post_login() -> void:
	%LoggedInAs.visible = true
	%UsernameLabel.text = Multiplayer.player_info.name
	%UsernameInput.visible = false
	%LoginButton.visible = false
	%SelectWorldButton.visible = true
	%JoinWorldButton.visible = true
	%SettingsButton.visible = true