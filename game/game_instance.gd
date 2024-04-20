class_name GameInstance
extends Node3D


func _enter_tree() -> void:
	Game.instance = self
	TickEngine.start_ticking()


func _ready() -> void:
	print("Game ready.")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if SaveEngine.is_new_save:
		SaveEngine.save_game()
	SaveEngine.load_game()


func _exit_tree() -> void:
	TickEngine.stop_ticking()