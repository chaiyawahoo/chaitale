extends Node


signal save_success

var autosave_tick_interval: int = 1200 # one minute

var terrain_save_completion_tracker: VoxelSaveCompletionTracker
var terrain_save_format: String = "./saves/%s/terrain.sql"

var save_format: String = "./saves/%s/save.dat"
var is_new_save: bool = false
var save_data: Dictionary = {
	player = {
		position = Vector3.ZERO,
		horizontal_look = 0.0,
		vertical_look = 0.0,
		external_velocity = Vector3.ZERO
	}
}


func _enter_tree() -> void:
	TickEngine.ticked.connect(_on_tick)


func _process(_delta):
	track_terrain_save()


func _on_tick() -> void:
	autosave()


func autosave() -> void:
	if TickEngine.ticks_elapsed % autosave_tick_interval:
		return
	if not Game.terrain:
		return
	print("Autosaving...")
	save_game()


func save_game() -> void:
	update_before_save()

	var save_file: FileAccess = FileAccess.open(save_format % Game.save_name, FileAccess.WRITE)
	var save_string: String = JSON.stringify(save_data)
	save_file.store_string(save_string)


func load_game() -> void:
	is_new_save = false
	if not FileAccess.file_exists(save_format % Game.save_name):
		return
	
	var save_file: FileAccess = FileAccess.open(save_format % Game.save_name, FileAccess.READ)
	var save_json: JSON = JSON.new()
	var parse_error: Error = save_json.parse(save_file.get_as_text())
	if parse_error != OK:
		return
	save_data = save_json.get_data()

	update_after_load()


func load_terrain_stream() -> void:
	if not Game.terrain:
		return
	Game.terrain.stream = VoxelStreamSQLite.new()
	Game.terrain.stream.database_path = terrain_save_format % Game.save_name
	Game.terrain.generator.noise.seed = Game.world_seed


func track_terrain_save() -> void:
	if not terrain_save_completion_tracker:
		return
	if terrain_save_completion_tracker.is_complete():
		print("Terrain saved.")
		save_success.emit()
		terrain_save_completion_tracker = null


func update_before_save() -> void:
	save_data.player.position = Game.player.global_position
	save_data.player.horizontal_look = Game.player.camera.horizontal_look
	save_data.player.vertical_look = Game.player.camera.vertical_look
	save_data.player.external_velocity = Game.player.external_velocity
	terrain_save_completion_tracker = Game.terrain.save_modified_blocks()


func update_after_load() -> void:
	Game.player.global_position = str_to_var("Vector3%s" % save_data.player.position)
	Game.player.camera.horizontal_look = float(save_data.player.horizontal_look)
	Game.player.camera.vertical_look = float(save_data.player.vertical_look)
	Game.player.external_velocity = str_to_var("Vector3%s" % save_data.player.external_velocity)
