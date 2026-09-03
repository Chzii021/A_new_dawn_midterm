extends Node2D
@onready var audio: AudioStreamPlayer2D = $Audio

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global.current_scene = "world"
	global.transition_scene = false
	$player.current_camera()
	audio.play()
	print(global.current_scene)
	
	if global.game_first_loading == true:
		$player.position.x = global.player_start_posx
		$player.position.y = global.player_start_posy
	else:
		$player.position.x = global.player_exit_village_posx
		$player.position.y = global.player_exit_village_posy
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	change_scene()


func _on_ciffside_transition_point_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		global.transition_scene = true


func _on_ciffside_transition_point_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		global.transition_scene = false

func change_scene():
	if global.transition_scene == true:
		if global.current_scene == "world":
			global.transition_scene = false
			if BossRoute.travel(BossRoute.VILLAGE, BossRoute.VILLAGE_ENTRY):
				global.game_first_loading = false
			
