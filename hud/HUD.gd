extends CanvasLayer


@onready var pointer: TextureRect = %Pointer
@onready var fps_label: Label = %FPS
@onready var position_label: Label = %PositionLabel


func _process(delta: float) -> void:
	fps_label.text = str(Engine.get_frames_per_second())
	pointer.visible = not Game.menu_opened
	if not Game.player:
		return
	var position_string_format: String = "x: %.3f y: %.3f z: %.3f"
	position_label.text = position_string_format % [Game.player.position.x, Game.player.position.y, Game.player.position.z]
