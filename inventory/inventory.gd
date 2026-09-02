extends Resource
class_name Inv

signal update

@export var slots: Array[InvSlot]

func insert(item: InvItem):
	var itemslots = slots.filter(func(slot): return slot.item == item)
	if !itemslots.is_empty():
		itemslots[0].amount += 1
	else:
		var emptyslots = slots.filter(func(slot): return slot.item == null)
		if !emptyslots.is_empty():
			emptyslots[0].item = item
			emptyslots[0].amount = 1
	update.emit()

func get_item_amount(item: InvItem) -> int:
	var total: int = 0

	for slot in slots:
		if slot.item == item:
			total += slot.amount

	return total


func remove_item(item: InvItem, amount: int) -> bool:
	if get_item_amount(item) < amount:
		return false

	var remaining: int = amount

	for slot in slots:
		if slot.item != item:
			continue

		var take: int = min(slot.amount, remaining)

		slot.amount -= take
		remaining -= take

		if slot.amount <= 0:
			slot.item = null
			slot.amount = 0

		if remaining <= 0:
			break

	update.emit()
	return true

func can_insert(item: InvItem) -> bool:
	for slot in slots:
		if slot == null:
			continue

		# มี item นี้อยู่แล้ว สามารถ stack ได้
		if slot.item == item:
			return true

		# มีช่องว่าง
		if slot.item == null:
			return true
	return false

func insert_amount(item: InvItem, amount: int) -> void:
	for i in range(amount):
		insert(item)

func replace_item(old_item: InvItem, new_item: InvItem) -> bool:
	if old_item == null or new_item == null:
		return false

	# หาช่องที่มีของเก่า
	var old_slot: InvSlot = null

	for slot in slots:
		if slot == null:
			continue

		if slot.item == old_item:
			old_slot = slot
			break

	# ไม่มี Bucket
	if old_slot == null:
		return false


	# ==========================================
	# ถ้ามี Bucket Water อยู่แล้ว
	# → เพิ่ม Stack เข้าไปได้เลย
	# ==========================================
	for slot in slots:
		if slot == null:
			continue

		if slot.item == new_item:
			old_slot.amount -= 1

			if old_slot.amount <= 0:
				old_slot.item = null
				old_slot.amount = 0

			slot.amount += 1

			update.emit()
			return true


	# ==========================================
	# ถ้า Bucket เหลือแค่ 1
	# → เปลี่ยนช่องเดิมเป็น Bucket Water เลย
	# ==========================================
	if old_slot.amount == 1:
		old_slot.item = new_item
		old_slot.amount = 1

		update.emit()
		return true


	# ==========================================
	# มี Bucket หลายอัน
	# → หาช่องว่างสำหรับ Bucket Water
	# ==========================================
	for slot in slots:
		if slot == null:
			continue

		if slot.item == null:
			old_slot.amount -= 1

			slot.item = new_item
			slot.amount = 1

			update.emit()
			return true


	print("Inventory เต็ม ไม่สามารถตักน้ำได้")
	return false

func swap_slots(from_index: int, to_index: int) -> void:

	if from_index < 0 or from_index >= slots.size():
		return

	if to_index < 0 or to_index >= slots.size():
		return

	if from_index == to_index:
		return


	var from_slot: InvSlot = slots[from_index]
	var to_slot: InvSlot = slots[to_index]


	if from_slot == null or to_slot == null:
		return


	var temp_item: InvItem = from_slot.item
	var temp_amount: int = from_slot.amount


	from_slot.item = to_slot.item
	from_slot.amount = to_slot.amount


	to_slot.item = temp_item
	to_slot.amount = temp_amount


	update.emit()
