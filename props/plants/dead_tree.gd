extends Node2D

@export_category("ID")
@export var plant_id: String = "dead_tree_01"
@export var health: int = 5
@export_category("Regrow")
@export var regrow_time: float = 60.0
@export var tree_scene: PackedScene
@export_category("Water Items")
@export var empty_bucket: InvItem
@export var water_bucket: InvItem
@export_category("Drop")
@export var wood_item: InvItem

@export_category("Sound")
@export var hit_sounds: Array[AudioStream]
@export_category("Quest")
@export var count_for_village_quest: bool = false

# dead / watered / grown / removed
var tree_state: String = "dead"
var dead_variant: int = 1
var player_in_area: bool = false
var regrow_at: float = 0.0
var already_hit: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var water = $AnimatedSprite2D/water
@onready var hit_box: HitBox = $HitBox
@onready var audio: AudioStreamPlayer2D = $HitSound
@onready var effect_animation: AnimationPlayer = $EffectAnimationPlayer

func _ready() -> void:
	hit_box.Damaged.connect(TakeDamage)

	water.visible = false
	water.z_index = -1

	load_state()


func _process(_delta: float) -> void:
	if tree_state == "dead":
		if player_in_area:
			if Input.is_action_just_pressed("interact"):
				water_tree()

	elif tree_state == "watered":
		var now: float = Time.get_unix_time_from_system()

		if now >= regrow_at:
			grow_tree()

# =====================================================
# โดน Player ต่อย
# =====================================================
func TakeDamage(hurt_box: HurtBox) -> void:
	effect_animation.stop()
	effect_animation.play("tree_damaged")
	# รดน้ำแล้ว หรือหายไปแล้ว ห้ามตี
	if tree_state != "dead":
		return

	# ลดเลือด
	var damage: int = hurt_box.damage

	var player = PlayerManager.player

	if player != null:
		damage = player.get_tree_damage()

	health -= damage
	health = max(health, 0)

	# เสียงตอนตี
	if hit_sounds.size() > 0:
		audio.stream = hit_sounds.pick_random()
		audio.pitch_scale = randf_range(0.9, 1.1)
		audio.play()
	

	print("Dead Tree HP = ", health)

	# เซฟเลือดทุกครั้ง
	save_state()

	# ยังไม่ตาย
	if health > 0:
		return

	# ให้ไม้ 1 ท่อน
	give_wood()
	tree_state = "removed"
	hit_box.set_deferred("monitoring", false)
	hit_box.set_deferred("monitorable", false)

	save_state()

	print("Get Wood x1")
	# =========================================
	# QUEST : CUT DEAD TREES
	# =========================================
	if count_for_village_quest:

		QuestManager.add_unique_progress(
			"cut_dead_trees",
			plant_id
		)
		
	queue_free()

# =====================================================
# ให้ไม้ 1 ชิ้น
# =====================================================

func give_wood() -> void:
	var target_player: player_2 = PlayerManager.player
	target_player.collect(wood_item)

func water_tree() -> void:
	# ต้องเป็นต้นไม้ตายที่ยังไม่ได้รดเท่านั้น
	if tree_state != "dead":
		return

	var target_player: player_2 = PlayerManager.player



	# ==================================
	# เช็ก Bucket Water
	# ==================================
	var water_amount: int = target_player.inv.get_item_amount(
		water_bucket
	)

	if water_amount <= 0:
		print("ไม่มีถังน้ำ รดต้นไม้ตายไม่ได้")
		return


	# ==================================
	# Bucket Water → Bucket เปล่า
	# ==================================
	var success: bool = target_player.inv.replace_item(
		water_bucket,
		empty_bucket
	)

	if not success:
		print("ไม่สามารถใช้ถังน้ำได้")
		return


	# ==================================
	# รดสำเร็จ
	# ==================================
	tree_state = "watered"

	regrow_at = (
		Time.get_unix_time_from_system()
		+ regrow_time
	)

	# แสดงน้ำ
	water.visible = true

	# หลังรดแล้วห้ามตี
	hit_box.set_deferred("monitoring", false)
	hit_box.set_deferred("monitorable", false)

	save_state()

	print("รดน้ำ Dead Tree สำเร็จ!")
	print(
		"Bucket Water เหลือ = ",
		target_player.inv.get_item_amount(water_bucket)
	)
	print(
		"Bucket เปล่า = ",
		target_player.inv.get_item_amount(empty_bucket)
	)
	print("จะโตเป็นต้นไม้ใน ", regrow_time, " วินาที")

# =====================================================
# โตเป็น Tree ปกติ
# =====================================================

func grow_tree() -> void:

	if tree_state != "watered":
		return


	# ==========================================
	# จำว่าต้นตายต้นนี้โตเป็นต้นปกติแล้ว
	# ==========================================

	tree_state = "grown"
	regrow_at = 0.0

	save_state()


	# ==========================================
	# สร้างต้นไม้ปกติ
	# ==========================================

	spawn_normal_tree()

func spawn_normal_tree() -> void:

	if tree_scene == null:
		print("ERROR: ยังไม่ได้ใส่ Tree Scene")
		return


	var tree_instance = tree_scene.instantiate()

	# ใช้ ID เดิม
	tree_instance.plant_id = plant_id


	var parent_node = get_parent()
	var spawn_position: Vector2 = global_position


	parent_node.add_child(tree_instance)

	tree_instance.global_position = spawn_position


	print(
		"Dead Tree ",
		plant_id,
		" became normal Tree!"
	)


	queue_free()
	
# =====================================================
# Player เข้าใกล้
# =====================================================

func _on_interact_area_body_entered(body: Node2D) -> void:

	if body is player_2:
		player_in_area = true


func _on_interact_area_body_exited(body: Node2D) -> void:

	if body is player_2:
		player_in_area = false


# =====================================================
# SAVE
# =====================================================
func save_state() -> void:
	global.plant_states[plant_id] = {
		"dead_tree_state": tree_state,
		"regrow_at": regrow_at,
		"dead_variant": dead_variant,
		"health": health
	}

# =====================================================
# LOAD
# =====================================================
func load_state() -> void:
	# ต้นนี้ยังไม่เคยมีข้อมูล
	if not global.plant_states.has(plant_id):

		tree_state = "dead"
		regrow_at = 0.0

		# สุ่มครั้งแรกเท่านั้น
		dead_variant = randi_range(0, 1)

		save_state()
		update_visual()

		return


	var data: Dictionary = global.plant_states[plant_id]
	health = data.get("health", 5)
	# โหลดรูปแบบเดิมกลับมา
	dead_variant = data.get("dead_variant", 1)


	if not data.has("dead_tree_state"):
		tree_state = "dead"
		update_visual()
		return


	tree_state = data.get(
		"dead_tree_state",
		"dead"
	)

	regrow_at = data.get(
		"regrow_at",
		0.0
	)

	if tree_state == "grown":

		call_deferred(
			"spawn_normal_tree"
		)

		return

	if tree_state == "removed":

		queue_free()

		return	

	# ถูกต่อยไปแล้ว → หาย
	if tree_state == "removed":
		queue_free()
		return


	# รดน้ำไว้แล้ว
	if tree_state == "watered":

		water.visible = true

		hit_box.monitoring = false
		hit_box.monitorable = false

		update_visual()

		var now: float = Time.get_unix_time_from_system()

		if now >= regrow_at:
			call_deferred("grow_tree")

	else:
		update_visual()

func update_visual() -> void:
	animated_sprite.play("dead_tree" + str(dead_variant))

	if tree_state == "watered":
		water.visible = true
	else:
		water.visible = false
