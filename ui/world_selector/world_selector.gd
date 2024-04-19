extends Control


var game_scene: PackedScene = preload("res://game/game.tscn")
var world_selection_scene: PackedScene = preload("res://ui/world_selector/world_selection.tscn")
var world_button_group: ButtonGroup = ButtonGroup.new()


func _enter_tree() -> void:
	var directory_access: DirAccess = DirAccess.open("./")
	if not directory_access.dir_exists("saves/"):
		directory_access.make_dir("saves/")
	var saves_directory_access: DirAccess = DirAccess.open("./saves")
	saves_directory_access.list_dir_begin()
	var file_name: String = saves_directory_access.get_next()
	while file_name != "":
		if saves_directory_access.current_is_dir():
			instanitate_world_in_list(file_name)
		file_name = saves_directory_access.get_next()
	saves_directory_access.list_dir_end()


func _ready() -> void:
	%CreateButton.pressed.connect(_on_button_create)
	%LoadButton.pressed.connect(_on_button_load)
	%BackButton.pressed.connect(_on_button_back)
	for world in %WorldsContainer.get_children():
		if not world is WorldSelection:
			continue
		world.double_clicked.connect(load_specific_world)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back()
		get_viewport().set_input_as_handled()


func _on_button_back() -> void:
	back()


func _on_button_create() -> void:
	create_world()


func _on_button_load() -> void:
	load_world()


func instanitate_world_in_list(directory_name: String) -> void:
	var world_selection: WorldSelection = world_selection_scene.instantiate()
	world_selection.name = directory_name
	world_selection.save_name = directory_name
	if not FileAccess.file_exists("./saves/%s/terrain.sql" % directory_name):
		return
	if FileAccess.file_exists("./saves/%s/seed.txt" % directory_name):
		var seed_file: FileAccess = FileAccess.open("./saves/%s/seed.txt" % directory_name, FileAccess.READ)
		world_selection.world_seed = int(str_to_var(seed_file.get_as_text()))
	else:
		return
	world_selection.button_group = world_button_group
	%WorldsContainer.add_child(world_selection)


# TODO: switch to new scene to allow user input
func create_world() -> void:
	var random_seed: int = randi()
	var directory_access: DirAccess = DirAccess.open("./saves")
	if directory_access.dir_exists("%d" % random_seed): # INFINITELY RARE
		create_world()
		return
	directory_access.make_dir("%d" % random_seed)
	var seed_file: FileAccess = FileAccess.open("./saves/%d/seed.txt" % random_seed, FileAccess.WRITE)
	seed_file.store_string("%d" % random_seed)
	Game.save_name = "%d" % random_seed
	Game.world_seed = random_seed
	get_tree().change_scene_to_packed(game_scene)


func load_world() -> void:
	load_specific_world(world_button_group.get_pressed_button().get_parent())


func load_specific_world(world_selection: WorldSelection) -> void:
	Game.save_name = world_selection.save_name
	Game.world_seed = world_selection.world_seed
	get_tree().change_scene_to_packed(game_scene)


func back() -> void:
	queue_free()