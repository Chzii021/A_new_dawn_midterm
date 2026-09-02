extends Node2D


# =====================================================
# ID
# =====================================================

@export_category("ID")

# ID สำหรับจำสถานะของต้นกล้า
# แต่ละต้นต้องไม่ซ้ำกัน
@export var plant_id: String = "seedling_01"


# =====================================================
# GROW
# =====================================================

@export_category("Grow")

@export var grow_time: float = 60.0
@export var tree_scene: PackedScene


# =====================================================
# WATER ITEM
# =====================================================

@export_category("Water Items")

@export var empty_bucket: InvItem
@export var water_bucket: InvItem


# =====================================================
# QUEST
# =====================================================

@export_category("Quest")

# เปิดเฉพาะต้นกล้าใน Village ที่ต้องการให้นับเควส
@export var count_for_village_quest: bool = false

# ID สำหรับ Quest
# แต่ละต้นต้องไม่ซ้ำ
@export var seedling_id: String = "village_seedling_01"


# =====================================================
# STATE
# =====================================================

var player_in_area: bool = false

var is_watered: bool = false

var grow_at: float = 0.0


# =====================================================
# NODE
# =====================================================

@onready var water = $AnimatedSprite2D/water


# =====================================================
# READY
# =====================================================

func _ready() -> void:

	# น้ำอยู่ด้านหลังต้นไม้
	water.z_index = -1

	# ปิดก่อน แล้วค่อยให้ load_state ตัดสิน
	water.visible = false


	load_seedling_state()


# =====================================================
# PROCESS
# =====================================================

func _process(_delta: float) -> void:

	# =========================================
	# ยังไม่ได้รดน้ำ
	# =========================================

	if not is_watered:

		if player_in_area:

			if Input.is_action_just_pressed(
				"interact"
			):

				water_seedling()


	# =========================================
	# รดน้ำแล้ว
	# =========================================

	else:

		var now: float = (
			Time.get_unix_time_from_system()
		)


		if now >= grow_at:

			grow_into_tree()


# =====================================================
# WATER SEEDLING
# =====================================================

func water_seedling() -> void:

	# รดแล้ว ห้ามรดซ้ำ
	if is_watered:
		return


	# =========================================
	# หา Player
	# =========================================

	var target_player: player_2 = (
		PlayerManager.player
	)


	if target_player == null:

		print(
			"ERROR: ไม่พบ Player"
		)

		return


	if target_player.inv == null:

		print(
			"ERROR: Player ไม่มี Inventory"
		)

		return


	# =========================================
	# เช็ก Bucket Water
	# =========================================

	if water_bucket == null:

		print(
			"ERROR: ยังไม่ได้ใส่ Water Bucket"
		)

		return


	if empty_bucket == null:

		print(
			"ERROR: ยังไม่ได้ใส่ Empty Bucket"
		)

		return


	var water_amount: int = (
		target_player.inv.get_item_amount(
			water_bucket
		)
	)


	if water_amount <= 0:

		print(
			"ไม่มีถังน้ำ รดต้นอ่อนไม่ได้"
		)

		return


	# =========================================
	# Water Bucket → Empty Bucket
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

	is_watered = true

	water.visible = true


	grow_at = (
		Time.get_unix_time_from_system()
		+ grow_time
	)


	# =========================================
	# SAVE ก่อน
	# =========================================

	save_seedling_state()


	# =========================================
	# QUEST 3
	# =========================================

	if count_for_village_quest:

		QuestManager.add_unique_progress(
			"quest_03",
			seedling_id
		)


	# =========================================
	# DEBUG
	# =========================================

	print(
		"รดน้ำต้นอ่อนสำเร็จ: ",
		plant_id
	)


	if count_for_village_quest:

		print(
			"Quest Seedling ID = ",
			seedling_id
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
		"ต้นอ่อนจะโตใน ",
		grow_time,
		" วินาที"
	)


# =====================================================
# GROW INTO TREE
# =====================================================

func grow_into_tree() -> void:

	if tree_scene == null:

		print(
			"ERROR: ยังไม่ได้ใส่ Tree Scene"
		)

		return


	# =========================================
	# จำว่าต้นนี้โตแล้ว
	# =========================================

	global.seedling_states[plant_id] = {

		"state": "grown",

		"grow_at": 0.0
	}


	# =========================================
	# จำตำแหน่งก่อนลบต้นกล้า
	# =========================================

	var spawn_position: Vector2 = (
		global_position
	)


	var parent_node: Node = (
		get_parent()
	)


	# =========================================
	# สร้างต้นไม้ใหญ่
	# =========================================

	var tree_instance = (
		tree_scene.instantiate()
	)


	# ถ้า Tree มี plant_id
	if "plant_id" in tree_instance:

		tree_instance.plant_id = plant_id


	parent_node.add_child(
		tree_instance
	)


	tree_instance.global_position = (
		spawn_position
	)


	print(
		"Seedling ",
		plant_id,
		" became tree!"
	)


	queue_free()


# =====================================================
# PLAYER ENTER
# =====================================================

func _on_interact_area_body_entered(
	body: Node2D
) -> void:

	if body is player_2:

		player_in_area = true


# =====================================================
# PLAYER EXIT
# =====================================================

func _on_interact_area_body_exited(
	body: Node2D
) -> void:

	if body is player_2:

		player_in_area = false


# =====================================================
# SAVE
# =====================================================

func save_seedling_state() -> void:

	var current_state: String = "seedling"


	if is_watered:

		current_state = "watered"


	global.seedling_states[plant_id] = {

		"state":
			current_state,

		"grow_at":
			grow_at
	}


# =====================================================
# LOAD
# =====================================================

func load_seedling_state() -> void:

	# =========================================
	# ไม่เคยมีข้อมูล
	# =========================================

	if not global.seedling_states.has(
		plant_id
	):

		is_watered = false
		grow_at = 0.0

		water.visible = false

		save_seedling_state()

		return


	# =========================================
	# โหลดข้อมูล
	# =========================================

	var data: Dictionary = (
		global.seedling_states[plant_id]
	)


	var state: String = data.get(
		"state",
		"seedling"
	)


	grow_at = data.get(
		"grow_at",
		0.0
	)


	# =========================================
	# โตไปแล้ว
	# =========================================

	if state == "grown":

		is_watered = true

		water.visible = false


		call_deferred(
			"grow_into_tree"
		)

		return


	# =========================================
	# เคยรดน้ำแล้ว
	# =========================================

	if state == "watered":

		is_watered = true

		water.visible = true


		var now: float = (
			Time.get_unix_time_from_system()
		)


		# ครบเวลาระหว่างอยู่ Map อื่น
		if now >= grow_at:

			call_deferred(
				"grow_into_tree"
			)


		return


	# =========================================
	# ยังไม่เคยรด
	# =========================================

	is_watered = false

	grow_at = 0.0

	water.visible = false
