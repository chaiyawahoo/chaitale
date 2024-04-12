extends CanvasLayer


@onready var pointer: TextureRect = $Pointer
@onready var fps_label: Label = $FPS

func _process(delta: float) -> void:
	fps_label.text = str(Engine.get_frames_per_second())
	pointer.visible = not Game.menu_opened
