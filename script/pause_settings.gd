extends CanvasLayer

@onready var overlay: Control = $Overlay
@onready var pause_panel: VBoxContainer = $Overlay/Center/Card/Margin/PausePanel
@onready var settings_panel: VBoxContainer = $Overlay/Center/Card/Margin/SettingsPanel
@onready var brightness_slider: HSlider = $Overlay/Center/Card/Margin/SettingsPanel/BrightnessSlider
@onready var music_slider: HSlider = $Overlay/Center/Card/Margin/SettingsPanel/MusicSlider
@onready var sfx_slider: HSlider = $Overlay/Center/Card/Margin/SettingsPanel/SfxSlider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	brightness_slider.value_changed.connect(_on_brightness_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	$Overlay/Center/Card/Margin/PausePanel/Resume.pressed.connect(close)
	$Overlay/Center/Card/Margin/PausePanel/Settings.pressed.connect(_show_settings)
	$Overlay/Center/Card/Margin/PausePanel/Quit.pressed.connect(_quit_game)
	$Overlay/Center/Card/Margin/SettingsPanel/Back.pressed.connect(_show_pause_menu)
	for button: TextureButton in [$Overlay/Center/Card/Margin/PausePanel/Resume, $Overlay/Center/Card/Margin/PausePanel/Settings, $Overlay/Center/Card/Margin/PausePanel/Quit]:
		button.mouse_entered.connect(_animate_button.bind(button, true))
		button.mouse_exited.connect(_animate_button.bind(button, false))
		button.focus_entered.connect(_animate_button.bind(button, true))
		button.focus_exited.connect(_animate_button.bind(button, false))
	get_tree().scene_changed.connect(_on_scene_changed)


func _animate_button(button: TextureButton, highlighted: bool) -> void:
	button.pivot_offset = button.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.04, 1.04) if highlighted else Vector2.ONE, 0.1)
	tween.tween_property(button, "modulate", Color(1.12, 1.08, 0.9, 1.0) if highlighted else Color.WHITE, 0.1)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if overlay.visible:
		if settings_panel.visible:
			_show_pause_menu()
		else:
			close()
	elif _is_gameplay_scene():
		open()
	get_viewport().set_input_as_handled()


func _is_gameplay_scene() -> bool:
	var scene := get_tree().current_scene
	if scene == null or not SaveManager.game_active:
		return false
	var path := scene.scene_file_path
	return path != "res://scenes/main_menu.tscn" and path != "res://scenes/opening_story.tscn"


func open() -> void:
	overlay.visible = true
	get_tree().paused = true
	_show_pause_menu()


func close() -> void:
	overlay.visible = false
	get_tree().paused = false


func _show_pause_menu() -> void:
	pause_panel.visible = true
	settings_panel.visible = false
	$Overlay/Center/Card/Margin/PausePanel/Resume.grab_focus()


func _show_settings() -> void:
	brightness_slider.set_value_no_signal(SettingsManager.brightness * 100.0)
	music_slider.set_value_no_signal(SettingsManager.music_volume * 100.0)
	sfx_slider.set_value_no_signal(SettingsManager.sfx_volume * 100.0)
	pause_panel.visible = false
	settings_panel.visible = true
	brightness_slider.grab_focus()


func _quit_game() -> void:
	SaveManager.save_game()
	SaveManager.game_active = false
	overlay.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_scene_changed() -> void:
	if overlay.visible and not _is_gameplay_scene():
		close()


func _on_brightness_changed(value: float) -> void:
	SettingsManager.set_brightness(value / 100.0)


func _on_music_changed(value: float) -> void:
	SettingsManager.set_music_volume(value / 100.0)


func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value / 100.0)
