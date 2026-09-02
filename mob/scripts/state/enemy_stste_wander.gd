class_name EnemyStateWander
extends EnemyState

@export var anim_name: String = "walk"
@export var wander_speed: float = 20.0

@export_category("AI")
@export var state_animation_duration: float = 0.5
@export var state_cycles_min: int = 1
@export var state_cycles_max: int = 3
@export var next_state: EnemyState

var _timer: float = 0.0
var _direction : Vector2

func init() -> void:
	pass


func enter() -> void:
	# สุ่มระยะเวลาที่จะเดิน
	_timer = randi_range(state_cycles_min, state_cycles_max) * state_animation_duration
	# สุ่มทิศจาก 4 ทิศโดยตรง
	_direction = enemy.DIR_4.pick_random()
	enemy.velocity = _direction * wander_speed
	enemy.set_direction(_direction)
	enemy.update_animation(anim_name)

func exit() -> void:
	pass


func process(delta: float) -> EnemyState:
	_timer -= delta
	if _timer <= 0:
		return next_state
	return null

func physics(_delta: float) -> EnemyState:
	return null


func handle_input(_event: InputEvent) -> EnemyState:
	return null
