extends Control


func _enter_tree() -> void:
    %BackButton.pressed.connect(_on_button_back)
    %ApplyButton.pressed.connect(_on_button_apply)


func _ready() -> void:
    var window_mode: int
    match Settings.window_mode:
        3: window_mode = 1
        4: window_mode = 2
        _: window_mode = 0
    %WindowMode.select(window_mode)


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        back()
        get_viewport().set_input_as_handled()


func _on_button_back() -> void:
    back()


func _on_button_apply() -> void:
    apply_changes()


func back() -> void:
    queue_free()


func apply_changes() -> void:
    Settings.window_mode = %WindowMode.get_selected_id()
    Settings.update_settings()