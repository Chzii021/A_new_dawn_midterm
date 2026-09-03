extends Control
## Screen-space pixel UI. Does not change combat, quests or retry behavior.
const GLYPHS = preload("res://boss_room/pixel_health_bar.gd").GLYPHS
const FOREST: Texture2D = preload("res://boss_room/assets/deep_forest_arena.png")
const INK := Color("0b1515")
const GOLD := Color("a78a50")
const LIGHT := Color("ead7a0")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visibility_changed.connect(_sync_overlay)
	resized.connect(queue_redraw)
	_sync_overlay()

func _sync_overlay() -> void:
	$"../Shade".visible = visible

func _draw() -> void:
	var w := int(size.x)
	var h := int(size.y)
	draw_rect(Rect2(4, 6, w, h), Color(0, 0, 0, 0.5))
	# Stepped silhouette, wood rails, golden inner bevel and deep green inlay.
	draw_rect(Rect2(3, 0, w - 6, h), INK)
	draw_rect(Rect2(0, 3, w, h - 6), INK)
	draw_rect(Rect2(3, 3, w - 6, h - 6), Color("513d2b"))
	draw_rect(Rect2(5, 5, w - 10, h - 10), GOLD)
	draw_rect(Rect2(6, 6, w - 12, h - 12), Color("142722"))
	draw_texture_rect_region(FOREST, Rect2(8, 8, w - 16, 43), Rect2(0, 100, FOREST.get_width(), 440), Color("a8b99b"))
	draw_rect(Rect2(8, 44, w - 16, 7), Color(0.03, 0.07, 0.06, 0.75))
	draw_rect(Rect2(8, 51, w - 16, 1), GOLD)
	# Fallen leaf emblem: a copper leaf split down its center.
	var cx := int(w / 2)
	draw_rect(Rect2(cx - 15, 14, 30, 27), INK)
	draw_rect(Rect2(cx - 13, 12, 26, 31), INK)
	draw_rect(Rect2(cx - 12, 14, 24, 27), Color("6b5030"))
	draw_rect(Rect2(cx - 10, 16, 20, 23), Color("192921"))
	var leaf := ["000011000", "001111100", "011111110", "111101111", "111001111", "111011110", "010111100", "000111000", "001010000"]
	for y in range(leaf.size()):
		for x in range(9):
			if leaf[y][x] == "1":
				draw_rect(Rect2(cx - 9 + x * 2, 18 + y * 2, 2, 2), Color("df9860") if x < 4 else Color("a94f3c"))
	_text("YOU FELL", 62, Color("e6b080"), 2)
	_text("FOREST GUARDIAN", 82, Color("93aa7b"))
	draw_line(Vector2(38, 94), Vector2(w - 38, 94), Color("3e5540"), 1)
	_text("DODGE THE BLADE. STRIKE", 102, LIGHT)
	_text("WHEN THE GUARDIAN RESTS.", 111, LIGHT)
	_text("ENTER / SPACE TO RETRY", h - 15, Color("8c9c74"))
	# Pixel roots run along the rails; leaves and brass pins anchor the corners.
	for side in [0, 1]:
		var x := 3 if side == 0 else w - 4
		for y in range(16, h - 10, 13):
			var step := 1 if int(y / 13) % 2 == 0 else -1
			draw_rect(Rect2(x - 1, y, 3, 8), Color("80643b"))
			draw_rect(Rect2(x + step, y + 6, 3, 3), Color("80643b"))
		for y in [7, h - 10]:
			draw_rect(Rect2(x - 1, y, 3, 3), LIGHT)
			var lx := 10 if side == 0 else w - 18
			draw_rect(Rect2(lx, y - 1, 8, 3), Color("587343"))
			draw_rect(Rect2(lx + 2, y - 3, 4, 2), Color("8da25b"))

func _text(value: String, y: int, color: Color, pixel: int = 1) -> void:
	var x := int((size.x - (value.length() * 4 - 1) * pixel) / 2)
	for i in range(value.length()):
		var bits: String = GLYPHS.get(value[i], GLYPHS[" "])
		for p in range(15):
			if bits[p] == "1":
				draw_rect(Rect2(x + (i * 4 + p % 3) * pixel, y + int(p / 3) * pixel, pixel, pixel), color)
