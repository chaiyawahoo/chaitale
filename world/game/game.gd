class_name Game
extends Node3D


static var terrain: VoxelTerrain
static var voxel_tool: VoxelTool
static var player: Player
static var pause_menu: CanvasLayer

static var menu_opened: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		toggle_menu()


func toggle_menu() -> void:
	menu_opened = not menu_opened
	if pause_menu:
		pause_menu.visible = menu_opened
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if menu_opened else Input.MOUSE_MODE_CAPTURED
