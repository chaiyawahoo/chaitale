class_name Game
extends Node3D


signal terrain_meshed

static var terrain: VoxelTerrain
static var menu_opened: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		toggle_menu()


func toggle_menu() -> void:
	menu_opened = not menu_opened
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if menu_opened else Input.MOUSE_MODE_CAPTURED
