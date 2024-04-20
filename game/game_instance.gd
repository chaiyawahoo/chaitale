class_name GameInstance
extends Node3D


func _enter_tree() -> void:
	Game.instance = self


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if SaveEngine.is_new_save:
		SaveEngine.save_game()
	SaveEngine.load_game()
