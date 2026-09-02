class_name Enemy
extends CharacterBody2D


signal direction_changed(new_directionn: Vector2)
signal enemy_damage(hurt_box: HurtBox)
signal enemy_destroyed(hurt_box: HurtBox)

const DIR_4 = [
	Vector2.RIGHT,
	Vector2.DOWN,
	Vector2.LEFT,
	Vector2.UP
]


@export var hp: int = 3
@export var hits_to_stun: int = 3


var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO

var player: player_2 = null
var invulnerble: bool = false

# จำนวนครั้งที่ Slime ทำ Damage ใส่ Player
var hit_count: int = 0

@onready var hurt_sound: AudioStreamPlayer2D = $HurtSound
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_box: HitBox = $HitBox
@onready var hurt_box: HurtBox = $HurtBox
@onready var state_machine: EnemyStateMachine = $EnemyStateMachine


func _ready() -> void:
	state_machine.initialize(self)

	player = PlayerManager.player

	# Slime ถูก Player ตี
	hit_box.Damaged.connect(_take_damaged)

	# Slime ชน Player
	hurt_box.hit_target.connect(_on_hurt_box_hit_target)


func _physics_process(_delta: float) -> void:
	move_and_slide()


func _process(_delta: float) -> void:
	pass


func set_direction(_new_direction: Vector2) -> bool:
	direction = _new_direction

	if direction == Vector2.ZERO:
		return false

	var direction_id: int = int(round(
		(direction + cardinal_direction * 0.1).angle()
		/ TAU
		* DIR_4.size()
	))

	direction_id = wrapi(
		direction_id,
		0,
		DIR_4.size()
	)

	var new_dir: Vector2 = DIR_4[direction_id]

	if new_dir == cardinal_direction:
		return false

	cardinal_direction = new_dir

	direction_changed.emit(new_dir)

	animated_sprite.flip_h = cardinal_direction == Vector2.LEFT

	return true


func update_animation(enemy_state: String) -> void:
	animated_sprite.play(
		enemy_state + "_" + anim_direction()
	)


func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "front"

	elif cardinal_direction == Vector2.UP:
		return "back"

	else:
		return "side"


# =========================================================
# SLIME รับ Damage จาก Player
# =========================================================

func _take_damaged(attacker_hurt_box: HurtBox) -> void:
	if invulnerble:
		return

	hp -= attacker_hurt_box.damage
	hp = max(hp, 0)
	hurt_sound.play()

	print("Slime HP = ", hp)

	if hp > 0:
		enemy_damage.emit(attacker_hurt_box)

	else:
		invulnerble = true
		enemy_destroyed.emit(attacker_hurt_box)


# =========================================================
# SLIME ทำ Damage ใส่ Player
# =========================================================

func _on_hurt_box_hit_target(target_hit_box: HitBox) -> void:
	var target: Node = target_hit_box.get_parent()

	# เช็กว่า HitBox ที่ชนคือของ Player จริง
	if target is not player_2:
		return

	var target_player: player_2 = target as player_2

	# นับจำนวนครั้งที่ Player โดน Slime
	hit_count += 1

	# ครบ 3 ครั้ง → Player Stun
	if hit_count >= hits_to_stun:
		hit_count = 0


		target_player.player_damage.emit(hurt_box)
