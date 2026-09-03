extends Control
const GLYPHS = preload("res://boss_room/pixel_health_bar.gd").GLYPHS
var caption := ""
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	var w := int(size.x)
	var h := int(size.y)
	for x in [1, w - 4]:
		for y in [1, h - 4]:
			draw_rect(Rect2(x, y, 3, 3), Color("ead19a"))
			draw_rect(Rect2(x + 1, y + 1, 1, 1), Color("5f4a30"))
	for y in range(18, h - 14, 19):
		draw_rect(Rect2(0, y, 2, 7), Color("b29456"))
		draw_rect(Rect2(w - 2, y + 4, 2, 7), Color("b29456"))
	for x in [7, w - 18]:
		draw_rect(Rect2(x, 0, 10, 2), Color("56763e"))
		draw_rect(Rect2(x + 3, -2, 5, 2), Color("8da557"))
		draw_rect(Rect2(x + 1, h - 2, 7, 2), Color("56763e"))
	for i in range(caption.length()):
		var bits: String = GLYPHS.get(caption[i], GLYPHS[" "])
		for p in range(15):
			if bits[p] == "1":
				draw_rect(Rect2(10 + (i * 4 + p % 3) * 2, 12 + int(p / 3) * 2, 2, 2), Color("ead7a0"))
