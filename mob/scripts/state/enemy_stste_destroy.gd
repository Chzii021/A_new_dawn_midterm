class_name EnemyStateDestroy
extends EnemyState

@export var anim_name: String = "dead"
@export var knockback_speed: float = 0

var _damage_position: Vector2
var _direction: Vector2


func init() -> void:
	enemy.enemy_destroyed.connect(_on_enemy_destroyed)

	if not enemy.animated_sprite.animation_finished.is_connected(_on_animation_finished):
		enemy.animated_sprite.animation_finished.connect(_on_animation_finished)


func enter() -> void:
	enemy.invulnerble = true

	# หาทิศจาก Enemy ไปยังจุดที่โดนโจมตี
	_direction = enemy.global_position.direction_to(_damage_position)

	enemy.set_direction(_direction)

	# กระเด็นออกจากจุดที่โดนตี
	enemy.velocity = -_direction * knockback_speed

	# เล่น animation ตาย
	enemy.animated_sprite.play(anim_name)

	print("ENEMY DEAD")


func exit() -> void:
	pass


func process(_delta: float) -> EnemyState:
	return null


func physics(_delta: float) -> EnemyState:
	# ถ้าอยากให้มี knockback ห้ามใส่ velocity = ZERO ตรงนี้
	return null


func handle_input(_event: InputEvent) -> EnemyState:
	return null


func _on_enemy_destroyed(hurt_box: HurtBox) -> void:
	# จำตำแหน่งของตัวที่โจมตี
	_damage_position = hurt_box.global_position

	state_machine.change_state(self)


func _on_animation_finished() -> void:
	if state_machine.current_state == self:
		enemy.queue_free()
