class_name EnemyStateStun
extends EnemyState

@export var anim_name: String = "stun"
@export var knockback_speed: float = 200.0
@export var decelerate_speed: float = 10.0

@export_category("AI")
@export var next_state: EnemyState

var _direction: Vector2 = Vector2.ZERO
var _animation_finished: bool = false
var _damage_positionn: Vector2

func init() -> void:
	enemy.enemy_damage.connect(_on_enemy_damaged)

	if not enemy.animated_sprite.animation_finished.is_connected(_on_animation_finished):
		enemy.animated_sprite.animation_finished.connect(_on_animation_finished)


func enter() -> void:
	_animation_finished = false

	# หาทิศ Player
	if enemy.player != null:
		_direction = enemy.global_position.direction_to(_damage_positionn)

		# กระเด็นออกจาก Player
		enemy.velocity = -_direction * knockback_speed

		# หันหน้าไปหา Player
		enemy.set_direction(_direction)
	enemy.update_animation(anim_name)


func exit() -> void:
	_animation_finished = false



func process(delta: float) -> EnemyState:
	# ค่อย ๆ ลดแรงกระเด็น
	enemy.velocity = enemy.velocity.move_toward(
		Vector2.ZERO,
		decelerate_speed * 100.0 * delta
	)

	# Animation stun จบ
	if _animation_finished:
		if next_state != null:
			return next_state
	return null


func physics(_delta: float) -> EnemyState:
	return null


func handle_input(_event: InputEvent) -> EnemyState:
	return null


func _on_enemy_damaged(hurt_box: HurtBox) -> void:
	_damage_positionn = hurt_box.global_position
	state_machine.change_state(self)


func _on_animation_finished() -> void:
	# รับเฉพาะตอนที่อยู่ใน Stun State
	if state_machine.current_state != self:
		return

	var expected_animation = anim_name + "_" + enemy.anim_direction()

	# เช็กว่า Animation ที่จบคือ stun จริง
	if enemy.animated_sprite.animation == expected_animation:
		_animation_finished = true
