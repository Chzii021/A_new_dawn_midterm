extends Button
const Art = preload("res://boss_room/ending_pixel_art.gd")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		add_theme_color_override(key, Color.TRANSPARENT)
	for event in [mouse_entered, mouse_exited, focus_entered, focus_exited, button_down, button_up, resized]:
		event.connect(queue_redraw)

func _draw() -> void:
	var lit := (is_hovered() or has_focus()) and not disabled
	var down := 1 if button_pressed else 0
	Art.frame(self, Rect2(0, down, size.x, size.y - 2), Color("46603b") if lit else Color("263c2b"))
	var label := text.replace(" >", "")
	var ink := Color("7f8867") if disabled else Color("ffe3a0")
	Art.lettering(self, label, Vector2(int((size.x - label.length() * 4 + 1) / 2), int((size.y - 5) / 2) + down), 1, ink)
	if lit:
		draw_rect(Rect2(7, int(size.y / 2) - 1 + down, 2, 2), Color("ffe3a0"))
