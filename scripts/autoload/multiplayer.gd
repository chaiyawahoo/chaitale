extends Node


signal player_connected(peer_id: int, player_info: String)
signal player_disconnected(peer_id: int)
signal server_disconnected
signal connection_refused

const PORT: int = 1004
const MAX_PLAYERS: int = 8
const DEFAULT_SERVER_ADDRESS: String = "127.0.0.1"

var player_info: Dictionary = {name = ""}
var players: Dictionary = {} # id: player_info


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func create_server(is_offline: bool = true) -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(PORT, MAX_PLAYERS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	register_player(1, player_info)
	multiplayer.refuse_new_connections = is_offline
	return OK


func join_server(ip: String = "") -> Error:
	ip = DEFAULT_SERVER_ADDRESS if ip == "" else ip
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(ip, PORT)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	return OK


func end_multiplayer_session() -> void:
	multiplayer.multiplayer_peer = null


@rpc("any_peer", "reliable")
func register_player(peer_id: int, info: Dictionary) -> void: 
	players[peer_id] = info
	player_connected.emit(peer_id, info)


func _on_player_connected(peer_id: int) -> void:
	# if multiplayer.is_server():
	# 	return
	register_player.rpc_id(peer_id, multiplayer.get_unique_id(), player_info)


func _on_player_disconnected(peer_id: int) -> void:
	player_disconnected.emit(peer_id)
	SaveEngine.save_game()
	players.erase(peer_id)


func _on_connected_ok() -> void:
	register_player(multiplayer.get_unique_id(), player_info)


func _on_connected_fail() -> void:
	Main.close_level()


func _on_server_disconnected() -> void:
	Main.close_level()
	server_disconnected.emit()
