class_name Level
extends Node3D


var player_scene: PackedScene = preload("res://client/player/player.tscn")
var terrain_scene: PackedScene = preload("res://world/terrain/voxel_terrain.tscn")


func _enter_tree() -> void:
	TickEngine.start_ticking()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Multiplayer.player_disconnected.connect(despawn)


func _ready() -> void:
	$PlayerSpawner.spawn_function = _spawn
	print("Game ready.")
	UI.loading_screen.visible = true
	UI.main_menu.visible = false
	spawn_on_server.rpc()
	while not Game.player:
		await TickEngine.ticked
	if multiplayer.is_server():
		SaveEngine.load_game(true)
		if SaveEngine.is_new_save or not Game.player.player_name in SaveEngine.save_data:
			SaveEngine.save_game()
		SaveEngine.load_game()


func _exit_tree() -> void:
	TickEngine.stop_ticking()


@rpc("any_peer", "call_local", "reliable")
func spawn_on_server():
	if not multiplayer.is_server():
		return
	$PlayerSpawner.spawn(multiplayer.get_remote_sender_id())


func _spawn(peer_id: int) -> Player:
	var new_player = player_scene.instantiate()
	new_player.name = str(peer_id)
	new_player.set_multiplayer_authority(peer_id)
	new_player.position = Vector3(0.5, 128, 0.5)
	new_player.add_to_group("players")
	return new_player


func despawn(peer_id: int) -> void:
	get_node(str(peer_id)).queue_free()
