class_name Main
extends Node


const packed_level: PackedScene = preload("res://game/level.tscn")

static var _instance: Main

@onready var level_parent: Node = $LevelParent
@onready var level_spawner: MultiplayerSpawner = $LevelSpawner


func _enter_tree() -> void:
	_instance = self
	Game.main = self


static func change_level() -> void:
	_instance._change_level.call_deferred(packed_level)


static func close_level() -> void:
	_instance._close_level.call_deferred()


func _change_level(scene: PackedScene) -> void:
	_remove_level()
	var level: Node = scene.instantiate()
	level.name = "Level"
	level_parent.add_child(level)
	UI.main_menu.visible = false


func _close_level() -> void:
	_remove_level()
	Multiplayer.end_multiplayer_session()
	UI.main_menu.visible = true
	UI.hud.visible = false
	UI.pause_menu.visible = false
	UI.loading_screen.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _remove_level() -> void:
	for node in level_parent.get_children():
		level_parent.remove_child(node)
		node.queue_free()
