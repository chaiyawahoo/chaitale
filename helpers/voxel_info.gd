class_name VoxelInfo
extends RefCounted


var position: Vector3i
var type: int


func _init(voxel_position: Vector3i = Vector3i.ZERO, voxel_type: int = 0) -> void:
	position = voxel_position
	type = voxel_type


static func from_position(voxel_position: Vector3i = Vector3i.ZERO) -> VoxelInfo:
	var voxel_info: VoxelInfo = VoxelInfo.new()
	voxel_info.position = voxel_position
	if Game.voxel_tool:
		voxel_info.type = Game.voxel_tool.get_voxel(voxel_position)
	return voxel_info


static func from_raycast(raycast_result: VoxelRaycastResult) -> VoxelInfo:
	var voxel_info: VoxelInfo = VoxelInfo.new()
	if raycast_result:
		voxel_info.position = raycast_result.position
	if Game.voxel_tool:
		voxel_info.type = Game.voxel_tool.get_voxel(voxel_info.position)
	return voxel_info
