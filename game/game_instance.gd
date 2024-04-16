class_name GameInstance
extends Node3D


var autosave_tick_interval: int = 1200 # one minute


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	TickEngine.ticked.connect(_on_tick)


func _on_tick() -> void:
	autosave()


func autosave() -> void:
	if TickEngine.ticks_elapsed % autosave_tick_interval:
		return
	if not Game.terrain:
		return
	print("Autosaving...")
	Game.terrain.save()
