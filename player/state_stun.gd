class_name state_stun
extends State

@export var knockback_speed: float = 200.0
@export var decelerate_speed: float = 10.0
@export var invulnerble_duration: float = 1.0

var hurt_box: HurtBox
var direction: Vector2
var next_state: State = null

@onready var idle: State = $"../idle"


func init() -> void:
	player.player_damage.connect(_player_damaged)


func Enter() -> void:
	

	if not player.animated_sprite.animation_finished.is_connected(_animation_finished):
		player.animated_sprite.animation_finished.connect(_animation_finished)

	# ทิศจาก Player ไปหาศัตรู
	direction = player.global_position.direction_to(hurt_box.global_position)

	# กระเด็นออกจากศัตรู
	player.velocity = direction * -knockback_speed
	player.UpdateAnimation("stun")
	player.make_invulnerble(invulnerble_duration)
	player.effect_animationt_player.play("damaged")


func Exit() -> void:
	next_state = null

	if player.animated_sprite.animation_finished.is_connected(_animation_finished):
		player.animated_sprite.animation_finished.disconnect(_animation_finished)


func Process(_delta: float) -> State:
	player.velocity -= player.velocity * decelerate_speed * _delta
	return next_state


func Physics(delta: float) -> State:
	# ค่อย ๆ ลดแรงกระเด็น
	player.velocity = player.velocity.move_toward(
		Vector2.ZERO,
		decelerate_speed * delta
	)

	return null


func _player_damaged(_hurt_box: HurtBox) -> void:
	hurt_box = _hurt_box
	state_machine.ChangeState(self)


func _animation_finished() -> void:
	next_state = idle
