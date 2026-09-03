extends RefCounted
## Integer-pixel ornamentation shared only by the epilogue UI.
const GLYPHS = preload("res://boss_room/pixel_health_bar.gd").GLYPHS

static func lettering(canvas: CanvasItem, label: String, at: Vector2, pixel: int = 1, ink: Color = Color("f4df9c")) -> void:
	for i in range(label.length()):
		var bits: String = GLYPHS.get(label[i], GLYPHS[" "])
		for p in range(15):
			if bits[p] == "1":
				canvas.draw_rect(Rect2(at + Vector2(i * 4 + p % 3, int(p / 3)) * pixel, Vector2.ONE * pixel), ink)

static func leaf(canvas: CanvasItem, at: Vector2, mirror: int = 1) -> void:
	for i in range(4):
		canvas.draw_rect(Rect2(at + Vector2(i * 2 * mirror, i), Vector2(3, 2)), Color("56753d"))
		canvas.draw_rect(Rect2(at + Vector2(i * 2 * mirror, i), Vector2(2, 1)), Color("9baa58"))

static func frame(canvas: CanvasItem, area: Rect2, fill: Color = Color("15251f")) -> void:
	var x := int(area.position.x)
	var y := int(area.position.y)
	var w := int(area.size.x)
	var h := int(area.size.y)
	canvas.draw_rect(Rect2(x + 3, y + 3, w - 3, h - 1), Color("050d0b"))
	canvas.draw_rect(Rect2(x + 2, y, w - 4, h), Color("211b14"))
	canvas.draw_rect(Rect2(x, y + 2, w, h - 4), Color("211b14"))
	canvas.draw_rect(Rect2(x + 1, y + 3, w - 2, h - 6), Color("715231"))
	canvas.draw_rect(Rect2(x + 3, y + 1, w - 6, h - 2), Color("715231"))
	canvas.draw_rect(Rect2(x + 4, y + 4, w - 8, h - 8), Color("b09053"))
	canvas.draw_rect(Rect2(x + 5, y + 5, w - 10, h - 10), fill)
	canvas.draw_rect(Rect2(x + 5, y + 2, w - 10, 1), Color("d1ad68"))
	canvas.draw_rect(Rect2(x + 5, y + h - 3, w - 10, 1), Color("453720"))
	for grain in range(12, w - 12, 23):
		canvas.draw_rect(Rect2(x + grain, y + 3, 7, 1), Color("4c3824"))
		canvas.draw_rect(Rect2(x + grain + 3, y + h - 4, 5, 1), Color("96713e"))
	for cx in [x + 2, x + w - 5]:
		for cy in [y + 2, y + h - 5]:
			canvas.draw_rect(Rect2(cx, cy, 3, 3), Color("e5c584"))
			canvas.draw_rect(Rect2(cx + 1, cy + 1, 1, 1), Color("76542c"))
