extends Node


# =====================================================
# QUEST STATES
# =====================================================

const NOT_STARTED := 0
const ACTIVE := 1
const READY_TO_TURN_IN := 2
const COMPLETED := 3


# =====================================================
# QUEST IDS
# =====================================================

const QUEST_REPAIR_CRAFT_TABLE := "repair_craft_table"


# =====================================================
# QUEST DATA
# =====================================================

var quest_states: Dictionary = {
	QUEST_REPAIR_CRAFT_TABLE: NOT_STARTED
}


# =====================================================
# รับเควส
# =====================================================

func start_quest(quest_id: String) -> void:
	if not quest_states.has(quest_id):
		quest_states[quest_id] = NOT_STARTED

	if quest_states[quest_id] != NOT_STARTED:
		return

	quest_states[quest_id] = ACTIVE

	print("QUEST STARTED: ", quest_id)


# =====================================================
# ตั้งว่า Objective เสร็จแล้ว
# =====================================================

func objective_complete(quest_id: String) -> void:
	if not quest_states.has(quest_id):
		return

	if quest_states[quest_id] != ACTIVE:
		return

	quest_states[quest_id] = READY_TO_TURN_IN

	print("QUEST READY: ", quest_id)


# =====================================================
# ส่งเควส
# =====================================================

func complete_quest(quest_id: String) -> void:
	if not quest_states.has(quest_id):
		return

	if quest_states[quest_id] != READY_TO_TURN_IN:
		return

	quest_states[quest_id] = COMPLETED

	print("QUEST COMPLETED: ", quest_id)


# =====================================================
# อ่านสถานะ
# =====================================================

func get_quest_state(quest_id: String) -> int:
	return quest_states.get(
		quest_id,
		NOT_STARTED
	)


# =====================================================
# เช็ก Objective ของเควสต่าง ๆ
# =====================================================

func update_quests() -> void:
	check_crafting_table_quest()


# =====================================================
# QUEST 1
# ซ่อมโต๊ะคราฟใน Village
# =====================================================

func check_crafting_table_quest() -> void:
	var quest_id := QUEST_REPAIR_CRAFT_TABLE

	if get_quest_state(quest_id) != ACTIVE:
		return


	# object_id ของโต๊ะคราฟ
	var repair_id := "village_crafting_table"

	if not global.repair_states.has(repair_id):
		return


	var data: Dictionary = global.repair_states[repair_id]

	var repaired: bool = data.get(
		"is_repaired",
		false
	)


	if repaired:
		objective_complete(quest_id)
