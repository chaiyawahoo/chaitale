class_name GameInstance
extends Node3D


var player_scene: PackedScene = preload("res://client/player/player.tscn")

@onready var loading_screen: CanvasLayer = $LoadingScreen
@onready var hud: CanvasLayer = $HUD


func _enter_tree() -> void:
	Game.instance = self
	TickEngine.start_ticking()
	$MultiplayerSpawner.spawn_function = player_spawn_function
	set_multiplayer_authority(multiplayer.get_unique_id())


func _ready() -> void:
	print("Game ready.")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var spawn_viewer = VoxelViewer.new()
	spawn_viewer.set_network_peer_id(multiplayer.get_unique_id())
	spawn_viewer.requires_data_block_notifications = true
	spawn_viewer.view_distance = 512
	spawn_viewer.requires_collisions = true
	spawn_viewer.requires_visuals = true
	add_child(spawn_viewer)
	await Game.terrain.meshed
	remove_child(spawn_viewer)
	Game.player = player_scene.instantiate()
	$MultiplayerSpawner.spawn(Game.player)
	SaveEngine.load_game(true)
	if SaveEngine.is_new_save or not Game.player.player_name in SaveEngine.save_data:
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


func player_spawn_function(data: Player) -> Node:
	data.set_multiplayer_authority(multiplayer.get_unique_id())
	return data
