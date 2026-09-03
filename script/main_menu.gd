extends Control

@onready var main_panel: VBoxContainer = %MainPanel
@onready var play_panel: VBoxContainer = %PlayPanel
@onready var save_slots_panel: VBoxContainer = %SaveSlotsPanel
@onready var settings_panel: VBoxContainer = %SettingsPanel
@onready var credits_panel: VBoxContainer = %CreditsPanel
@onready var load_button: BaseButton = %LoadButton
@onready var status_label: Label = %StatusLabel
@onready var title_logo: TextureRect = $TitleLogo
@onready var settings_backdrop: Panel = %SettingsBackdrop
@onready var save_slots_board: TextureRect = %SaveSlotsBoard
@onready var save_slots_title: TextureRect = %SaveSlotsTitle
@onready var credits_board: TextureRect = %CreditsBoard
@onready var credits_back_button: TextureButton = %CreditsBackButton

var _water_playback: AudioStreamGeneratorPlayback
var _water_low_pass := 0.0
var _water_phase := 0.0
var _water_rng := RandomNumberGenerator.new()
var _music_fading_out := false
var _slot_mode_new_game := true
const MUSIC_LEVEL_DB := -18.0
const MUSIC_SILENT_DB := -45.0

var _save_slot_texture: Texture2D
var _new_slot_texture: Texture2D


func _ready() -> void:
	_save_slot_texture = load("res://art/slot_save_game.png") as Texture2D
	_new_slot_texture = load("res://art/slot_create_new.png") as Texture2D
	_prepare_credits_text()
	$MenuMusic.bus = &"Music"
	$Breeze.bus = &"SFX"
	$WaterStream.bus = &"SFX"
	resized.connect(_apply_responsive_typography)
	_apply_responsive_typography()
	%BrightnessSlider.value = SettingsManager.brightness * 100.0
	%MusicSlider.value = SettingsManager.music_volume * 100.0
	%SfxSlider.value = SettingsManager.sfx_volume * 100.0
	_update_value_labels()
	_update_continue_button()
	load_button.tooltip_text = ""
	_show_panel(main_panel)
	%PlayButton.grab_focus()
	_setup_image_buttons()
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		_get_slot_select(slot).pressed.connect(_on_slot_selected.bind(slot))
		_get_slot_delete(slot).pressed.connect(_on_slot_deleted.bind(slot))
	%Back.pressed.connect(_on_slot_back_pressed)
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
	_set_font_size($Center/MenuCard/Panels/CreditsPanel/Creators, viewport_height * 0.016, 6, 9)


func _prepare_credits_text() -> void:
	var member_lines: PackedStringArray = []
	for line: String in $Center/MenuCard/Panels/CreditsPanel/Creators.text.split("\n"):
		var cleaned: String = line.strip_edges()
		if cleaned.is_empty() or cleaned == "Created by Group 4" or cleaned == "Made with Godot Engine":
			continue
		member_lines.append(cleaned)
	$Center/MenuCard/Panels/CreditsPanel/Creators.text = "\n".join(member_lines)


func _set_font_size(control: Control, requested: float, minimum: int, maximum: int) -> void:
	control.add_theme_font_size_override("font_size", clampi(roundi(requested), minimum, maximum))


func _resize_image_buttons(viewport_height: float) -> void:
	# The control itself uses the same wide aspect as the artwork, so the visible
	# plate and clickable area are identical instead of having an invisible row.
	var row_height := clampf(viewport_height * 0.09, 32.0, 44.0)
	var row_width := row_height * 3.85
	for button in find_children("*", "TextureButton", true, false):
		if button == credits_back_button:
			button.custom_minimum_size = Vector2.ZERO
			continue
		if button.name.ends_with("Minus") or button.name.ends_with("Plus"):
			button.custom_minimum_size = Vector2(20.0, 20.0)
			button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			continue
		if save_slots_panel.is_ancestor_of(button):
			if button.name == "Delete":
				button.custom_minimum_size = Vector2(48.0, 18.0)
			elif button.name == "Back":
				button.custom_minimum_size = Vector2(72.0, 24.0)
			else:
				button.custom_minimum_size = Vector2(96.0, 36.0)
			button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			continue
		if credits_panel.is_ancestor_of(button):
			button.custom_minimum_size = Vector2(110.0, 30.0)
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
	for candidate in [main_panel, play_panel, save_slots_panel, settings_panel, credits_panel]:
		candidate.visible = candidate == panel
	# The Settings screen has its own heading artwork, so do not stack it over
	# the game's title logo.
	var uses_large_card: bool = panel == settings_panel or panel == save_slots_panel or panel == credits_panel
	title_logo.visible = not uses_large_card
	settings_backdrop.visible = panel == settings_panel
	save_slots_board.visible = panel == save_slots_panel
	save_slots_title.visible = panel == save_slots_panel
	credits_board.visible = panel == credits_panel
	credits_back_button.visible = panel == credits_panel
	_set_menu_card_layout(uses_large_card)
	if panel == credits_panel:
		_set_credits_card_layout()
	if panel == save_slots_panel:
		_set_save_card_layout()
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


func _set_credits_card_layout() -> void:
	var card: PanelContainer = %MenuCard
	card.anchor_left = 0.30
	card.anchor_top = 0.055
	card.anchor_right = 0.70
	card.anchor_bottom = 0.87
	card.offset_left = 0.0
	card.offset_top = 0.0
	card.offset_right = 0.0
	card.offset_bottom = 0.0


func _set_save_card_layout() -> void:
	var card: PanelContainer = %MenuCard
	card.anchor_left = 0.20
	card.anchor_top = 0.25
	card.anchor_right = 0.80
	card.anchor_bottom = 0.90
	card.offset_left = 0.0
	card.offset_top = 0.0
	card.offset_right = 0.0
	card.offset_bottom = 0.0


func _on_play_pressed() -> void:
	_update_continue_button()
	_show_panel(play_panel)


func _on_new_game_pressed() -> void:
	_open_save_slots(true)


func _on_load_game_pressed() -> void:
	_open_save_slots(false)


func _open_save_slots(for_new_game: bool) -> void:
	_slot_mode_new_game = for_new_game
	%Hint.text = "CHOOSE A NEW GAME SLOT" if for_new_game else "CHOOSE A SAVE TO CONTINUE"
	_refresh_save_slots()
	_show_panel(save_slots_panel)


func _refresh_save_slots() -> void:
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		var info: Dictionary = SaveManager.get_slot_info(slot)
		var occupied: bool = bool(info.get("exists", false))
		var select_button: TextureButton = _get_slot_select(slot)
		var delete_button: TextureButton = _get_slot_delete(slot)
		var balance_spacer: Control = save_slots_panel.get_node("Slot%d/Balance" % slot) as Control
		var slot_label: Label = select_button.get_node("Label") as Label
		if occupied:
			select_button.texture_normal = _save_slot_texture
			select_button.custom_minimum_size = Vector2(120.0, 34.0)
			slot_label.text = "SLOT %d  •  HP %d" % [slot, int(info.get("health", 100))]
			select_button.tooltip_text = ""
		else:
			select_button.texture_normal = _new_slot_texture
			select_button.custom_minimum_size = Vector2(96.0, 36.0)
			slot_label.text = "EMPTY SLOT %d" % slot
			select_button.tooltip_text = ""
		select_button.disabled = occupied if _slot_mode_new_game else not occupied
		select_button.modulate = Color(1, 1, 1, 0.38) if select_button.disabled else Color.WHITE
		delete_button.visible = occupied
		balance_spacer.visible = occupied


func _get_slot_select(slot: int) -> TextureButton:
	return save_slots_panel.get_node("Slot%d/Select" % slot) as TextureButton


func _get_slot_delete(slot: int) -> TextureButton:
	return save_slots_panel.get_node("Slot%d/Delete" % slot) as TextureButton


func _on_slot_selected(slot: int) -> void:
	if _slot_mode_new_game:
		SaveManager.start_new_game(slot)
	elif not SaveManager.load_game(slot):
		status_label.text = "Slot %d could not be loaded." % slot


func _on_slot_deleted(slot: int) -> void:
	if SaveManager.delete_save(slot):
		_refresh_save_slots()
		_update_continue_button()
	else:
		status_label.text = "Slot %d could not be deleted." % slot


func _on_slot_back_pressed() -> void:
	_update_continue_button()
	_show_panel(play_panel)


func _update_continue_button() -> void:
	var any_save_exists: bool = SaveManager.has_save()
	load_button.disabled = not any_save_exists
	load_button.modulate = Color.WHITE if any_save_exists else Color(1.0, 1.0, 1.0, 0.28)


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
