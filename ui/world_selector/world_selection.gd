class_name WorldSelection
extends MarginContainer


signal double_clicked(world_selection: WorldSelection)

var world_seed: int = 1004
var save_name: String = "world"
var button_group: ButtonGroup


func _ready() -> void:
	$Button.button_group = button_group
	$Button.text = save_name


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		double_clicked.emit(self)
