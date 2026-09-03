extends Node2D

const ART = preload("res://boss_room/forest_path_art.gd")
@onready var player: CharacterBody2D = $Actors/Player

func _ready() -> void:
	global.current_scene = "forest_path"
	global.transition_scene = false
	player.position = BossRoute.TRAIL_START
	for child in player.get_children():
		if child is Camera2D:
			child.enabled = false
	$Actors/Player/TrailCamera.enabled = true
	$Actors/Player/TrailCamera.make_current()
	_build_edges()

func _build_edges() -> void:
	for side in [-1, 1]:
		var body := StaticBody2D.new()
		body.collision_layer = 16
		body.collision_mask = 0
		var shape := CollisionPolygon2D.new()
		var outer: float = -128 if side == -1 else 448
		var points := PackedVector2Array([Vector2(outer, 32)])
		for y in range(32, 529, 16):
			points.append(Vector2(ART.path_center(y) + side * 52, y))
		points.append(Vector2(outer, 528))
		shape.polygon = points
		body.add_child(shape)
		$Walls.add_child(body)

func _process(_delta: float) -> void:
	$HUD/Hint.visible = not $Actors/BossGate.player_near() and not $Actors/VillageExit.player_near()
