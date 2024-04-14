extends CanvasLayer


func _ready() -> void:
	if not Game.pause_menu:
		Game.pause_menu = self
