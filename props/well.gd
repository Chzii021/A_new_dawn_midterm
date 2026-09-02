extends StaticBody2D


# =====================================================
# ID
# =====================================================

@export_category("ID")
@export var well_id: String = "world_well_01"


# =====================================================
# REPAIR
# =====================================================

@export_category("Repair")
@export var repair_title: String = "ซ่อมบ่อน้ำ"
@export var requirements: Array[CraftRequirement]


# =====================================================
# BUCKET ITEMS
# =====================================================

@export_category("Bucket Items")
@export var empty_bucket: InvItem
@export var water_bucket: InvItem


# =====================================================
# WELL
# =====================================================

@export_category("Well")
@export var max_uses: int = 20
@export var refill_time: float = 30.0


# =====================================================
# STATE
# =====================================================

# broke / well / dry
var well_state: String = "broke"

var current_uses: int = 0
var refill_at: float = 0.0

# จำนวนวัสดุที่ใส่เข้ามาแล้ว
var delivered: Dictionary = {}


# =====================================================
# PLAYER
# =====================================================

var player_in_area: bool = false
var player: player_2 = null


# =====================================================
# NODES
# =====================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var repair_ui: Control = $RepairUI


# =====================================================
# READY
# =====================================================

func _ready() -> void:
	load_well_state()
	update_visual()

	if repair_ui != null:
		repair_ui.hide_panel()


# =====================================================
# PROCESS
# =====================================================

func _process(_delta: float) -> void:

	# =========================================
	# บ่อแห้ง → เช็กเวลาฟื้น
	# =========================================

	if well_state == "dry":

		var now: float = Time.get_unix_time_from_system()

		if now >= refill_at:
			refill_well()


	# =========================================
	# Player ไม่ได้อยู่ใกล้
	# =========================================

	if not player_in_area:
		return


	# =========================================
	# ถ้ายังพังอยู่
	# อัปเดต UI
	# =========================================

	if well_state == "broke":
		update_repair_ui()


	# =========================================
	# กดใช้งาน
	# =========================================

	if Input.is_action_just_pressed("interact"):

		match well_state:

			"broke":
				add_repair_materials()

			"well":
				fill_bucket()

			"dry":
				print("บ่อน้ำแห้ง ต้องรออีกสักพัก")


# =====================================================
# ใส่วัตถุดิบสำหรับซ่อม
# =====================================================

func add_repair_materials() -> void:

	var target_player: player_2 = PlayerManager.player

	if target_player == null:
		print("ERROR: Player not found")
		return

	if target_player.inv == null:
		print("ERROR: Player ไม่มี Inventory")
		return


	var added_something: bool = false


	for requirement in requirements:

		if requirement == null:
			continue

		if requirement.item == null:
			continue


		var key: String = requirement.item.resource_path

		var current: int = delivered.get(
			key,
			0
		)

		var needed: int = (
			requirement.amount
			- current
		)


		# ของชนิดนี้ครบแล้ว
		if needed <= 0:
			continue


		# จำนวนที่ Player มี
		var player_amount: int = (
			target_player.inv.get_item_amount(
				requirement.item
			)
		)


		if player_amount <= 0:
			continue


		# ใส่เท่าที่มี แต่ไม่เกินจำนวนที่ต้องการ
		var amount_to_add: int = min(
			needed,
			player_amount
		)


		var success: bool = (
			target_player.inv.remove_item(
				requirement.item,
				amount_to_add
			)
		)


		if success:

			delivered[key] = (
				current
				+ amount_to_add
			)

			added_something = true


			print(
				requirement.item.name,
				" ",
				delivered[key],
				"/",
				requirement.amount
			)


	save_well_state()

	update_repair_ui()


	# =========================================
	# ของครบทั้งหมด
	# =========================================

	if check_repair_complete():

		complete_repair()

	elif not added_something:

		print("ยังไม่มีวัตถุดิบที่ต้องการ")


# =====================================================
# เช็กว่าของซ่อมครบหรือยัง
# =====================================================

func check_repair_complete() -> bool:

	for requirement in requirements:

		if requirement == null:
			continue

		if requirement.item == null:
			continue


		var key: String = requirement.item.resource_path

		var current: int = delivered.get(
			key,
			0
		)


		if current < requirement.amount:
			return false


	return true


# =====================================================
# ซ่อมบ่อน้ำเสร็จ
# =====================================================

func complete_repair() -> void:

	if well_state != "broke":
		return


	well_state = "well"

	current_uses = 0
	refill_at = 0.0


	update_visual()

	save_well_state()


	if repair_ui != null:
		repair_ui.hide_panel()
	
	QuestManager.objective_complete("quest_04")

	print("ซ่อมบ่อน้ำสำเร็จ!")


# =====================================================
# ตักน้ำ
# =====================================================

func fill_bucket() -> void:

	if well_state != "well":
		return


	var target_player: player_2 = PlayerManager.player


	if target_player == null:
		return


	if target_player.inv == null:
		return


	if empty_bucket == null:
		print("ERROR: ยังไม่ได้กำหนด bucket.tres")
		return


	if water_bucket == null:
		print("ERROR: ยังไม่ได้กำหนด bucket_water.tres")
		return


	# =========================================
	# เช็ก Bucket เปล่า
	# =========================================

	var empty_amount: int = (
		target_player.inv.get_item_amount(
			empty_bucket
		)
	)


	if empty_amount <= 0:

		print("ไม่มี Bucket เปล่า")

		return


	# =========================================
	# Bucket → Bucket Water
	# =========================================

	var success: bool = (
		target_player.inv.replace_item(
			empty_bucket,
			water_bucket
		)
	)


	if not success:

		print("ไม่สามารถตักน้ำได้")

		return


	# =========================================
	# ตักสำเร็จ
	# =========================================

	current_uses += 1


	print(
		"ตักน้ำสำเร็จ ",
		current_uses,
		"/",
		max_uses
	)


	# =========================================
	# ครบจำนวนครั้ง
	# =========================================

	if current_uses >= max_uses:
		make_dry()


	save_well_state()


# =====================================================
# บ่อแห้ง
# =====================================================

func make_dry() -> void:

	well_state = "dry"

	refill_at = (
		Time.get_unix_time_from_system()
		+ refill_time
	)


	update_visual()

	save_well_state()


	print(
		"บ่อน้ำแห้ง! รอ ",
		refill_time,
		" วินาที"
	)


# =====================================================
# น้ำกลับมา
# =====================================================

func refill_well() -> void:

	if well_state != "dry":
		return


	well_state = "well"

	current_uses = 0
	refill_at = 0.0


	update_visual()

	save_well_state()


	print("บ่อน้ำมีน้ำอีกครั้ง!")


# =====================================================
# VISUAL
# =====================================================

func update_visual() -> void:

	match well_state:

		"broke":

			animated_sprite.play(
				"broke"
			)

		"well":

			animated_sprite.play(
				"well"
			)

		"dry":

			animated_sprite.play(
				"well_dry"
			)


# =====================================================
# PLAYER ENTER
# =====================================================

func _on_interactable_area_body_entered(
	body: Node2D
) -> void:

	if body is player_2:

		player = body
		player_in_area = true


		if well_state == "broke":
			show_repair_ui()


# =====================================================
# PLAYER EXIT
# =====================================================

func _on_interactable_area_body_exited(
	body: Node2D
) -> void:

	if body == player:

		player_in_area = false
		player = null


		if repair_ui != null:
			repair_ui.hide_panel()


# =====================================================
# แสดง Repair UI
# =====================================================

func show_repair_ui() -> void:

	if repair_ui == null:
		return


	if well_state != "broke":

		repair_ui.hide_panel()

		return


	update_repair_ui()


# =====================================================
# อัปเดต Repair UI
# =====================================================

func update_repair_ui() -> void:

	if repair_ui == null:
		return


	if well_state != "broke":

		repair_ui.hide_panel()

		return


	var ui_requirements: Array = []


	for requirement in requirements:

		if requirement == null:
			continue

		if requirement.item == null:
			continue


		var key: String = (
			requirement.item.resource_path
		)


		var current: int = delivered.get(
			key,
			0
		)


		ui_requirements.append(
			{
				"name":
					requirement.item.name,

				"current":
					current,

				"required":
					requirement.amount
			}
		)


	repair_ui.show_repair(
		repair_title,
		ui_requirements
	)


# =====================================================
# SAVE
# =====================================================

func save_well_state() -> void:

	global.well_states[well_id] = {

		"well_state":
			well_state,

		"current_uses":
			current_uses,

		"refill_at":
			refill_at,

		"delivered":
			delivered.duplicate(true)
	}


# =====================================================
# LOAD
# =====================================================

func load_well_state() -> void:

	# =========================================
	# ยังไม่มีข้อมูล
	# =========================================

	if not global.well_states.has(
		well_id
	):

		well_state = "broke"

		current_uses = 0

		refill_at = 0.0

		delivered = {}


		save_well_state()

		return


	# =========================================
	# โหลดข้อมูล
	# =========================================

	var data: Dictionary = (
		global.well_states[well_id]
	)


	well_state = data.get(
		"well_state",
		"broke"
	)


	current_uses = data.get(
		"current_uses",
		0
	)


	refill_at = data.get(
		"refill_at",
		0.0
	)


	delivered = data.get(
		"delivered",
		{}
	).duplicate(true)


	# =========================================
	# ถ้าบ่อแห้งแล้วครบเวลา
	# ระหว่างอยู่แมพอื่น
	# =========================================

	if well_state == "dry":

		var now: float = (
			Time.get_unix_time_from_system()
		)


		if now >= refill_at:

			well_state = "well"

			current_uses = 0

			refill_at = 0.0


			save_well_state()
