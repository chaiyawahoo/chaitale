class_name GameInstance
extends Node3D


var player_scene: PackedScene = preload("res://client/player/player.tscn")

@onready var loading_screen: CanvasLayer = $LoadingScreen
@onready var hud: CanvasLayer = $HUD


func _enter_tree() -> void:
	Game.instance = self
	TickEngine.start_ticking()
	$MultiplayerSpawner.spawn_function = _spawn_function


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
	$MultiplayerSpawner.spawn(multiplayer.get_unique_id())
	SaveEngine.load_game(true)
	if SaveEngine.is_new_save or not Game.player.player_name in SaveEngine.save_data:
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


func _spawn_function(player_id: int) -> Node:
	var new_player = player_scene.instantiate()
	if player_id == 1:
		Game.player = new_player
	new_player.set_multiplayer_authority(player_id)
	return new_player
