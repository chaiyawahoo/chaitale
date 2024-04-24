extends CanvasLayer


func _ready() -> void:
	%QuitButton.pressed.connect(_on_button_quit)
	%SelectWorldButton.pressed.connect(_on_button_select_world)
	%SettingsButton.pressed.connect(_on_button_settings)
	%LoginButton.pressed.connect(_on_button_login)
	%JoinWorldButton.pressed.connect(_on_button_join_world)
	%LogoutButton.pressed.connect(_on_button_logout)


func _on_button_select_world() -> void:
	open_world_select()


func _on_button_settings() -> void:
	open_settings()


func _on_button_quit() -> void:
	quit()


func _on_button_login() -> void:
	login()


func _on_button_join_world() -> void:
	Multiplayer.join_server()


func _on_button_logout() -> void:
	logout()


func set_username(username: String) -> void:
	Multiplayer.player_info.name = username


func open_world_select() -> void:
	add_child(UI.world_selector_scene.instantiate())


func open_settings() -> void:
	add_child(UI.settings_scene.instantiate())


func quit() -> void:
	print("Quitting.")
	get_tree().quit()


func login() -> void:
	set_username(%UsernameInput.text)
	%LoggedInAs.visible = true
	%UsernameLabel.text = Multiplayer.player_info.name
	%UsernameInput.visible = false
	%LoginButton.visible = false
	%LogoutButton.visible = true
	%SelectWorldButton.visible = true
	%JoinWorldButton.visible = true
	%SettingsButton.visible = true


func logout() -> void:
	set_username("")
	%LoggedInAs.visible = false
	%UsernameLabel.text = ""
	%UsernameInput.visible = true
	%UsernameInput.text = ""
	%LoginButton.visible = true
	%LogoutButton.visible = false
	%SelectWorldButton.visible = false
	%JoinWorldButton.visible = false
	%SettingsButton.visible = false