extends Node


func _ready() -> void:
	pass


func create_game() -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(1004, 8)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	return OK
