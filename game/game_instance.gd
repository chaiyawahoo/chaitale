class_name GameInstance
extends Node3D


var player_scene: PackedScene = preload("res://client/player/player.tscn")

@onready var loading_screen: CanvasLayer = $LoadingScreen
@onready var hud: CanvasLayer = $HUD


func _enter_tree() -> void:
	Game.instance = self
	TickEngine.start_ticking()


func _ready() -> void:
	print("Game ready.")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var spawn_viewer = VoxelViewer.new()
	add_child(spawn_viewer)
	await Game.terrain.meshed
	remove_child(spawn_viewer)
	Game.player = player_scene.instantiate()
	add_child(Game.player)
	if SaveEngine.is_new_save:
		# multiplayer: check if player name exists in save
		Game.player.position.y = Game.terrain.highest_voxel_position.y + 2
		Game.player.position.x = 0.5
		Game.player.position.z = 0.5
		SaveEngine.save_game()
	SaveEngine.load_game()


func _exit_tree() -> void:
	TickEngine.stop_ticking()


func hide_loading_screen() -> void:
	loading_screen.visible = false


func show_hud() -> void:
	hud.visible = true