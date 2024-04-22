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

var is_server: bool = false


func _ready() -> void:
	pass


func create_server() -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(PORT, MAX_PLAYERS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	is_server = true
	return OK


func join_server() -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(DEFAULT_SERVER_ADDRESS, PORT)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	return OK


func end_multiplayer_session() -> void:
	multiplayer.multiplayer_peer = null


@rpc("any_peer", "reliable")
func register_player(peer_id: int, info: Dictionary):
	players[peer_id] = info
	player_connected.emit(peer_id, info)



func _on_player_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		return
	register_player.rpc_id(peer_id, multiplayer.get_unique_id(), player_info)


func _on_player_disconnected(peer_id: int) -> void:
	players.erase(peer_id)
	player_disconnected.emit(peer_id)


func _on_connected_ok() -> void:
	register_player(multiplayer.get_unique_id(), player_info)


func _on_connected_fail() -> void:
	end_multiplayer_session()


func _on_server_disconnected() -> void:
	end_multiplayer_session()
	server_disconnected.emit()
