class_name WorldSelection
extends MarginContainer


var world_seed: int = 1004
var save_name: String = "world"
var button_group: ButtonGroup


func _ready() -> void:
	$Button.button_group = button_group
	$Button.text = save_name
