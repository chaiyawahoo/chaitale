extends Node


signal ticked

var ticks_elapsed: int = 0
var seconds_per_tick: float = 0.05 # 20 ticks per second
var tick_timer: float = 0
var ticking = false


func _process(delta: float) -> void:
	if ticking:
		tick(delta)


func start_ticking() ->  void:
	ticks_elapsed = 0
	tick_timer = 0
	ticking = true


func stop_ticking() -> void:
	ticks_elapsed = 0
	tick_timer = 0
	ticking = false


func tick(delta: float) -> void:
	tick_timer += delta
	if tick_timer >= seconds_per_tick:
		tick_timer -= seconds_per_tick
		ticks_elapsed += 1
		ticked.emit()
