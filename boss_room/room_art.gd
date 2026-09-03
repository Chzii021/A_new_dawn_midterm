@tool
extends Node2D
## Code-drawn placeholder art; visible in the editor and replaceable with a TileMapLayer.
var gate_closed: bool = false

func _draw() -> void:
	draw_rect(Rect2(-8192, -8192, 16384, 16384), Color("10151c"))
	draw_rect(Rect2(0, 0, 576, 352), Color("20262c"))
	for row in range(10):
		for col in range(17):
			var tone: float = float((col * 7 + row * 3) % 5) * 0.009
			var stone := Color(0.22 + tone, 0.27 + tone, 0.29 + tone)
			draw_rect(Rect2(16 + col * 32, 16 + row * 32, 31, 31), stone)
	# Inlaid border and central ritual dais.
	draw_rect(Rect2(40, 40, 496, 256), Color("617276"), false, 2)
	draw_rect(Rect2(46, 46, 484, 244), Color("303e43"), false, 2)
	draw_circle(Vector2(288, 160), 79, Color("263339"))
	draw_arc(Vector2(288, 160), 78, 0, TAU, 64, Color("728486"), 2)
	draw_arc(Vector2(288, 160), 64, 0, TAU, 64, Color("435c62"), 2)
	var diamond := PackedVector2Array([Vector2(288, 120), Vector2(324, 160), Vector2(288, 200), Vector2(252, 160), Vector2(288, 120)])
	draw_polyline(diamond, Color("83c9bd"), 2)
	draw_circle(Vector2(288, 160), 7, Color("a7d9c3"))
	for i in range(8):
		var direction := Vector2.from_angle(i * TAU / 8.0)
		draw_line(Vector2(288, 160) + direction * 68, Vector2(288, 160) + direction * 74, Color("83c9bd"), 3)
	# Southern approach, leading from the entry alcove into the arena.
	for step in range(3):
		draw_rect(Rect2(264, 252 + step * 26, 48, 20), Color("526267"))
		draw_line(Vector2(264, 252 + step * 26), Vector2(312, 252 + step * 26), Color("82908b"))
	# Walls align with the scene's layer-5 collision bodies.
	_wall(Rect2(0, 0, 576, 24))
	_wall(Rect2(0, 24, 16, 328))
	_wall(Rect2(560, 24, 16, 328))
	_wall(Rect2(16, 328, 232, 24))
	_wall(Rect2(328, 328, 232, 24))
	# Entry recess: back wall prevents walking outside the room even while open.
	draw_rect(Rect2(248, 328, 80, 24), Color("172126"))
	draw_rect(Rect2(248, 346, 80, 6), Color("46565d"))
	for p in [Vector2(88, 80), Vector2(488, 80), Vector2(88, 264), Vector2(488, 264)]:
		_pillar(p)
	for p in [Vector2(176, 22), Vector2(400, 22), Vector2(232, 328), Vector2(344, 328)]:
		_torch(p)
	if gate_closed:
		draw_rect(Rect2(248, 302, 80, 9), Color("48352f"))
		for x in range(252, 328, 10):
			draw_rect(Rect2(x, 303, 4, 24), Color("d09a64"))
	else:
		draw_rect(Rect2(249, 319, 78, 2), Color("83c9bd"))

func _wall(rect: Rect2) -> void:
	draw_rect(rect, Color("151d26"))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), Color("6a7779"))
	for x in range(int(rect.position.x) + 2, int(rect.end.x) - 2, 24):
		draw_rect(Rect2(x, rect.position.y + 6, minf(22, rect.end.x - x - 1), minf(13, rect.size.y - 6)), Color("3e4b53"))

func _pillar(p: Vector2) -> void:
	draw_ellipse_shadow(p)
	draw_rect(Rect2(p - Vector2(15, 10), Vector2(30, 20)), Color("27323a"))
	draw_rect(Rect2(p - Vector2(11, 27), Vector2(22, 29)), Color("68757b"))
	draw_rect(Rect2(p - Vector2(7, 24), Vector2(5, 25)), Color("839193"))
	draw_rect(Rect2(p - Vector2(15, 32), Vector2(30, 8)), Color("99a5a0"))

func draw_ellipse_shadow(p: Vector2) -> void:
	draw_rect(Rect2(p - Vector2(17, 4), Vector2(36, 16)), Color(0.04, 0.07, 0.09, 0.45))

func _torch(p: Vector2) -> void:
	draw_circle(p, 16, Color(1.0, 0.6, 0.2, 0.055))
	draw_rect(Rect2(p + Vector2(-3, 1), Vector2(6, 9)), Color("36272a"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-5, 0), p + Vector2(-2, -10), p + Vector2(1, -6), p + Vector2(3, -13), p + Vector2(5, 0)]), Color("f0a35e"))
	draw_rect(Rect2(p + Vector2(-2, -5), Vector2(4, 6)), Color("ffe5a0"))
