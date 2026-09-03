extends Control
const PixelFrame = preload("res://boss_room/ending_pixel_frame.gd")
const PixelButton = preload("res://boss_room/ending_pixel_button.gd")
var chapter_frame: Control
var picture_frame: Control
## Four supplied stills, animated with camera motion and fades; no image regeneration.
const SLIDES := [
	{"image": "res://boss_room/assets/ending/01_final_blow.jpg", "text": "วิกรมรวบรวมพลัง โจมตีบอสเป็นครั้งสุดท้าย", "duration": 5.0},
	{"image": "res://boss_room/assets/ending/02_spirit_released.jpg", "text": "เมื่อบอสพ่ายแพ้ ภูติผีที่สิงอยู่ก็หลุดออก เหลือเพียงแคนของคุณยาย", "duration": 6.0},
	{"image": "res://boss_room/assets/ending/03_return_khaen.png", "text": "วิกรมนำแคนกลับมาคืนให้คุณยาย", "duration": 5.0},
	{"image": "res://boss_room/assets/ending/04_grandmother_plays.png", "text": "คุณยายเป่าแคนอีกครั้ง เสียงเพลงแห่งความสุขกลับคืนสู่บ้าน", "duration": 7.0}
]
var slide_index := 0
var elapsed := 0.0
var changing := false
var finished := false
var leaving := false
var picture: TextureRect
var caption: Label
var chapter: Label
var fade: ColorRect
var finish_panel: Control
var next_button: Button
var skip_button: Button
var menu_button: Button
var movement: Tween
var transition: Tween

func _ready() -> void:
	SaveManager.game_active = false
	get_tree().paused = false
	theme = preload("res://inventory/forest_ui_theme.gd").create_theme()
	_build_ui()
	resized.connect(_restart_motion)
	_show_slide(0)

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("081310")
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture_frame = PixelFrame.new()
	add_child(picture_frame)
	picture_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture_frame.offset_left = 8
	picture_frame.offset_right = -8
	picture_frame.offset_top = 31
	picture_frame.offset_bottom = -54
	picture = TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.offset_left = 14
	picture.offset_right = -14
	picture.offset_top = 37
	picture.offset_bottom = -60
	picture.resized.connect(_fit_picture_frame)
	chapter_frame = PixelFrame.new()
	chapter_frame.kind = "header"
	chapter_frame.position = Vector2(8, 4)
	chapter_frame.size = Vector2(110, 23)
	add_child(chapter_frame)
	chapter = Label.new()
	chapter.position = Vector2(9, 4)
	add_child(chapter)
	chapter.hide()
	skip_button = PixelButton.new()
	skip_button.text = "SKIP"
	add_child(skip_button)
	skip_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	skip_button.offset_left = -55
	skip_button.offset_right = -8
	skip_button.offset_top = 4
	skip_button.offset_bottom = 29
	skip_button.pressed.connect(_show_end)
	var panel := PanelContainer.new()
	panel.name = "CaptionPanel"
	var panel_style := StyleBoxEmpty.new()
	panel_style.content_margin_left = 11
	panel_style.content_margin_right = 9
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 8
	panel.offset_right = -8
	panel.offset_top = -49
	panel.offset_bottom = -5
	var trim := PixelFrame.new()
	trim.expand_edges = Vector4(11, 8, 9, 8)
	panel.add_child(trim)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	caption = Label.new()
	var thai := SystemFont.new()
	thai.font_names = PackedStringArray(["Tahoma", "Leelawadee UI"])
	caption.add_theme_font_override("font", thai)
	caption.add_theme_font_size_override("font_size", 9)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(caption)
	next_button = PixelButton.new()
	next_button.text = "NEXT >"
	next_button.custom_minimum_size = Vector2(47, 26)
	next_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	next_button.pressed.connect(_advance)
	row.add_child(next_button)
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	finish_panel = Control.new()
	add_child(finish_panel)
	finish_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.05, 0.035, 0.88)
	finish_panel.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	finish_panel.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var end_card := PanelContainer.new()
	end_card.custom_minimum_size = Vector2(218, 130)
	var end_margin := StyleBoxEmpty.new()
	end_margin.set_content_margin_all(18)
	end_card.add_theme_stylebox_override("panel", end_margin)
	center.add_child(end_card)
	var end_trim := PixelFrame.new()
	end_trim.expand_edges = Vector4(18, 18, 18, 18)
	end_card.add_child(end_trim)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	end_card.add_child(box)
	var title := PixelFrame.new()
	title.kind = "title"
	title.custom_minimum_size = Vector2(145, 22)
	box.add_child(title)
	var thanks := Label.new()
	thanks.text = "THANK YOU FOR PLAYING"
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(thanks)
	menu_button = PixelButton.new()
	menu_button.text = "MAIN MENU"
	menu_button.custom_minimum_size = Vector2(145, 29)
	menu_button.pressed.connect(_return_to_menu)
	box.add_child(menu_button)
	finish_panel.hide()

func _process(delta: float) -> void:
	if changing or finished: return
	elapsed += delta
	if elapsed >= float(SLIDES[slide_index].duration): _advance()

func _show_slide(index: int) -> void:
	slide_index = index
	elapsed = 0
	changing = true
	picture.texture = load(SLIDES[index].image)
	caption.text = SLIDES[index].text
	chapter.text = "EPILOGUE  /  %02d - 04" % (index + 1)
	chapter_frame.chapter_index = index
	chapter_frame.queue_redraw()
	next_button.text = "FINISH" if index == 3 else "NEXT >"
	_restart_motion()
	transition = create_tween()
	transition.tween_property(fade, "color:a", 0.0, 0.55)
	transition.tween_callback(func(): changing = false)

func _restart_motion() -> void:
	if picture == null or finished: return
	_fit_picture_frame()
	if movement != null and movement.is_valid(): movement.kill()
	picture.pivot_offset = picture.size * 0.5
	picture.scale = Vector2.ONE * 0.98
	movement = create_tween()
	movement.tween_property(picture, "scale", Vector2.ONE, float(SLIDES[slide_index].duration) + 0.55).set_trans(Tween.TRANS_SINE)

func _fit_picture_frame() -> void:
	if picture == null or picture.texture == null: return
	var image_size := picture.texture.get_size()
	var fit := minf(picture.size.x / image_size.x, picture.size.y / image_size.y)
	var fitted := (image_size * fit).floor()
	picture_frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	picture_frame.position = (picture.position + (picture.size - fitted) * 0.5).floor() - Vector2(6, 6)
	picture_frame.size = fitted + Vector2(12, 12)

func _advance() -> void:
	if changing or finished: return
	if slide_index == SLIDES.size() - 1:
		_show_end()
		return
	changing = true
	transition = create_tween()
	transition.tween_property(fade, "color:a", 1.0, 0.45)
	transition.tween_callback(_show_slide.bind(slide_index + 1))

func _show_end() -> void:
	if finished: return
	finished = true
	changing = false
	if transition != null and transition.is_valid(): transition.kill()
	if movement != null and movement.is_valid(): movement.kill()
	fade.color.a = 0.0
	finish_panel.show()
	next_button.disabled = true
	skip_button.disabled = true
	menu_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or finished: return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		_advance()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_show_end()

func _return_to_menu() -> void:
	if leaving: return
	leaving = true
	var error := get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	if error != OK:
		leaving = false
		menu_button.text = "TRY AGAIN"
