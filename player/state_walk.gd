class_name state_walk
extends State

@export var move_speed: float = 100.0
@onready var audio: AudioStreamPlayer2D =$"../../Audio/walk"
@onready var idle: State = $"../idle"
@onready var attack: State = $"../attack"


func Enter() -> void:
	player.UpdateAnimation("walk")
	audio.play()


func Exit() -> void:
	audio.stop()


func Process(_delta: float) -> State:
	# ปล่อยปุ่มเดิน → Idle
	if player.direction == Vector2.ZERO:
		player.velocity = Vector2.ZERO
		return idle

	# กำหนดความเร็วเฉพาะ Walk State
	player.velocity = player.direction.normalized() * move_speed

	player.update_direction()
	player.UpdateAnimation("walk")

	return null


func Physics(_delta: float) -> State:
	return null


func HandleInput(event: InputEvent) -> State:
	if event.is_action_pressed("attack"):
		return attack

	return null
