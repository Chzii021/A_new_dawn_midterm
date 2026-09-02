class_name player_2
extends CharacterBody2D

const SPEED = 100.0

var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO

var invulnerble: bool = false

var hp: int = global.player_health
var max_hp: int = global.player_max_health


# =====================================================
# DAMAGE
# =====================================================

@export var base_attack_damage: int = 1

# โบนัสเฉพาะพวกต้นไม้
var tree_damage_bonus: int = 0


# =====================================================
# INVENTORY
# =====================================================

@export var inv: Inv = preload("res://inventory/playerinv.tres")


# =====================================================
# NODES
# =====================================================

@onready var health_bar: ProgressBar = $CanvasLayer/ProgressBar
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: PLaterStateMachine = $StateMachine

# Player รับ Damage
@onready var hit_box: HitBox = $HitBox

# Player ใช้โจมตี
@onready var hurt_box: HurtBox = $Interaction/HurtBox

@onready var effect_animationt_player: AnimationPlayer = $EffectAnimationPlayer
@onready var hurt_sound: AudioStreamPlayer2D = $Audio/hurt_sound


# =====================================================
# SIGNALS
# =====================================================

signal DirectionChanged(new_direction: Vector2)
signal player_damage(hurt_box: HurtBox)


func player():
	pass


func _ready() -> void:
	print("PLAYER READY")

	PlayerManager.player = self

	# Damage ที่ใช้ตี Monster ยังคงเป็น Damage ปกติ
	hurt_box.damage = base_attack_damage

	health_bar.max_value = max_hp
	health_bar.value = hp

	animated_sprite.play("idle_front")

	state_machine.Initialize(self)

	hit_box.Damaged.connect(_take_damage)


# =====================================================
# MOVEMENT
# =====================================================

func _physics_process(_delta):
	direction = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	if direction != Vector2.ZERO:
		direction = direction.normalized()

	move_and_slide()


func update_direction():
	var new_dir: Vector2 = cardinal_direction

	if direction.y > 0:
		new_dir = Vector2.DOWN

	elif direction.y < 0:
		new_dir = Vector2.UP

	elif direction.x > 0:
		new_dir = Vector2.RIGHT

	elif direction.x < 0:
		new_dir = Vector2.LEFT

	if new_dir == cardinal_direction:
		return

	cardinal_direction = new_dir

	DirectionChanged.emit(cardinal_direction)


# =====================================================
# ANIMATION
# =====================================================

func UpdateAnimation(animation_state: String):
	match cardinal_direction:

		Vector2.RIGHT:
			animated_sprite.flip_h = true
			animated_sprite.play(animation_state + "_side")

		Vector2.LEFT:
			animated_sprite.flip_h = false
			animated_sprite.play(animation_state + "_side")

		Vector2.DOWN:
			animated_sprite.flip_h = false
			animated_sprite.play(animation_state + "_front")

		Vector2.UP:
			animated_sprite.flip_h = false
			animated_sprite.play(animation_state + "_back")


# =====================================================
# CAMERA
# =====================================================

func current_camera():
	var cameras = {
		"world": $world_camera,
		"village": $village_camera
	}

	for camera in cameras.values():
		camera.enabled = false

	if cameras.has(global.current_scene):
		cameras[global.current_scene].enabled = true

	else:
		print(
			"ERROR: Camera not found for scene: ",
			global.current_scene
		)


# =====================================================
# PLAYER DAMAGE
# =====================================================

func _take_damage(hurt_box: HurtBox) -> void:
	if invulnerble:
		return

	update_hp(-hurt_box.damage)

	hurt_sound.play()

	print(
		"Player HP: ",
		hp,
		"/",
		max_hp
	)

	if hp <= 0:
		print("PLAYER DEAD")
		die()


func update_hp(delta: int) -> void:
	hp = clampi(
		hp + delta,
		0,
		max_hp
	)

	global.player_health = hp
	global.player_max_health = max_hp

	health_bar.value = hp


func make_invulnerble(_duration: float = 1.0) -> void:
	invulnerble = true

	hit_box.monitoring = false

	await get_tree().create_timer(
		_duration
	).timeout

	invulnerble = false

	hit_box.monitoring = true


func die() -> void:
	velocity = Vector2.ZERO

	# ถ้าตายแล้วเริ่มใหม่ HP เต็ม
	global.player_health = global.player_max_health


# =====================================================
# INVENTORY
# =====================================================
func collect(item: InvItem) -> void:
	if inv == null:
		print("ERROR: Player inv = null")
		return

	if item == null:
		print("ERROR: Item = null")
		return

	inv.insert(item)


# =====================================================
# EQUIPMENT
# =====================================================

func equip_item(item: InvItem) -> void:
	# ถอด Effect ของชิ้นเก่าก่อน
	tree_damage_bonus = 0

	# ถ้ามี Item ที่เลือกอยู่
	if item != null:
		tree_damage_bonus = item.tree_damage_bonus

# =====================================================
# DAMAGE FUNCTIONS
# =====================================================

# Damage ปกติ
# ใช้กับ Monster
func get_normal_damage() -> int:
	return base_attack_damage


# Damage สำหรับต้นไม้ / ตอไม้ / ต้นไม้ตาย
func get_tree_damage() -> int:
	return (
		base_attack_damage
		+ tree_damage_bonus
	)
