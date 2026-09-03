extends Button
const GLYPHS = preload("res://boss_room/pixel_health_bar.gd").GLYPHS

func _ready() -> void:
	for style in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	add_theme_color_override("font_color", Color.TRANSPARENT)
	add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	add_theme_color_override("font_focus_color", Color.TRANSPARENT)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

func _draw() -> void:
	var selected := is_hovered() or has_focus()
	var down := 1 if button_pressed else 0
	var w := int(size.x)
	var h := int(size.y)
	draw_rect(Rect2(2, 2, w - 4, h - 1), Color("081411"))
	draw_rect(Rect2(0, down, w, h - 3), Color("d1b36c") if selected else Color("8b7147"))
	draw_rect(Rect2(1, 1 + down, w - 2, h - 5), Color("304e36") if selected else Color("23392d"))
	draw_rect(Rect2(3, 2 + down, w - 6, 1), Color("718557"))
	var label := "TRY AGAIN"
	var x := int((w - label.length() * 4 + 1) / 2)
	for i in range(label.length()):
		var bits: String = GLYPHS.get(label[i], GLYPHS[" "])
		for p in range(15):
			if bits[p] == "1":
				draw_rect(Rect2(x + i * 4 + p % 3, 8 + down + int(p / 3), 1, 1), Color("f3dfa4"))
	if selected:
		draw_rect(Rect2(10, 9 + down, 2, 3), Color("e3b967"))
		draw_rect(Rect2(12, 10 + down, 2, 1), Color("e3b967"))
