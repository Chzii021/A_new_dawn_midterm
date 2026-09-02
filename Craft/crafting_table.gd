extends Node2D

signal repair_completed

@export var object_id: String = "broken_object_01"
@export_category("Quest")
@export var quest_id: String = ""

# =====================================================
# REPAIR
# =====================================================

@export_category("Repair")
@export var repair_title: String = "ซ่อมสิ่งของ"
@export var requirements: Array[CraftRequirement]


# =====================================================
# PLAYER
# =====================================================

var player: player_2 = null
var player_in_area: bool = false


# =====================================================
# STATE
# =====================================================

var is_repaired: bool = false

# จำนวนของที่ใส่ไปแล้ว
var delivered: Dictionary = {}


# =====================================================
# NODES
# =====================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var repair_ui = $RepairUI


# =====================================================
# READY
# =====================================================

func _ready() -> void:
	load_repair_state()
	update_visual()

	if repair_ui != null:
		repair_ui.hide_panel()


# =====================================================
# PROCESS
# =====================================================

func _process(_delta: float) -> void:
	if not player_in_area:
		return


	# ถ้ายังพังอยู่
	if not is_repaired:
		update_repair_ui()


	if Input.is_action_just_pressed("interact"):

		# ยังพังอยู่ → ใส่วัตถุดิบ
		if not is_repaired:
			add_materials()

		# ซ่อมแล้ว → ใช้งาน
		else:
			use_object()


# =====================================================
# PLAYER เข้าใกล้
# =====================================================
func _on_interactable_area_body_entered(body: Node2D) -> void:

	if body is player_2:

		player = body
		player_in_area = true


		# =====================================
		# โต๊ะซ่อมแล้ว → อนุญาตให้ Craft
		# =====================================

		if is_repaired:

			global.near_crafting_table = true

			print("อยู่ใกล้ Crafting Table → Craft ได้")


		# =====================================
		# โต๊ะยังพัง
		# =====================================

		else:

			global.near_crafting_table = false

			show_repair_ui()
# =====================================================
# PLAYER ออกจากพื้นที่
# =====================================================
func _on_interactable_area_body_exited(body: Node2D) -> void:

	if body == player:

		player = null
		player_in_area = false


		# ออกจากโต๊ะ → Craft ไม่ได้
		global.near_crafting_table = false


		if repair_ui != null:
			repair_ui.hide_panel()


		print("ออกจาก Crafting Table → Craft ไม่ได้")
# =====================================================
# ใส่วัตถุดิบจาก Inventory
# =====================================================

func add_materials() -> void:
	if player == null:
		return


	if player.inv == null:
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


		var player_amount: int = (
			player.inv.get_item_amount(
				requirement.item
			)
		)


		# Player ไม่มีของชิ้นนี้
		if player_amount <= 0:
			continue


		# ใส่เท่าที่มี แต่ไม่เกินที่ต้องการ
		var amount_to_add: int = min(
			needed,
			player_amount
		)


		var removed: bool = (
			player.inv.remove_item(
				requirement.item,
				amount_to_add
			)
		)


		if removed:
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


	save_repair_state()

	update_repair_ui()


	# =========================================
	# ของครบ → ซ่อมเสร็จ
	# =========================================

	if check_repair_complete():
		complete_repair()

	elif not added_something:
		print("ยังไม่มีวัตถุดิบที่ต้องการ")


# =====================================================
# เช็กว่าของครบหรือยัง
# =====================================================

func check_repair_complete() -> bool:

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


		if current < requirement.amount:
			return false


	return true


# =====================================================
# ซ่อมเสร็จ
# =====================================================
func complete_repair() -> void:

	if is_repaired:
		return

	is_repaired = true

	save_repair_state()
	update_visual()

	if repair_ui != null:
		repair_ui.hide_panel()

	repair_completed.emit()
	if player_in_area:
		global.near_crafting_table = true

	print("REPAIR COMPLETE!")
	print("Quest ID = ", quest_id)


	# =========================================
	# แจ้ง QuestManager ว่าซ่อมสำเร็จแล้ว
	# =========================================

	if quest_id != "":

		QuestManager.objective_complete(
			quest_id
		)

	else:

		print("❌ Object นี้ยังไม่ได้ตั้ง Quest ID")
# =====================================================
# เปลี่ยนภาพ
# =====================================================

func update_visual() -> void:

	if is_repaired:

		animated_sprite.play(
			"fixed"
		)

	else:

		animated_sprite.play(
			"broken"
		)


# =====================================================
# ใช้งานหลังซ่อมแล้ว
# =====================================================

func use_object() -> void:

	if not is_repaired:
		return


	print("ใช้งาน Object ได้แล้ว!")


	# ใส่ความสามารถของ Object ตรงนี้


# =====================================================
# แสดง Repair UI
# =====================================================

func show_repair_ui() -> void:

	if repair_ui == null:
		return


	if is_repaired:
		repair_ui.hide_panel()
		return


	update_repair_ui()


# =====================================================
# อัปเดตข้อมูลใน Repair UI
# =====================================================

func update_repair_ui() -> void:

	if repair_ui == null:
		return


	if is_repaired:
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


		# จำนวนที่ "ใส่เข้าไปแล้ว"
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

func save_repair_state() -> void:

	global.repair_states[object_id] = {

		"is_repaired":
			is_repaired,

		"delivered":
			delivered.duplicate(true)
	}


# =====================================================
# LOAD
# =====================================================

func load_repair_state() -> void:

	if not global.repair_states.has(
		object_id
	):

		save_repair_state()
		return


	var data: Dictionary = (
		global.repair_states[object_id]
	)


	is_repaired = data.get(
		"is_repaired",
		false
	)


	delivered = data.get(
		"delivered",
		{}
	).duplicate(true)
