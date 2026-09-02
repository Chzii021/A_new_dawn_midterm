extends Node2D


# =====================================================
# ID
# =====================================================

@export_category("ID")

@export var house_id: String = "village_house_01"

@export_category("Quest")
@export var level_2_quest_id: String = ""

# =====================================================
# LEVEL 2 REQUIREMENTS
# =====================================================

@export_category("LV1 -> LV2")

@export var level_2_requirements: Array[CraftRequirement]


# =====================================================
# LEVEL 3 REQUIREMENTS
# =====================================================

@export_category("LV2 -> LV3")

@export var level_3_requirements: Array[CraftRequirement]


# =====================================================
# PLAYER
# =====================================================

var player: player_2 = null

var player_in_area: bool = false


# =====================================================
# HOUSE STATE
# =====================================================

# 1 = บ้านพัง
# 2 = ซ่อมระดับกลาง
# 3 = บ้านสมบูรณ์

var house_level: int = 1


# ของที่ใส่สำหรับ LV2
var delivered_level_2: Dictionary = {}


# ของที่ใส่สำหรับ LV3
var delivered_level_3: Dictionary = {}


# =====================================================
# NODES
# =====================================================

@onready var animated_sprite: AnimatedSprite2D = (
	$AnimatedSprite2D
)

@onready var repair_ui = (
	$RepairUI
)


# =====================================================
# READY
# =====================================================

func _ready() -> void:

	load_house_state()

	update_visual()


	if repair_ui != null:

		repair_ui.hide_panel()


# =====================================================
# PROCESS
# =====================================================

func _process(_delta: float) -> void:

	if not player_in_area:
		return


	# =========================================
	# LV3 สร้างเสร็จแล้ว
	# =========================================

	if house_level >= 3:

		if repair_ui != null:

			repair_ui.hide_panel()

		return


	# =========================================
	# อัปเดตป้าย
	# =========================================

	update_build_ui()


	# =========================================
	# กด Space
	# =========================================

	if Input.is_action_just_pressed(
		"interact"
	):

		add_materials()


# =====================================================
# PLAYER ENTER
# =====================================================

func _on_interactable_area_body_entered(
	body: Node2D
) -> void:

	if body is player_2:

		player = body

		player_in_area = true


		if house_level < 3:

			update_build_ui()


# =====================================================
# PLAYER EXIT
# =====================================================

func _on_interactable_area_body_exited(
	body: Node2D
) -> void:

	if body == player:

		player = null

		player_in_area = false


		if repair_ui != null:

			repair_ui.hide_panel()


# =====================================================
# GET CURRENT REQUIREMENTS
# =====================================================

func get_current_requirements() -> Array[CraftRequirement]:

	if house_level == 1:

		return level_2_requirements


	if house_level == 2:

		return level_3_requirements


	return []


# =====================================================
# GET CURRENT DELIVERED
# =====================================================

func get_current_delivered() -> Dictionary:

	if house_level == 1:

		return delivered_level_2


	if house_level == 2:

		return delivered_level_3


	return {}


# =====================================================
# ADD MATERIALS
# =====================================================

func add_materials() -> void:

	if player == null:
		return


	if player.inv == null:

		print(
			"ERROR: Player ไม่มี Inventory"
		)

		return


	if house_level >= 3:
		return


	var requirements: Array[CraftRequirement] = (
		get_current_requirements()
	)


	var delivered: Dictionary = (
		get_current_delivered()
	)


	var added_something: bool = false


	# =========================================
	# ใส่วัตถุดิบ
	# =========================================

	for requirement in requirements:

		if requirement == null:
			continue


		if requirement.item == null:
			continue


		var key: String = (
			requirement.item.resource_path
		)


		var current: int = (
			delivered.get(
				key,
				0
			)
		)


		var needed: int = (
			requirement.amount
			- current
		)


		# ครบแล้ว
		if needed <= 0:
			continue


		var player_amount: int = (
			player.inv.get_item_amount(
				requirement.item
			)
		)


		# ไม่มีของ
		if player_amount <= 0:
			continue


		# เอาเท่าที่ Player มี
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


	# =========================================
	# ส่ง Dictionary กลับ
	# =========================================

	if house_level == 1:

		delivered_level_2 = delivered


	elif house_level == 2:

		delivered_level_3 = delivered


	# =========================================
	# SAVE
	# =========================================

	save_house_state()

	update_build_ui()


	# =========================================
	# เช็กของครบ
	# =========================================

	if check_level_complete():

		upgrade_house()

	elif not added_something:

		print(
			"ยังไม่มีวัตถุดิบที่บ้านต้องการ"
		)


# =====================================================
# CHECK COMPLETE
# =====================================================

func check_level_complete() -> bool:

	var requirements: Array[CraftRequirement] = (
		get_current_requirements()
	)


	var delivered: Dictionary = (
		get_current_delivered()
	)


	for requirement in requirements:

		if requirement == null:
			continue


		if requirement.item == null:
			continue


		var key: String = (
			requirement.item.resource_path
		)


		var current: int = (
			delivered.get(
				key,
				0
			)
		)


		if current < requirement.amount:

			return false


	return true


# =====================================================
# UPGRADE HOUSE
# =====================================================
func upgrade_house() -> void:

	if house_level >= 3:
		return


	house_level += 1


	print(
		"HOUSE UPGRADE → LV",
		house_level
	)


	save_house_state()
	update_visual()


	# =========================================
	# QUEST : HOUSE LV2
	# =========================================

	if house_level == 2:

		if level_2_quest_id != "":

			QuestManager.objective_complete(
				level_2_quest_id
			)


	# =========================================
	# LV3 เสร็จสมบูรณ์
	# =========================================

	if house_level >= 3:

		if repair_ui != null:
			repair_ui.hide_panel()

		print("HOUSE COMPLETE!")

		return


	if player_in_area:
		update_build_ui()
# =====================================================
# UPDATE VISUAL
# =====================================================

func update_visual() -> void:

	match house_level:

		1:

			animated_sprite.play(
				"lv1"
			)


		2:

			animated_sprite.play(
				"lv2"
			)


		3:

			animated_sprite.play(
				"lv3"
			)


# =====================================================
# UPDATE BUILD UI
# =====================================================

func update_build_ui() -> void:

	if repair_ui == null:
		return


	if house_level >= 3:

		repair_ui.hide_panel()

		return


	var requirements: Array[CraftRequirement] = (
		get_current_requirements()
	)


	var delivered: Dictionary = (
		get_current_delivered()
	)


	var ui_requirements: Array = []


	for requirement in requirements:

		if requirement == null:
			continue


		if requirement.item == null:
			continue


		var key: String = (
			requirement.item.resource_path
		)


		var current: int = (
			delivered.get(
				key,
				0
			)
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


	var title: String = ""


	if house_level == 1:

		title = (
			"Upgrade House LV1 → LV2"
		)


	elif house_level == 2:

		title = (
			"Upgrade House LV2 → LV3"
		)


	repair_ui.show_repair(
		title,
		ui_requirements
	)


# =====================================================
# SAVE
# =====================================================

func save_house_state() -> void:

	global.house_states[house_id] = {

		"house_level":
			house_level,

		"delivered_level_2":
			delivered_level_2.duplicate(
				true
			),

		"delivered_level_3":
			delivered_level_3.duplicate(
				true
			)
	}


# =====================================================
# LOAD
# =====================================================

func load_house_state() -> void:

	# =========================================
	# ยังไม่เคยมีข้อมูล
	# =========================================

	if not global.house_states.has(
		house_id
	):

		house_level = 1

		delivered_level_2 = {}

		delivered_level_3 = {}

		save_house_state()

		return


	# =========================================
	# LOAD
	# =========================================

	var data: Dictionary = (
		global.house_states[house_id]
	)


	house_level = data.get(
		"house_level",
		1
	)


	delivered_level_2 = data.get(
		"delivered_level_2",
		{}
	).duplicate(true)


	delivered_level_3 = data.get(
		"delivered_level_3",
		{}
	).duplicate(true)
