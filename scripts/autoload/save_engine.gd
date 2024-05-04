extends Node


signal save_success
signal loaded
signal server_data_received


const PLAYER_SAVE_KEYS: Array[String] = ["position", "horizontal_look", "vertical_look", "external_velocity", "falling", "flying"]


var autosave_tick_interval: int = 1200 # one minute
var autosave_tick_counter: int = 0

var terrain_save_completion_tracker: VoxelSaveCompletionTracker
var terrain_save_format: String = "./saves/%s/terrain.sql"

var save_format: String = "./saves/%s/save.dat"
var is_new_save: bool = false
var save_data: Dictionary = {}


func _enter_tree() -> void:
	TickEngine.ticked.connect(_on_tick)


func _process(_delta):
	track_terrain_save()


func _on_tick() -> void:
	autosave_tick()


func autosave_tick() -> void:
	if not multiplayer.is_server():
		return
	if not Game.terrain:
		return
	if autosave_tick_counter < autosave_tick_interval:
		autosave_tick_counter += 1
		return
	autosave_tick_counter = 0
	print("Autosaving...")
	save_game()


func save_game() -> void:
	if multiplayer.multiplayer_peer:
		if not multiplayer.is_server():
			return

	update_before_save()

	terrain_save_completion_tracker = Game.terrain.save_modified_blocks()
	
	var save_file: FileAccess = FileAccess.open(save_format % Game.save_name, FileAccess.WRITE)
	save_file.store_var(save_data, true)


func load_game(silent: bool = false) -> void:
	if not multiplayer.is_server():
		return

	is_new_save = false
	if not FileAccess.file_exists(save_format % Game.save_name):
		return
	
	var save_file: FileAccess = FileAccess.open(save_format % Game.save_name, FileAccess.READ)
	save_data = save_file.get_var(true)

	if silent:
		return
	loaded.emit()


func purge_save_data() -> void:
	save_data = {}


func load_terrain_stream() -> void:
	if multiplayer.multiplayer_peer:
		if not multiplayer.is_server():
			return
	if not Game.terrain:
		return
	Game.terrain.stream = VoxelStreamSQLite.new()
	Game.terrain.stream.database_path = terrain_save_format % Game.save_name
	Game.terrain.generator.noise.seed = Game.world_seed


@rpc("any_peer", "reliable")
func request_server_save_data() -> void:
	if not multiplayer.is_server():
		return
	send_server_save_data.rpc_id(multiplayer.get_remote_sender_id(), save_data)


@rpc("authority", "call_local", "reliable")
func send_server_save_data(data: Dictionary) -> void:
	save_data = data
	server_data_received.emit()


func track_terrain_save() -> void:
	if multiplayer.multiplayer_peer:
		if not multiplayer.is_server():
			return
	if not terrain_save_completion_tracker:
		return
	if terrain_save_completion_tracker.is_complete():
		print("Terrain saved.")
		save_success.emit()
		terrain_save_completion_tracker = null


func update_before_save() -> void:
	if multiplayer.multiplayer_peer:
		if not multiplayer.is_server():
			return
	get_tree().call_group("players", "send_save_data")
	UI.hud.send_save_data()
