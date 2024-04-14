class_name Game
extends Node3D


static var terrain: VoxelTerrain
static var voxel_tool: VoxelTool
static var player: Player
static var pause_menu: CanvasLayer

var autosave_tick_interval: int = 1200 # one minute


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	TickEngine.ticked.connect(_on_tick)


func _on_tick() -> void:
	if not TickEngine.ticks_elapsed % autosave_tick_interval:
		if Game.terrain:
			print("Autosaving...")
			Game.terrain.save()
