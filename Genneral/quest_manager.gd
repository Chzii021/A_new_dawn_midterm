extends Node
signal quest_state_changed


const NOT_STARTED := 0
const ACTIVE := 1
const READY_TO_TURN_IN := 2
const COMPLETED := 3


# =====================================================
# QUEST LIST
# =====================================================

var quests: Array[Dictionary] = [

	# =================================================
	# QUEST 1 : ซ่อมโต๊ะ Craft
	# =================================================

	{
		"id": "repair_craft_table",

		"start_text":
			"The crafting table in the village is broken. Could you please fix it?",

		"active_text":
			"Please repair the crafting table.",

		"complete_text":
			"Excellent! The crafting table is working again!",

		"target": 1
	},


	# =================================================
	# QUEST 2 : ตัดต้นไม้ตาย 5 ต้น
	# =================================================

	{
		"id": "cut_dead_trees",

		"start_text":
			"There are a lot of dead trees in the village, could you please cut them down?",

		"active_text":
			"Craft an axe at the crafting table, then go and cut down 5 dead trees.",

		"complete_text":
			"Excellent! You're awesome!",

		"target": 5
	},


	# =================================================
	# QUEST 3 : รดน้ำต้นกล้า 5 ต้น
	# =================================================

	{
		"id": "quest_03",

		"start_text":
			"Craft a bucket at the crafting table and water the seedlings.",

		"active_text":
			"Please water the 5 seedlings in the village.",

		"complete_text":
			"That's fantastic! Thank you!",

		"target": 5
	},


	# =================================================
	# QUEST 4 : ซ่อมบ่อน้ำ
	# =================================================

	{
		"id": "quest_04",

		"start_text":
			"The village well is broken, so the villagers have no water to use.",

		"active_text":
			"Please fix the well.",

		"complete_text":
			"Thank you!",

		"target": 1
	},
	{
		"id": "upgrade_grandma_house_lv2",

		"start_text":
			"My house is still damaged. Could you help repair it?",

		"active_text":
			"Please upgrade my house to level 2.",

		"complete_text":
			"Wonderful! My house looks much better now. Thank you!",

		"target": 1
	},

	{
		"id": "craft_sword",

		"start_text":
			"You should have something to protect village.",

		"active_text":
			"Craft a sword at the crafting table.",

		"complete_text":
			"Excellent! Now you can fight against the CanKaNuayKongTuayTan!",

		"target": 1
	}
]


# =====================================================
# STATE
# =====================================================

var quest_states: Dictionary = {}

var quest_progress: Dictionary = {}

# เก็บ ID ของ Object ที่เคยนับแล้ว
# ป้องกันต้นเดิมถูกนับซ้ำ
var counted_objects: Dictionary = {}


var current_quest_index: int = 0


# =====================================================
# READY
# =====================================================

func _ready() -> void:

	for quest in quests:

		var quest_id: String = quest["id"]

		if not quest_states.has(quest_id):
			quest_states[quest_id] = NOT_STARTED

		if not quest_progress.has(quest_id):
			quest_progress[quest_id] = 0

		if not counted_objects.has(quest_id):
			counted_objects[quest_id] = {}


func get_save_data() -> Dictionary:
	return {
		"current_index": current_quest_index,
		"states": quest_states.duplicate(true),
		"progress": quest_progress.duplicate(true),
		"counted_objects": counted_objects.duplicate(true)
	}


func load_save_data(data: Dictionary) -> void:
	current_quest_index = clampi(int(data.get("current_index", 0)), 0, quests.size())
	quest_states = (data.get("states", {}) as Dictionary).duplicate(true)
	quest_progress = (data.get("progress", {}) as Dictionary).duplicate(true)
	counted_objects = (data.get("counted_objects", {}) as Dictionary).duplicate(true)
	_ensure_quest_defaults()
	quest_state_changed.emit()


func reset_progress() -> void:
	current_quest_index = 0
	quest_states.clear()
	quest_progress.clear()
	counted_objects.clear()
	_ensure_quest_defaults()
	quest_state_changed.emit()


func _ensure_quest_defaults() -> void:
	for quest in quests:
		var quest_id: String = quest["id"]
		if not quest_states.has(quest_id):
			quest_states[quest_id] = NOT_STARTED
		if not quest_progress.has(quest_id):
			quest_progress[quest_id] = 0
		if not counted_objects.has(quest_id):
			counted_objects[quest_id] = {}


# =====================================================
# GET CURRENT QUEST
# =====================================================

func get_current_quest() -> Dictionary:

	if current_quest_index >= quests.size():
		return {}

	return quests[current_quest_index]


func get_current_quest_id() -> String:

	var quest: Dictionary = get_current_quest()

	if quest.is_empty():
		return ""

	return quest["id"]


# =====================================================
# GET STATE
# =====================================================

func get_quest_state(
	quest_id: String
) -> int:

	return quest_states.get(
		quest_id,
		NOT_STARTED
	)


# =====================================================
# GET PROGRESS
# =====================================================

func get_progress(
	quest_id: String
) -> int:

	return quest_progress.get(
		quest_id,
		0
	)


func get_target(
	quest_id: String
) -> int:

	for quest in quests:

		if quest["id"] == quest_id:
			return quest.get(
				"target",
				1
			)

	return 1


# =====================================================
# START QUEST
# =====================================================

func start_current_quest() -> void:

	var quest: Dictionary = get_current_quest()

	if quest.is_empty():
		return


	var quest_id: String = quest["id"]


	if get_quest_state(quest_id) != NOT_STARTED:
		return


	quest_states[quest_id] = ACTIVE

	quest_progress[quest_id] = 0

	counted_objects[quest_id] = {}


	print(
		"QUEST STARTED: ",
		quest_id
	)


# =====================================================
# เพิ่ม Progress แบบปกติ
# =====================================================

func add_progress(
	quest_id: String,
	amount: int = 1
) -> void:

	# ต้องเป็น Quest ที่กำลังทำ
	if get_current_quest_id() != quest_id:
		return


	if get_quest_state(quest_id) != ACTIVE:
		return


	var target: int = get_target(
		quest_id
	)


	var current: int = get_progress(
		quest_id
	)


	current += amount

	current = min(
		current,
		target
	)


	quest_progress[quest_id] = current


	print(
		"QUEST PROGRESS: ",
		quest_id,
		" ",
		current,
		"/",
		target
	)


	# ครบ
	if current >= target:

		objective_complete(
			quest_id
		)


# =====================================================
# เพิ่ม Progress แบบ Object ไม่ซ้ำ
# =====================================================

func add_unique_progress(
	quest_id: String,
	object_id: String
) -> void:

	if object_id == "":
		return


	# ต้องเป็น Quest ปัจจุบัน
	if get_current_quest_id() != quest_id:
		return


	# ต้อง Active
	if get_quest_state(quest_id) != ACTIVE:
		return


	if not counted_objects.has(
		quest_id
	):
		counted_objects[quest_id] = {}


	var objects: Dictionary = (
		counted_objects[quest_id]
	)


	# Object นี้เคยนับแล้ว
	if objects.has(object_id):

		print(
			"Already counted: ",
			object_id
		)

		return


	# จำ Object นี้
	objects[object_id] = true

	counted_objects[quest_id] = objects


	# +1
	add_progress(
		quest_id,
		1
	)


# =====================================================
# OBJECTIVE COMPLETE
# =====================================================

func objective_complete(
	quest_id: String
) -> void:

	if get_current_quest_id() != quest_id:
		return


	if not quest_states.has(quest_id):
		return


	if quest_states[quest_id] != ACTIVE:
		return


	quest_states[quest_id] = (
		READY_TO_TURN_IN
	)


	print(
		"QUEST READY: ",
		quest_id
	)


# =====================================================
# COMPLETE QUEST
# =====================================================

func complete_current_quest() -> void:

	var quest: Dictionary = (
		get_current_quest()
	)


	if quest.is_empty():
		return


	var quest_id: String = quest["id"]


	if (
		get_quest_state(quest_id)
		!= READY_TO_TURN_IN
	):
		return


	# จบถาวร
	quest_states[quest_id] = COMPLETED


	print(
		"QUEST COMPLETED: ",
		quest_id
	)


	# =========================================
	# ไป Quest ต่อไป
	# =========================================

	current_quest_index += 1
	quest_state_changed.emit()


	if current_quest_index < quests.size():

		print(
			"NEXT QUEST: ",
			get_current_quest_id()
		)

	else:

		print(
			"ALL QUESTS COMPLETED"
		)
