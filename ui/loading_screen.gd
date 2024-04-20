extends CanvasLayer


func _ready() -> void:
    await Game.terrain.meshed
    visible = false