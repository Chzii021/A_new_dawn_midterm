extends CanvasLayer

@onready var inv: Inv = preload("res://inventory/playerinv.tres")

@onready var hotbar: HBoxContainer = $Hotbar

var slots: Array = []

var selected_index: int = 0

const HOTBAR_SIZE: int = 4


func _ready() -> void:
	slots = hotbar.get_children()

	if not inv.update.is_connected(update_hotbar):
		inv.update.connect(update_hotbar)

	setup_hotbar()

	select_slot(0)


func setup_hotbar() -> void:
	var count: int = min(
		HOTBAR_SIZE,
		slots.size(),
		inv.slots.size()
	)

	for i in range(count):
		var slot_ui = slots[i]

		# Hotbar ช่อง 0 = Inventory ช่อง 0
		# Hotbar ช่อง 1 = Inventory ช่อง 1
		slot_ui.setup(inv, i)

		if slot_ui.has_signal("slot_pressed"):
			slot_ui.slot_pressed.connect(_on_slot_pressed)

	update_hotbar()


func update_hotbar() -> void:
	var count: int = min(
		HOTBAR_SIZE,
		slots.size(),
		inv.slots.size()
	)

	for i in range(count):
		slots[i].update(inv.slots[i])

	# ถ้าของในช่องที่เลือกเปลี่ยน
	# ให้ Effect เปลี่ยนตามด้วย
	apply_selected_item()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("hotbar_1"):
		select_slot(0)

	elif Input.is_action_just_pressed("hotbar_2"):
		select_slot(1)

	elif Input.is_action_just_pressed("hotbar_3"):
		select_slot(2)

	elif Input.is_action_just_pressed("hotbar_4"):
		select_slot(3)


func _on_slot_pressed(index: int) -> void:
	select_slot(index)


func select_slot(index: int) -> void:
	if index < 0 or index >= HOTBAR_SIZE:
		return

	selected_index = index

	update_selection_visual()

	apply_selected_item()


func apply_selected_item() -> void:
	if selected_index < 0:
		return

	if selected_index >= inv.slots.size():
		return

	var slot: InvSlot = inv.slots[selected_index]

	if slot == null:
		return

	var selected_item: InvItem = slot.item

	var player = PlayerManager.player

	if player == null:
		return

	if player.has_method("equip_item"):
		player.equip_item(selected_item)


func update_selection_visual() -> void:
	for i in range(slots.size()):

		if i == selected_index:
			slots[i].modulate = Color(1.0, 1.0, 0.65)

		else:
			slots[i].modulate = Color.WHITE
