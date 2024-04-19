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
	stream = VoxelStreamSQLite.new()
	stream.database_path = "./saves/%s/terrain.sql" % save_name
	generator.noise.seed = world_seed


func _ready() -> void:
	# find a better way to wait for load
	await get_tree().create_timer(1).timeout
	var voxel_raycast_result: VoxelRaycastResult = Game.voxel_tool.raycast(bounds.size * Vector3.UP, Vector3.DOWN, bounds.size.y)
	if voxel_raycast_result:
		loaded = true
		highest_voxel_position = voxel_raycast_result.position
		meshed.emit()


func _process(_delta: float) -> void:
	if save_completion_tracker:
		if save_completion_tracker.is_complete():
			print("Terrain saved.")
			save_success.emit()
			save_completion_tracker = null
	
	if loaded:
		return
	# SLOW AND NOT RELIABLE
#	if is_area_meshed(AABB(Vector3.ZERO, Vector3.ONE)):
#		loaded = true
#		meshed.emit()

	# TODO: this is fast, but not reliable. maybe find a way to keep it fast?
#	if requested:
#		if get_statistics().time_request_blocks_to_load == 0:
#			loaded = true
#			meshed.emit()
#	if get_statistics().time_request_blocks_to_load > 0:
#		requested = true


func save() -> void:
	save_completion_tracker = save_modified_blocks()
