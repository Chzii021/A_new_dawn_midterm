class_name state_attack
extends State

var attacking: bool = false

@export var attack_sounds: Array[AudioStream]
@export_range(1, 20, 0.5) var decelerate_speed : float = 5.0

@onready var animated_player: AnimatedSprite2D = $"../../AnimatedSprite2D"
@onready var walk: State = $"../walk"
@onready var idle: State = $"../idle"
@onready var audio: AudioStreamPlayer2D = $"../../Audio/AudioStreamPlayer2D"
@onready var hurt_box: HurtBox = $"../../Interaction/HurtBox"



func Enter() -> void:
	attacking = true

	player.UpdateAnimation("attack")

	if not animated_player.animation_finished.is_connected(EndAttack):
		animated_player.animation_finished.connect(EndAttack)
		
	# สุ่มเสียงโจมตี
	if attack_sounds.size() > 0:
		var random_sound = attack_sounds.pick_random()
		audio.stream = random_sound
		audio.pitch_scale = randf_range(0.9, 1.1)
		audio.play()
		
	await  get_tree().create_timer(0.075).timeout
	hurt_box.monitoring = true

func Exit() -> void:
	animated_player.animation_finished.disconnect(EndAttack)
	attacking = false
	hurt_box.monitoring = false


func Process(_delta: float) -> State:
	player.velocity -= player.velocity * decelerate_speed * _delta

	if attacking == false:
		if player.direction == Vector2.ZERO:
			return idle
		else:
			return walk

	return null


func Physics(_delta: float) -> State:
	return null


func HandleInput(_event: InputEvent) -> State:
	return null


func EndAttack() -> void:
	attacking = false
