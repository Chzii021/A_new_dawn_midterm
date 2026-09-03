extends Control

@onready var main_panel: VBoxContainer = %MainPanel
@onready var play_panel: VBoxContainer = %PlayPanel
@onready var settings_panel: VBoxContainer = %SettingsPanel
@onready var credits_panel: VBoxContainer = %CreditsPanel
@onready var load_button: BaseButton = %LoadButton
@onready var status_label: Label = %StatusLabel
@onready var title_logo: TextureRect = $TitleLogo
@onready var settings_backdrop: Panel = %SettingsBackdrop

var _water_playback: AudioStreamGeneratorPlayback
var _water_low_pass := 0.0
var _water_phase := 0.0
var _water_rng := RandomNumberGenerator.new()
var _music_fading_out := false
const MUSIC_LEVEL_DB := -18.0
const MUSIC_SILENT_DB := -45.0


func _ready() -> void:
	$MenuMusic.bus = &"Music"
	$Breeze.bus = &"SFX"
	$WaterStream.bus = &"SFX"
	resized.connect(_apply_responsive_typography)
	_apply_responsive_typography()
	%BrightnessSlider.value = SettingsManager.brightness * 100.0
	%MusicSlider.value = SettingsManager.music_volume * 100.0
	%SfxSlider.value = SettingsManager.sfx_volume * 100.0
	_update_value_labels()
	load_button.disabled = not SaveManager.has_save()
	load_button.tooltip_text = ""
	_show_panel(main_panel)
	%PlayButton.grab_focus()
	_setup_image_buttons()
	$MenuMusic.finished.connect(_restart_music)
	$Breeze.finished.connect(_restart_audio.bind($Breeze))
	_fade_music_in()
	_water_rng.randomize()
	_water_playback = $WaterStream.get_stream_playback() as AudioStreamGeneratorPlayback


func _process(_delta: float) -> void:
	_fill_water_buffer()
	_update_music_fade()


func _restart_audio(player: AudioStreamPlayer) -> void:
	player.play()


func _restart_music() -> void:
	$MenuMusic.play()
	_music_fading_out = false
	_fade_music_in()


func _fade_music_in() -> void:
	$MenuMusic.volume_db = MUSIC_SILENT_DB
	create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).tween_property(
		$MenuMusic, "volume_db", MUSIC_LEVEL_DB, 3.5
	)


func _update_music_fade() -> void:
	if _music_fading_out or not $MenuMusic.playing or $MenuMusic.stream == null:
		return
	var remaining: float = float(
		$MenuMusic.stream.get_length() - $MenuMusic.get_playback_position()
	)
	if remaining <= 4.0:
		_music_fading_out = true
		create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).tween_property(
			$MenuMusic, "volume_db", MUSIC_SILENT_DB, maxf(remaining, 0.25)
		)


func _fill_water_buffer() -> void:
	if not _water_playback:
		return
	var frames := _water_playback.get_frames_available()
	for i in frames:
		var noise := _water_rng.randf_range(-1.0, 1.0)
		_water_low_pass = lerpf(_water_low_pass, noise, 0.07)
		_water_phase += 0.006 + noise * 0.0003
		var ripple := sin(_water_phase) * sin(_water_phase * 0.31) * 0.008
		var flowing_water := _water_low_pass * 0.035 + ripple
		_water_playback.push_frame(Vector2(flowing_water * 0.92, flowing_water))


func _apply_responsive_typography() -> void:
	# Font sizes are based on the logical viewport height. Godot then applies the
	# project's pixel scale, keeping the same proportions in embedded/external play.
	var viewport_height := maxf(size.y, 216.0)
	_resize_particles()
	_resize_image_buttons(viewport_height)
	_set_font_size($TitleBlock/Title, viewport_height * 0.065, 12, 38)
	_set_font_size($TitleBlock/Subtitle, viewport_height * 0.018, 5, 11)
	for heading in [
		$Center/MenuCard/Panels/MainPanel/Heading,
		$Center/MenuCard/Panels/PlayPanel/Heading,
		$Center/MenuCard/Panels/SettingsPanel/Heading,
		$Center/MenuCard/Panels/CreditsPanel/Heading
	]:
		_set_font_size(heading, viewport_height * 0.035, 7, 21)
	for button in find_children("*", "Button", true, false):
		_set_font_size(button, viewport_height * 0.027, 6, 17)
	_set_font_size($Center/MenuCard/Panels/PlayPanel/Hint, viewport_height * 0.017, 5, 10)
	_set_font_size($Center/MenuCard/Panels/CreditsPanel/Game, viewport_height * 0.028, 6, 17)
	_set_font_size($Center/MenuCard/Panels/CreditsPanel/Creators, viewport_height * 0.019, 5, 11)


func _set_font_size(control: Control, requested: float, minimum: int, maximum: int) -> void:
	control.add_theme_font_size_override("font_size", clampi(roundi(requested), minimum, maximum))


func _resize_image_buttons(viewport_height: float) -> void:
	# The control itself uses the same wide aspect as the artwork, so the visible
	# plate and clickable area are identical instead of having an invisible row.
	var row_height := clampf(viewport_height * 0.09, 32.0, 44.0)
	var row_width := row_height * 3.85
	for button in find_children("*", "TextureButton", true, false):
		if button.name.ends_with("Minus") or button.name.ends_with("Plus"):
			button.custom_minimum_size = Vector2(20.0, 20.0)
			button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			continue
		button.custom_minimum_size = Vector2(row_width, row_height)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _setup_image_buttons() -> void:
	for button in find_children("*", "TextureButton", true, false):
		button.pivot_offset = button.size * 0.5
		button.mouse_entered.connect(_highlight_image_button.bind(button, true))
		button.mouse_exited.connect(_highlight_image_button.bind(button, false))
		button.focus_entered.connect(_highlight_image_button.bind(button, true))
		button.focus_exited.connect(_highlight_image_button.bind(button, false))


func _highlight_image_button(button: BaseButton, highlighted: bool) -> void:
	if button.disabled:
		return
	button.pivot_offset = button.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.035, 1.035) if highlighted else Vector2.ONE, 0.1)
	tween.tween_property(button, "modulate", Color(1.12, 1.08, 0.9, 1.0) if highlighted else Color.WHITE, 0.1)


func _resize_particles() -> void:
	var particles: GPUParticles2D = $AmbientParticles
	particles.position = size * 0.5
	particles.visibility_rect = Rect2(-size * 0.5, size)
	var particle_material := particles.process_material as ParticleProcessMaterial
	if particle_material:
		particle_material.emission_box_extents = Vector3(size.x * 0.5, size.y * 0.5, 1.0)


func _show_panel(panel: Control) -> void:
	for candidate in [main_panel, play_panel, settings_panel, credits_panel]:
		candidate.visible = candidate == panel
	# The Settings screen has its own heading artwork, so do not stack it over
	# the game's title logo.
	title_logo.visible = panel != settings_panel
	settings_backdrop.visible = panel == settings_panel
	_set_menu_card_layout(panel == settings_panel)
	status_label.text = ""
	var first_button := panel.find_children("*", "BaseButton", true, false)
	if not first_button.is_empty():
		first_button[0].grab_focus()


func _set_menu_card_layout(for_settings: bool) -> void:
	var card: PanelContainer = %MenuCard
	if for_settings:
		card.anchor_left = 0.28
		card.anchor_top = 0.10
		card.anchor_right = 0.72
		card.anchor_bottom = 0.93
		card.offset_left = 0.0
		card.offset_top = 0.0
		card.offset_right = 0.0
		card.offset_bottom = 0.0
	else:
		card.anchor_left = 0.16
		card.anchor_top = 0.31
		card.anchor_right = 0.84
		card.anchor_bottom = 0.94
		card.offset_left = 101.52002
		card.offset_top = 0.0
		card.offset_right = -97.52002
		card.offset_bottom = 0.0


func _on_play_pressed() -> void:
	_show_panel(play_panel)


func _on_new_game_pressed() -> void:
	SaveManager.start_new_game()


func _on_load_game_pressed() -> void:
	if not SaveManager.load_game():
		status_label.text = "The save file could not be loaded."


func _on_settings_pressed() -> void:
	_show_panel(settings_panel)


func _on_credits_pressed() -> void:
	_show_panel(credits_panel)


func _on_back_pressed() -> void:
	_show_panel(main_panel)


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_brightness_changed(value: float) -> void:
	SettingsManager.set_brightness(value / 100.0)
	_update_value_labels()


func _on_music_changed(value: float) -> void:
	SettingsManager.set_music_volume(value / 100.0)
	_update_value_labels()


func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value / 100.0)
	_update_value_labels()


func _update_value_labels() -> void:
	%BrightnessValue.text = "%d%%" % int(%BrightnessSlider.value)
	%MusicValue.text = "%d%%" % int(%MusicSlider.value)
	%SfxValue.text = "%d%%" % int(%SfxSlider.value)
