extends Node2D

@export_category("ID")
@export var plant_id: String = "papaya_01"

@export_category("Papaya")
@export var health: int = 8
@export var grow_time: float = 10.0
@export var item: InvItem
@export var wood_drop_amount: int = 2
@export_category("Stump")
@export var stump_health: int = 5
@export var stump_wood_amount: int = 1
@export var wood_item: InvItem

@export_category("Regrow Tree")
@export var tree_regrow_time: float = 240.0

@export_category("Water Items")
@export var empty_bucket: InvItem
@export var water_bucket: InvItem

@export_category("Sound")
@export var chop_sounds: Array[AudioStream]

var stump_can_take_damage: bool = true
var max_health: int
var stump_max_health: int

# papaya / no papaya / stump / watered / removed
var tree_state: String = "papaya"

var player_in_area: bool = false
var player = null


# เวลาเกิดลูกมะละกอใหม่
var fruit_regrow_at: float = 0.0

# เวลาที่ตอจะโตกลับเป็นต้น
var tree_regrow_at: float = 0.0


var papaya = preload(
	"res://scenes/papaya_collectable.tscn"
)


@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var effect_animation: AnimationPlayer = $EffectAnimationPlayer
@onready var growth_timer: Timer = $growth_timer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_box: HitBox = $HitBox

@onready var water_sprite: Sprite2D = $AnimatedSprite2D/water


func _ready() -> void:
	max_health = health
	stump_max_health = stump_health

	hit_box.Damaged.connect(TakeDamage)

	water_sprite.visible = false
	water_sprite.z_index = -1

	load_plant_state()
	update_visual()


func _process(_delta: float) -> void:

	# =========================================
	# ต้นถูกทำลายถาวรแล้ว
	# =========================================
	if tree_state == "removed":
		return


	# =========================================
	# ต้นปกติ มีลูก
	# =========================================
	if tree_state == "papaya":

		if player_in_area:
			if Input.is_action_just_pressed("interact"):
				pick_papaya()


	# =========================================
	# เป็นตอ → กด Space รดน้ำ
	# =========================================
	elif tree_state == "stump":

		if player_in_area:
			if Input.is_action_just_pressed("interact"):
				water_stump()


	# =========================================
	# รดน้ำแล้ว → เช็กครบ 240 วิ
	# =========================================
	elif tree_state == "watered":

		var now: float = Time.get_unix_time_from_system()

		if now >= tree_regrow_at:
			regrow_tree()


# =====================================================
# VISUAL
# =====================================================

func update_visual() -> void:

	match tree_state:

		"papaya":
			animated_sprite.visible = true
			animated_sprite.play("papaya")
			water_sprite.visible = false


		"no papaya":
			animated_sprite.visible = true
			animated_sprite.play("no papaya")
			water_sprite.visible = false


		"stump":
			animated_sprite.visible = true
			animated_sprite.play("dead papaya")
			water_sprite.visible = false


		"watered":
			animated_sprite.visible = true
			animated_sprite.play("dead papaya")
			water_sprite.visible = true


		"removed":
			water_sprite.visible = false


# =====================================================
# รับ DAMAGE
# =====================================================

func TakeDamage(hurt_box: HurtBox) -> void:
	var damage: int = get_wood_damage(hurt_box)
	# =========================================
	# ต้นปกติ
	# =========================================
	if tree_state == "papaya" or tree_state == "no papaya":

		effect_animation.stop()
		effect_animation.play("tree_damaged")


		var player_ = PlayerManager.player

		if player_ != null:
			damage = player_.get_tree_damage()

		health -= damage
		health = max(health, 0)

		play_chop_sound()

		print(
			"Papaya Tree Damage = ",
			damage,
			" | HP = ",
			health,
			"/",
			max_health
		)

		save_plant_state()

		if health <= 0:
			become_stump()

		return


	# =========================================
	# ตอไม้
	# ตี 5 ครั้งโดยนับ "ครั้ง" ไม่ได้นับ damage
	# =========================================
	if tree_state == "stump":

	# เพิ่งกลายเป็นตอ
	# ยังไม่นับ Damage จากการโจมตีครั้งเดิม
		if not stump_can_take_damage:
			return

		stump_health -= damage
		stump_health = max(stump_health, 0)

		effect_animation.stop()
		effect_animation.play("tree_damaged")

		play_chop_sound()

		print(
			"Stump Damage = ",
			damage,
			" | HP = ",
			stump_health,
			"/",
			stump_max_health
		)

		save_plant_state()

		if stump_health <= 0:
			destroy_stump()

		return


# =====================================================
# ต้น HP 0 → กลายเป็นตอ
# =====================================================
func become_stump() -> void:
	tree_state = "stump"

	health = 0

	stump_health = stump_max_health

	stump_can_take_damage = false

	growth_timer.stop()
	fruit_regrow_at = 0.0

	update_visual()
	save_plant_state()
	drop_wood()

	print(
		"Papaya became stump | Stump HP = ",
		stump_health,
		"/",
		stump_max_health
	)

	await get_tree().create_timer(0.35).timeout

	if tree_state == "stump":
		stump_can_take_damage = true

func drop_wood() -> void:

	var target_player: player_2 = PlayerManager.player

	for i in range(wood_drop_amount):
		target_player.collect(wood_item)

	print("Get Wood x", wood_drop_amount)
	
func destroy_stump() -> void:

	if tree_state != "stump":
		return

	tree_state = "removed"

	hit_box.set_deferred(
		"monitoring",
		false
	)

	hit_box.set_deferred(
		"monitorable",
		false
	)

	give_stump_wood()
	save_plant_state()
	queue_free()

func give_stump_wood() -> void:
	var target_player: player_2 = PlayerManager.player
	for i in range(stump_wood_amount):
		target_player.collect(wood_item)
	print(
		"Get Wood x",
		stump_wood_amount
	)

func water_stump() -> void:

	if tree_state != "stump":
		return


	var target_player: player_2 = PlayerManager.player


	if target_player == null:
		print("ERROR: Player not found")
		return


	if target_player.inv == null:
		print("ERROR: Player ไม่มี Inventory")
		return


	if water_bucket == null:
		print(
			"ERROR: ยังไม่ได้กำหนด bucket_water.tres"
		)
		return


	if empty_bucket == null:
		print(
			"ERROR: ยังไม่ได้กำหนด bucket.tres"
		)
		return


	# =========================================
	# ต้องมี Bucket Water
	# =========================================

	var water_amount: int = (
		target_player.inv.get_item_amount(
			water_bucket
		)
	)


	if water_amount <= 0:
		print(
			"ไม่มีถังน้ำ รดต้นมะละกอไม่ได้"
		)
		return


	# =========================================
	# Bucket Water → Bucket เปล่า
	# =========================================

	var success: bool = (
		target_player.inv.replace_item(
			water_bucket,
			empty_bucket
		)
	)


	if not success:
		print("ไม่สามารถใช้ถังน้ำได้")
		return


	# =========================================
	# รดสำเร็จ
	# =========================================

	tree_state = "watered"

	tree_regrow_at = (
		Time.get_unix_time_from_system()
		+ tree_regrow_time
	)


	# รดแล้วห้ามตี
	hit_box.set_deferred(
		"monitoring",
		false
	)

	hit_box.set_deferred(
		"monitorable",
		false
	)


	update_visual()
	save_plant_state()


	print("รดน้ำต้นมะละกอสำเร็จ!")

	print(
		"Bucket Water เหลือ = ",
		target_player.inv.get_item_amount(
			water_bucket
		)
	)

	print(
		"Bucket เปล่า = ",
		target_player.inv.get_item_amount(
			empty_bucket
		)
	)

	print(
		"ต้นมะละกอจะโตใน ",
		tree_regrow_time,
		" วินาที"
	)


# =====================================================
# ครบ 240 วิ → ต้นโตใหม่
# =====================================================

func regrow_tree() -> void:

	if tree_state != "watered":
		return


	tree_state = "papaya"

	health = max_health
	stump_health = 0

	tree_regrow_at = 0.0
	fruit_regrow_at = 0.0


	hit_box.monitoring = true
	hit_box.monitorable = true


	update_visual()
	save_plant_state()


	print("Papaya Tree regrown!")


# =====================================================
# Player เข้าใกล้
# =====================================================

func _on_pick_papaya_area_body_entered(
	body: Node2D
) -> void:

	if body.has_method("player"):
		player_in_area = true
		player = body


func _on_pick_papaya_area_body_exited(
	body: Node2D
) -> void:

	if body == player:
		player_in_area = false
		player = null


# =====================================================
# เก็บลูกมะละกอ
# =====================================================

func pick_papaya() -> void:

	if tree_state != "papaya":
		return


	tree_state = "no papaya"


	fruit_regrow_at = (
		Time.get_unix_time_from_system()
		+ grow_time
	)


	save_plant_state()

	growth_timer.start(grow_time)

	drop()

	update_visual()


# =====================================================
# ลูกมะละกอเกิดใหม่
# =====================================================

func _on_growth_timer_timeout() -> void:

	if tree_state != "no papaya":
		return


	tree_state = "papaya"

	fruit_regrow_at = 0.0

	save_plant_state()

	update_visual()

	print("Papaya regrown!")


# =====================================================
# DROP PAPAYA
# =====================================================

func drop() -> void:

	var instance = papaya.instantiate()

	get_parent().add_child(instance)

	instance.global_position = (
		$Marker2D.global_position
	)

	instance.z_index = 1


	if player != null:
		player.collect(item)


# =====================================================
# SOUND
# =====================================================

func play_chop_sound() -> void:

	if chop_sounds.is_empty():
		return

	audio.stream = chop_sounds.pick_random()

	audio.pitch_scale = randf_range(
		0.9,
		1.1
	)

	audio.play()


# =====================================================
# SAVE
# =====================================================

func save_plant_state() -> void:

	global.plant_states[plant_id] = {
		"tree_state": tree_state,
		"health": health,
		"stump_health": stump_health,
		"fruit_regrow_at": fruit_regrow_at,
		"tree_regrow_at": tree_regrow_at
	}


# =====================================================
# LOAD
# =====================================================

func load_plant_state() -> void:

	# =========================================
	# ยังไม่มีข้อมูลต้นนี้
	# =========================================

	if not global.plant_states.has(plant_id):

		tree_state = "papaya"
		health = max_health
		stump_health = 0

		save_plant_state()

		return


	var data: Dictionary = (
		global.plant_states[plant_id]
	)


	tree_state = data.get(
		"tree_state",
		"papaya"
	)

	health = data.get(
		"health",
		max_health
	)

	stump_health = data.get(
		"stump_health",
		0
	)

	fruit_regrow_at = data.get(
		"fruit_regrow_at",
		0.0
	)

	tree_regrow_at = data.get(
		"tree_regrow_at",
		0.0
	)


	# =========================================
	# รองรับ Save เก่าที่ใช้ is_dead
	# =========================================

	if data.get("is_dead", false):
		tree_state = "stump"
		health = 0


	# =========================================
	# ถูกทำลายไปแล้ว
	# =========================================

	if tree_state == "removed":

		hit_box.monitoring = false
		hit_box.monitorable = false

		queue_free()

		return


	# =========================================
	# ไม่มีลูกมะละกอ
	# =========================================

	if tree_state == "no papaya":

		# รองรับ Save เก่าที่ใช้ regrow_at
		if fruit_regrow_at <= 0:
			fruit_regrow_at = data.get(
				"regrow_at",
				0.0
			)


		var now: float = (
			Time.get_unix_time_from_system()
		)


		var remaining: float = (
			fruit_regrow_at - now
		)


		if remaining <= 0:

			tree_state = "papaya"
			fruit_regrow_at = 0.0

			save_plant_state()

		else:

			growth_timer.start(
				remaining
			)


	# =========================================
	# เป็นตอ
	# =========================================

	elif tree_state == "stump":

		health = 0

		hit_box.monitoring = true
		hit_box.monitorable = true


	# =========================================
	# รดน้ำแล้ว
	# =========================================

	elif tree_state == "watered":

		hit_box.monitoring = false
		hit_box.monitorable = false


		var now: float = (
			Time.get_unix_time_from_system()
		)


		# ครบ 240 วิระหว่างอยู่แมพอื่นแล้ว
		if now >= tree_regrow_at:

			regrow_tree()

			return

func get_wood_damage(hurt_box: HurtBox) -> int:
	# ค่า Damage ปกติของการโจมตีนั้น
	var damage: int = hurt_box.damage

	var target_player: player_2 = PlayerManager.player

	if target_player == null:
		return damage

	# ต้องเป็น HurtBox ที่อยู่ภายใน Player เท่านั้น
	# ป้องกันกรณี Monster ตีต้นไม้แล้วได้ Bonus ขวานของ Player
	if target_player.is_ancestor_of(hurt_box):
		damage = target_player.get_tree_damage()

	return damage
