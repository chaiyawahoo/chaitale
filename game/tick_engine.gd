extends Node


signal ticked

var ticks_elapsed: int = 0
var seconds_per_tick: float = 0.05 # 20 ticks per second
var tick_timer: float = 0


func _process(delta: float) -> void:
	tick_timer += delta
	if tick_timer >= seconds_per_tick:
		tick_timer -= seconds_per_tick
		ticks_elapsed += 1
		ticked.emit()
