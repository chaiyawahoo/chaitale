extends Node


var world_selector_scene: PackedScene = preload("res://scenes/ui/world_selector.tscn")
var settings_scene: PackedScene = preload("res://scenes/ui/settings_menu.tscn")

@onready var main_menu: CanvasLayer = $MainMenu
@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var loading_screen: CanvasLayer = $LoadingScreen