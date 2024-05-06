extends CanvasLayer


var current_hotbar_index: int = 0

@onready var pointer: TextureRect = %Pointer
@onready var fps_label: Label = %FPS
@onready var position_label: Label = %PositionLabel
@onready var hotbar: HBoxContainer = %Hotbar
@onready var hotbar_slots: Array[Node] = hotbar.get_children()


func _enter_tree() -> void:
	SaveEngine.loaded.connect(_on_save_loaded)


func _ready() -> void:
	select_item(current_hotbar_index)


func _process(_delta: float) -> void:
	if not $Debug.visible:
		return
	fps_label.text = str(Engine.get_frames_per_second())
	pointer.visible = not Game.is_paused
	if not Game.player:
		return
	var position_string_format: String = "x: %.3f y: %.3f z: %.3f"
	position_label.text = position_string_format % [Game.player.position.x, Game.player.position.y - Game.player.player_area.size.y / 2, Game.player.position.z]


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		$Debug.visible = not $Debug.visible
		return
	if event.is_action_pressed("toggle_ui"):
		visible = not visible
		return
	if event is InputEventMouseButton:
		if event.is_pressed():
			var up_function: Callable = select_previous if not Settings.settings.controls.invert_scroll else select_next
			var down_function: Callable = select_next if not Settings.settings.controls.invert_scroll else select_previous
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				up_function.call()
				return
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				down_function.call()
				return
	# for loop do last ?
	for i in range(9):
		if event.is_action_pressed("select_%s" % (i+1)):
			select_item(i)
			return


func _on_save_loaded() -> void:
	load_save()


func select_item(index: int) -> void:
	current_hotbar_index = posmod(index, 9)
	for i in range(9):
		if i == current_hotbar_index:
			hotbar_slots[i].theme_type_variation = "HotbarSelected"
			continue
		hotbar_slots[i].theme_type_variation = "HotbarSlot"
	if not Game.player:
		return
	VoxelEditor.current_voxel_id = current_hotbar_index + 1


func select_previous() -> void:
	select_item(current_hotbar_index - 1)


func select_next() -> void:
	select_item(current_hotbar_index + 1)


func load_save() -> void:
	if not "hud" in SaveEngine.save_data:
		return
	var save_data: Dictionary = SaveEngine.save_data.hud
	current_hotbar_index = save_data.hotbar_index
	select_item(current_hotbar_index)


func send_save_data() -> void:
	var save_data: Dictionary = {
		hotbar_index = current_hotbar_index
	}
	SaveEngine.save_data.hud = save_data
