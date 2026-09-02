@tool
extends Node2D

const FOREST: Texture2D = preload("res://boss_room/assets/deep_forest_arena.png")
var gate_closed: bool = false

func _draw() -> void:
	draw_rect(Rect2(-8192, -8192, 16384, 16384), Color("050d10"))
	draw_texture_rect(FOREST, Rect2(0, 0, 576, 352), false)
	if gate_closed:
		# Visible root barrier matches the entrance collision; no stone gate in the forest.
		for index in range(5):
			var y: float = 306.0 + index * 3.0
			var root_line := PackedVector2Array([Vector2(248, y + 4), Vector2(268, y - 1), Vector2(286, y + 2), Vector2(308, y - 2), Vector2(328, y + 3)])
			draw_polyline(root_line, Color("313b20"), 4)
			draw_polyline(root_line, Color("657044"), 1)
