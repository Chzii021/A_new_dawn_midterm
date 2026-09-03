@tool
extends Node2D

const BACKGROUND: Texture2D = preload("res://boss_room/assets/forest_trail_pixel_v1.png")

# Shared with the collision builder. Art changes must not change this corridor.
static func path_center(y: float) -> float:
	return 160.0 + roundf(sin((y - 64.0) / 80.0) * 24.0 / 4.0) * 4.0

func _draw() -> void:
	draw_rect(Rect2(-4096, -4096, 8192, 8192), Color("101e1c"))
	draw_texture_rect(BACKGROUND, Rect2(-32, -32, 384, 576), false)
