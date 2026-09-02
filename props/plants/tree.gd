extends Node2D
@export var plant_id: String = "tree_01"
@export_category("Tree")
@export var health: int = 12
@export var stump_health: int = 5
@export_category("Regrow")
@export var regrow_time: float = 90.0
@export_category("Drop")
@export var wood_item: InvItem
@export var wood_drop_amount: int = 3
@export var stump_wood_amount: int = 1

@export_category("Sound")
@export var chop_sounds: Array[AudioStream]

@export_category("Water Items")
@export var empty_bucket: InvItem
@export var water_bucket: InvItem

var max_health: int
var stump_max_health: int
var tree_state: String = "alive"
var tree_variant: int = 1
var player_in_area: bool = false
var player: player_2 = null
var regrow_at: float = 0.0
var stump_can_take_damage: bool = true

@onready var audio: AudioStreamPlayer2D = $HitSound
@onready var effect_animation: AnimationPlayer = $EffectAnimationPlayer
@onready var hit_box: HitBox = $HitBox
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var shadow_sprite = (
	$AnimatedSprite2D/ShadowSprite2D
)

@onready var water_sprite = (
	$AnimatedSprite2D/water
)

func _ready() -> void:
	# จำ HP เต็มของต้น
	max_health = health

	# จำ HP เต็มของตอ
	stump_max_health = stump_health

	hit_box.Damaged.connect(TakeDamage)

	load_tree_state()


# =====================================================
# PROCESS
# =====================================================

func _process(_delta: float) -> void:

	# =========================================
	# เป็นตอ → สามารถกดรดน้ำ
	# =========================================

	if tree_state == "stump":

		if player_in_area:

			if Input.is_action_just_pressed("interact"):
				water_tree()


	# =========================================
	# รดน้ำแล้ว → รอโต
	# =========================================

	elif tree_state == "watered":

		var now: float = (
			Time.get_unix_time_from_system()
		)

		if now >= regrow_at:
			regrow_tree()


# =====================================================
# DAMAGE สำหรับพวกต้นไม้
# =====================================================

func get_wood_damage(hurt_box: HurtBox) -> int:

	# Damage ปกติ
	var damage: int = hurt_box.damage

	var target_player: player_2 = (
		PlayerManager.player
	)

	if target_player == null:
		return damage


	# ต้องเป็น HurtBox ที่อยู่ภายใน Player
	# จึงจะได้รับโบนัสจากขวาน
	if target_player.is_ancestor_of(hurt_box):

		damage = (
			target_player.get_tree_damage()
		)


	return damage


# =====================================================
# รับ DAMAGE
# =====================================================

func TakeDamage(hurt_box: HurtBox) -> void:

	# หายไปแล้ว
	if tree_state == "removed":
		return

	# รดน้ำแล้ว ห้ามตี
	if tree_state == "watered":
		return


	var damage: int = (
		get_wood_damage(hurt_box)
	)


	# =================================================
	# ต้นใหญ่โดนตี
	# =================================================

	if tree_state == "alive":

		effect_animation.stop()
		effect_animation.play(
			"tree_damaged"
		)

		health -= damage

		health = max(
			health,
			0
		)

		play_chop_sound()


		print(
			"Tree Damage = ",
			damage,
			" | HP = ",
			health,
			"/",
			max_health
		)


		save_tree_state()


		# HP ต้นหมด
		if health <= 0:
			become_stump()


		return


	# =================================================
	# ตอไม้โดนตี
	# =================================================

	if tree_state == "stump":

		# เพิ่งกลายเป็นตอ
		# ไม่รับ Damage จากการตีครั้งเดิม
		if not stump_can_take_damage:
			return


		stump_health -= damage

		stump_health = max(
			stump_health,
			0
		)


		effect_animation.stop()
		effect_animation.play(
			"tree_damaged"
		)

		play_chop_sound()


		print(
			"Stump Damage = ",
			damage,
			" | HP = ",
			stump_health,
			"/",
			stump_max_health
		)


		save_tree_state()


		# HP ตอหมด → ทำลาย
		if stump_health <= 0:
			remove_stump()


		return


# =====================================================
# ต้นใหญ่ HP 0 → กลายเป็นตอ
# =====================================================

func become_stump() -> void:

	tree_state = "stump"

	# HP ต้นใหญ่หมด
	health = 0

	# ตอเกิดมา HP เต็ม 5
	stump_health = stump_max_health


	# =========================================
	# กัน Hit เดิมไปโดนตอซ้ำ
	# =========================================

	stump_can_take_damage = false


	update_tree_visual()

	drop_wood()

	save_tree_state()


	print(
		"Tree became stump | Stump HP = ",
		stump_health,
		"/",
		stump_max_health
	)


	# รอให้การโจมตีเดิมจบก่อน
	await get_tree().create_timer(
		0.35
	).timeout


	# ถ้ายังเป็นตออยู่
	if tree_state == "stump":
		stump_can_take_damage = true


# =====================================================
# ตอ HP 0 → ทำลาย
# =====================================================

func remove_stump() -> void:

	if tree_state != "stump":
		return


	tree_state = "removed"

	stump_health = 0


	hit_box.set_deferred(
		"monitoring",
		false
	)

	hit_box.set_deferred(
		"monitorable",
		false
	)


	give_stump_wood()

	save_tree_state()


	print("Stump destroyed!")


	queue_free()


# =====================================================
# ได้ไม้จากตอ
# =====================================================

func give_stump_wood() -> void:

	var target_player: player_2 = (
		PlayerManager.player
	)

	if target_player == null:
		return

	if wood_item == null:
		print("ERROR: Wood Item is null")
		return


	for i in range(stump_wood_amount):
		target_player.collect(
			wood_item
		)


	print(
		"Get Wood x",
		stump_wood_amount
	)


# =====================================================
# รดน้ำตอ
# =====================================================

func water_tree() -> void:

	if tree_state != "stump":
		return


	var target_player: player_2 = (
		PlayerManager.player
	)


	if target_player == null:

		print(
			"ERROR: Player not found"
		)

		return


	if target_player.inv == null:

		print(
			"ERROR: Player ไม่มี Inventory"
		)

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
	# เช็กว่ามี Bucket Water
	# =========================================

	var water_bucket_amount: int = (
		target_player.inv.get_item_amount(
			water_bucket
		)
	)


	if water_bucket_amount <= 0:

		print(
			"ไม่มีถังน้ำ รดต้นไม้ไม่ได้"
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

		print(
			"ไม่สามารถใช้ถังน้ำได้"
		)

		return


	# =========================================
	# รดน้ำสำเร็จ
	# =========================================

	tree_state = "watered"

	stump_can_take_damage = false


	regrow_at = (
		Time.get_unix_time_from_system()
		+ regrow_time
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


	update_tree_visual()

	save_tree_state()


	print(
		"รดน้ำต้นไม้สำเร็จ!"
	)

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
		"ต้นไม้จะโตใน ",
		regrow_time,
		" วินาที"
	)


# =====================================================
# โตกลับเป็นต้นใหญ่
# =====================================================

func regrow_tree() -> void:

	if tree_state != "watered":
		return


	tree_state = "alive"


	# HP ต้นเต็ม
	health = max_health

	# ตอนนี้ไม่มีตอ
	stump_health = 0


	regrow_at = 0.0

	stump_can_take_damage = true


	hit_box.monitoring = true
	hit_box.monitorable = true


	update_tree_visual()

	save_tree_state()


	print(
		"Tree regrown! HP = ",
		health,
		"/",
		max_health
	)


# =====================================================
# PLAYER เข้าใกล้
# =====================================================

func _on_interact_area_body_entered(
	body: Node2D
) -> void:

	if body is player_2:

		player = body
		player_in_area = true


func _on_interact_area_body_exited(
	body: Node2D
) -> void:

	if body == player:

		player_in_area = false
		player = null


# =====================================================
# DROP WOOD จากต้นใหญ่
# =====================================================

func drop_wood() -> void:

	var target_player: player_2 = (
		PlayerManager.player
	)


	if target_player == null:
		return


	if wood_item == null:

		print(
			"ERROR: Wood Item is null"
		)

		return


	for i in range(wood_drop_amount):

		target_player.collect(
			wood_item
		)


	print(
		"Get Wood x",
		wood_drop_amount
	)


# =====================================================
# SOUND
# =====================================================

func play_chop_sound() -> void:

	if chop_sounds.is_empty():
		return


	audio.stream = (
		chop_sounds.pick_random()
	)


	audio.pitch_scale = (
		randf_range(
			0.9,
			1.1
		)
	)


	audio.play()


# =====================================================
# SAVE
# =====================================================

func save_tree_state() -> void:

	global.plant_states[plant_id] = {

		"health":
			health,

		"stump_health":
			stump_health,

		"tree_state":
			tree_state,

		"tree_variant":
			tree_variant,

		"regrow_at":
			regrow_at
	}


# =====================================================
# LOAD
# =====================================================

func load_tree_state() -> void:

	# =========================================
	# ต้นนี้ยังไม่เคยมีข้อมูล
	# =========================================

	if not global.plant_states.has(
		plant_id
	):

		tree_variant = randi_range(
			0,
			3
		)

		tree_state = "alive"

		health = max_health

		# ยังไม่มีตอ
		stump_health = 0

		regrow_at = 0.0

		stump_can_take_damage = true


		save_tree_state()

		update_tree_visual()

		return


	# =========================================
	# โหลดข้อมูล
	# =========================================

	var data: Dictionary = (
		global.plant_states[plant_id]
	)


	tree_state = data.get(
		"tree_state",
		"alive"
	)


	health = data.get(
		"health",
		max_health
	)


	tree_variant = data.get(
		"tree_variant",
		1
	)


	regrow_at = data.get(
		"regrow_at",
		0.0
	)


	# =========================================
	# โหลด HP ตอ
	# =========================================

	if data.has("stump_health"):

		stump_health = data.get(
			"stump_health",
			stump_max_health
		)

	else:

		# รองรับ Save เก่าที่ไม่มี stump_health
		if tree_state == "stump":

			stump_health = (
				stump_max_health
			)

		else:

			stump_health = 0


	# =========================================
	# removed
	# =========================================

	if tree_state == "removed":

		hit_box.monitoring = false
		hit_box.monitorable = false

		queue_free()

		return


	# =========================================
	# stump
	# =========================================

	if tree_state == "stump":

		health = 0

		# ถ้า Save เก่าเคยเป็น 0
		# ให้คืน HP ตอเป็น 5
		if stump_health <= 0:

			stump_health = (
				stump_max_health
			)


		stump_can_take_damage = true


		hit_box.monitoring = true
		hit_box.monitorable = true


	# =========================================
	# watered
	# =========================================

	elif tree_state == "watered":

		stump_can_take_damage = false


		hit_box.monitoring = false
		hit_box.monitorable = false


		var now: float = (
			Time.get_unix_time_from_system()
		)


		if now >= regrow_at:

			regrow_tree()

			return


	# =========================================
	# alive
	# =========================================

	elif tree_state == "alive":

		stump_can_take_damage = true


		hit_box.monitoring = true
		hit_box.monitorable = true


	update_tree_visual()


# =====================================================
# VISUAL
# =====================================================

func update_tree_visual() -> void:

	match tree_state:


		# =====================================
		# ต้นใหญ่
		# =====================================

		"alive":

			animated_sprite.visible = true

			shadow_sprite.visible = true

			water_sprite.visible = false


			animated_sprite.play(
				"tree"
				+ str(tree_variant)
			)


		# =====================================
		# ตอ
		# =====================================

		"stump":

			animated_sprite.visible = true

			shadow_sprite.visible = false

			water_sprite.visible = false


			animated_sprite.play(
				"dead tree"
			)


		# =====================================
		# ตอที่รดน้ำ
		# =====================================

		"watered":

			animated_sprite.visible = true

			shadow_sprite.visible = false

			water_sprite.visible = true


			animated_sprite.play(
				"dead tree"
			)


		# =====================================
		# ถูกทำลาย
		# =====================================

		"removed":

			animated_sprite.visible = false

			shadow_sprite.visible = false

			water_sprite.visible = false
