extends Node2D

@export var plant_id: String = "seedling_01"

@export_category("Grow")
@export var grow_time: float = 60.0
@export_category("Water Items")
@export var empty_bucket: InvItem
@export var water_bucket: InvItem
@export var tree_scene: PackedScene

var player_in_area: bool = false
var is_watered: bool = false
var grow_at: float = 0.0

@onready var water = $AnimatedSprite2D/water


func _ready() -> void:
	# น้ำปิดไว้ก่อน
	water.visible = false
	water.z_index = -1

	load_seedling_state()


func _process(_delta: float) -> void:
	# ยังไม่ได้รดน้ำ
	if not is_watered:
		if player_in_area:
			if Input.is_action_just_pressed("interact"):
				water_seedling()

	# รดแล้ว
	else:
		var now: float = Time.get_unix_time_from_system()

		if now >= grow_at:
			grow_into_tree()

func water_seedling() -> void:
	# รดไปแล้ว ห้ามรดซ้ำ
	if is_watered:
		return

	var target_player: player_2 = PlayerManager.player

	if target_player == null:
		print("ERROR: Player not found")
		return

	if target_player.inv == null:
		print("ERROR: Player ไม่มี Inventory")
		return

	if water_bucket == null:
		print("ERROR: ยังไม่ได้กำหนด bucket_water.tres")
		return

	if empty_bucket == null:
		print("ERROR: ยังไม่ได้กำหนด bucket.tres")
		return


	# เช็กว่ามีถังน้ำหรือไม่
	var water_amount: int = target_player.inv.get_item_amount(
		water_bucket
	)

	if water_amount <= 0:
		print("ไม่มีถังน้ำ รดต้นอ่อนไม่ได้")
		return


	# เปลี่ยนถังน้ำ → ถังเปล่า
	var success: bool = target_player.inv.replace_item(
		water_bucket,
		empty_bucket
	)

	if not success:
		print("ไม่สามารถใช้ถังน้ำได้")
		return


	# =========================
	# รดน้ำสำเร็จ
	# =========================
	is_watered = true

	water.visible = true

	grow_at = (
		Time.get_unix_time_from_system()
		+ grow_time
	)

	save_seedling_state()

	print("รดน้ำต้นอ่อนสำเร็จ!")
	print(
		"Bucket Water เหลือ = ",
		target_player.inv.get_item_amount(water_bucket)
	)
	print(
		"Bucket เปล่า = ",
		target_player.inv.get_item_amount(empty_bucket)
	)
	print("ต้นอ่อนจะโตใน ", grow_time, " วินาที")

# =====================================================
# โตเป็นต้นไม้ใหญ่
# =====================================================

func grow_into_tree() -> void:
	if tree_scene == null:
		print("ERROR: ยังไม่ได้ใส่ Tree Scene")
		return

	# จำว่าต้นอ่อนนี้โตแล้ว
	global.seedling_states[plant_id] = {
		"state": "grown",
		"grow_at": 0.0
	}

	var tree_instance = tree_scene.instantiate()

	# สำคัญ:
	# ถ้า tree.gd ของคุณมี plant_id
	# ให้ต้นใหม่ใช้ ID เดียวกับต้นอ่อน
	tree_instance.plant_id = plant_id

	# ตำแหน่งเดิม
	tree_instance.position = position

	get_parent().add_child(tree_instance)

	print("Seedling became tree!")

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

func save_seedling_state() -> void:
	global.seedling_states[plant_id] = {
		"state": "watered" if is_watered else "seedling",
		"grow_at": grow_at
	}


# =====================================================
# LOAD
# =====================================================

func load_seedling_state() -> void:
	# ยังไม่เคยมีข้อมูล
	if not global.seedling_states.has(plant_id):
		save_seedling_state()
		return


	var data: Dictionary = global.seedling_states[plant_id]

	var state: String = data.get(
		"state",
		"seedling"
	)


	# ============================
	# เคยโตเป็นต้นใหญ่แล้ว
	# ============================
	if state == "grown":
		call_deferred("grow_into_tree")
		return


	# ============================
	# เคยรดน้ำ
	# ============================
	if state == "watered":
		is_watered = true

		grow_at = data.get(
			"grow_at",
			0.0
		)

		water.visible = true

		var now: float = Time.get_unix_time_from_system()

		# ระหว่างอยู่แมพอื่นครบ 60 วิแล้ว
		if now >= grow_at:
			call_deferred("grow_into_tree")


	else:
		is_watered = false
		water.visible = false
