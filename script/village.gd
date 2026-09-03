extends Node2D
@onready var audio: AudioStreamPlayer2D = $Audio

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global.current_scene = "village"
	global.transition_scene = false
	audio.play()
	$player2.current_camera()
	print(global.current_scene)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	change_scene()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		global.transition_scene = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		global.transition_scene = false

func change_scene():
	if global.transition_scene == true:
		if global.current_scene == "village":
			global.transition_scene = false
			BossRoute.travel(BossRoute.WORLD, BossRoute.WORLD_RETURN)
