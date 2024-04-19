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


func _process(_delta: float) -> void:
	_update_camera_raycast_result()


func _update_camera_raycast_result() -> void:
	if not player:
		return
	camera_raycast_result = player.camera.get_looking_raycast_result()

func do_tween(object: Object, property: String, new_value: Variant, duration: float, tween: Tween) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(object, property, new_value, duration)
