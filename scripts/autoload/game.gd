extends Node


var save_name: String
var world_seed: int
var terrain: VoxelTerrain
var voxel_tool: VoxelTool
var voxel_types: int
var player: Player
var hover_cube: MeshInstance3D
var pause_menu: CanvasLayer
var camera_raycast_result: VoxelRaycastResult

var is_paused: bool = false:
	get:
		if UI.pause_menu:
			return UI.pause_menu.visible
		return false
var is_server: bool = false


func _process(_delta: float) -> void:
	_update_camera_raycast_result()


func _update_camera_raycast_result() -> void:
	if not player or not player.is_inside_tree():
		return
	camera_raycast_result = player.get_looking_raycast_result()


func do_tween(object: Object, property: String, new_value: Variant, duration: float, tween: Tween) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(object, property, new_value, duration)
