extends VoxelTerrain


signal meshed
signal save_success

var loaded: bool = false
var requested: bool = false

var save_name: String = "world"
var directory_access: DirAccess = DirAccess.open("./")
var save_completion_tracker: VoxelSaveCompletionTracker

func _ready() -> void:
	stream = VoxelStreamSQLite.new()
	if not directory_access.dir_exists("saves/"):
		directory_access.make_dir("saves/")
	if FileAccess.file_exists("saves/%s.sql" % save_name):
		print("loading %s" % save_name)
	stream.database_path = "saves/%s.sql" % save_name
	if not Game.terrain:
		Game.terrain = self
	if not Game.voxel_tool:
		Game.voxel_tool = get_voxel_tool()


func _process(_delta: float) -> void:
	if save_completion_tracker:
		if save_completion_tracker.is_complete():
			print("Terrain saved.")
			save_success.emit()
			save_completion_tracker = null
	
	if loaded:
		return
	# SLOW
#	print(is_area_meshed(AABB(Vector3.ZERO, Vector3.ONE)))
	# TODO: this is hacky, find a better method to detect loaded
	if requested:
		if get_statistics().time_request_blocks_to_load == 0:
			loaded = true
			meshed.emit()
	if get_statistics().time_request_blocks_to_load > 0:
		requested = true


func save() -> void:
	save_completion_tracker = save_modified_blocks()