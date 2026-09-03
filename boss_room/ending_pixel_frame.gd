extends Control
const Art = preload("res://boss_room/ending_pixel_art.gd")
var kind := "panel"
var chapter_index := 0
var expand_edges := Vector4.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_set_transform(Vector2(-expand_edges.x, -expand_edges.y))
	var w := int(size.x + expand_edges.x + expand_edges.z)
	var h := int(size.y + expand_edges.y + expand_edges.w)
	if kind == "title":
		Art.lettering(self, "THE END", Vector2(int((w - 81) / 2), 3), 3)
		return
	Art.frame(self, Rect2(0, 0, w, h))
	if kind == "header":
		Art.lettering(self, "EPILOGUE", Vector2(11, 8))
		for i in range(4):
			var x := 53 + i * 13
			draw_rect(Rect2(x, 7, 8, 8), Color("b58d4a") if i == chapter_index else Color("3d5139"))
			Art.lettering(self, str(i + 1), Vector2(x + 2, 8), 1, Color("fff0b9") if i == chapter_index else Color("83936a"))
	else:
		Art.leaf(self, Vector2(8, 0))
		Art.leaf(self, Vector2(w - 10, 0), -1)
		Art.leaf(self, Vector2(w - 15, h - 5), -1)
