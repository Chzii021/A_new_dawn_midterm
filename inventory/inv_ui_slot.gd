extends Panel

var inv: Inv = null
var slot_index: int = -1

@onready var item_visual: TextureRect = $CenterContainer/item_display
@onready var amount_text: Label = $AmountMargin/Label
signal slot_pressed(slot_index: int)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	$CenterContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

	$AmountMargin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount_text.mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(_inv: Inv, _slot_index: int) -> void:
	inv = _inv
	slot_index = _slot_index

	refresh()

func refresh() -> void:
	if inv == null:
		return

	if slot_index < 0 or slot_index >= inv.slots.size():
		return

	update(inv.slots[slot_index])

func update(slot: InvSlot) -> void:

	if slot == null or slot.item == null:
		item_visual.texture = null
		item_visual.visible = false

		amount_text.text = ""
		amount_text.visible = false

		return

	item_visual.visible = true
	item_visual.texture = slot.item.texture

	if slot.amount > 1:
		amount_text.visible = true
		amount_text.text = str(slot.amount)

	else:
		amount_text.text = ""
		amount_text.visible = false

func _get_drag_data(_at_position: Vector2) -> Variant:
	if inv == null:
		return null

	if slot_index < 0 or slot_index >= inv.slots.size():
		return null

	var slot: InvSlot = inv.slots[slot_index]

	if slot == null or slot.item == null:
		return null

	var preview := TextureRect.new()
	preview.texture = slot.item.texture
	preview.custom_minimum_size = Vector2(20, 20)
	
	preview.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)
	preview.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	
	set_drag_preview(preview)

	return {
		"inventory": inv,
		"from_index": slot_index
	}

func _can_drop_data(
	_at_position: Vector2,
	data: Variant
) -> bool:

	if not data is Dictionary:
		return false

	if not data.has("inventory"):
		return false

	if not data.has("from_index"):
		return false


	# ต้องเป็น Inventory เดียวกัน
	if data["inventory"] != inv:
		return false


	return true

func _drop_data(
	_at_position: Vector2,
	data: Variant
) -> void:

	if inv == null:
		return


	var from_index: int = int(
		data["from_index"]
	)

	inv.swap_slots(
		from_index,
		slot_index
	)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				slot_pressed.emit(slot_index)
