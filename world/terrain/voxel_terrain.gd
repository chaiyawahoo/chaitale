extends VoxelTerrain


signal meshed
signal save_success

var loaded: bool = false
var requested: bool = false
var highest_voxel_position: Vector3i = Vector3i.ZERO

var save_name: String = "world"
var world_seed: int = 1004
var directory_access: DirAccess = DirAccess.open("./")
var save_completion_tracker: VoxelSaveCompletionTracker


func _enter_tree() -> void:
	Game.terrain = self
	Game.voxel_tool = get_voxel_tool()
	Game.voxel_types = mesher.library.models.size() - 1
	if Game.world_seed:
		world_seed = Game.world_seed
	if Game.save_name:
		save_name = Game.save_name
	SaveEngine.load_terrain_stream()


func _ready() -> void:
	wait_for_mesh()


func wait_for_mesh() -> void:
	var voxel_raycast_result: VoxelRaycastResult = Game.voxel_tool.raycast(bounds.size * Vector3.UP, Vector3.DOWN, bounds.size.y)
	if voxel_raycast_result:
		loaded = true
		highest_voxel_position = voxel_raycast_result.position
		meshed.emit()
		return
	await TickEngine.ticked
	wait_for_mesh()