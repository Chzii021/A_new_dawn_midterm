class_name state_idle
extends State

@onready var walk: State = $"../walk"
@onready var attack: State = $"../attack"


func Enter() -> void:
	player.velocity = Vector2.ZERO
	player.UpdateAnimation("idle")


func Exit() -> void:
	pass


func Process(_delta: float) -> State:
	# เช็ก Input เดิน ไม่ใช่ velocity
	if player.direction != Vector2.ZERO:
		return walk

	player.velocity = Vector2.ZERO
	return null


func Physics(_delta: float) -> State:
	return null


func HandleInput(event: InputEvent) -> State:
	if event.is_action_pressed("attack"):
		return attack

	return null
