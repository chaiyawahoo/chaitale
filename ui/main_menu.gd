extends Control


func _ready() -> void:
	%QuitButton.pressed.connect(_on_button_quit)
	%SelectWorldButton.pressed.connect(_on_button_select_world)


func _on_button_quit() -> void:
	quit()


func _on_button_select_world() -> void:
	select_world()


func quit() -> void:
	get_tree().quit()


func select_world() -> void:
	get_tree().change_scene_to_packed(UI.world_selector_scene)
