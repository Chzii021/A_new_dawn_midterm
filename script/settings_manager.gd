extends Node

const SETTINGS_PATH := "user://settings.cfg"

var brightness := 1.0
var music_volume := 0.8
var sfx_volume := 0.8
var _brightness_overlay: ColorRect


func _ready() -> void:
	_ensure_audio_buses()
	_load_settings()
	_create_brightness_overlay()
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_assign_existing_audio")


func set_brightness(value: float) -> void:
	brightness = clampf(value, 0.01, 1.0)
	if is_instance_valid(_brightness_overlay):
		_brightness_overlay.color = Color(0.0, 0.0, 0.0, (1.0 - brightness) * 0.7)
	_save_settings()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_set_bus_volume("Music", music_volume)
	_save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_set_bus_volume("SFX", sfx_volume)
	_save_settings()


func _ensure_audio_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, linear_value <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear_value, 0.001)))


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		brightness = float(config.get_value("display", "brightness", brightness))
		music_volume = float(config.get_value("audio", "music", music_volume))
		sfx_volume = float(config.get_value("audio", "sfx", sfx_volume))
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "brightness", brightness)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.save(SETTINGS_PATH)


func _create_brightness_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1000
	layer.name = "BrightnessOverlay"
	_brightness_overlay = ColorRect.new()
	_brightness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_brightness_overlay)
	add_child(layer)
	_brightness_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_brightness(brightness)


func _on_node_added(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		_assign_audio_bus(node)


func _assign_existing_audio() -> void:
	_assign_audio_recursive(get_tree().root)


func _assign_audio_recursive(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		_assign_audio_bus(node)
	for child in node.get_children():
		_assign_audio_recursive(child)


func _assign_audio_bus(player: Node) -> void:
	var parent_name := player.get_parent().name.to_lower() if player.get_parent() else ""
	var player_name := player.name.to_lower()
	var is_background_music: bool = bool(
		player.bus == &"Music"
		or player_name == "menumusic"
		or (player_name == "audio" and parent_name in ["world", "village"])
	)
	player.bus = &"Music" if is_background_music else &"SFX"
