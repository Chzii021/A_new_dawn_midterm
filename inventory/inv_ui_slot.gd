extends Panel

var inv: Inv = null
var slot_index: int = -1
var selected: bool = false
var hovered: bool = false

@onready var item_visual: TextureRect = $CenterContainer/item_display
@onready var amount_text: Label = $AmountMargin/Label
signal slot_pressed(slot_index: int)

func _ready() -> void:
	theme = preload("res://inventory/forest_ui_theme.gd").create_theme()
	custom_minimum_size = Vector2(24, 24)
	scale = Vector2.ONE
	self_modulate = Color.WHITE
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	$Panel.hide()
	item_visual.custom_minimum_size = Vector2(17, 17)
	$AmountMargin.add_theme_constant_override("margin_top", 0)
	$AmountMargin.add_theme_constant_override("margin_right", 2)
	$AmountMargin.add_theme_constant_override("margin_bottom", 1)
	amount_text.add_theme_font_size_override("font_size", 7)
	amount_text.add_theme_color_override("font_color", Color("ffebad"))
	amount_text.add_theme_color_override("font_outline_color", Color("101b17"))
	amount_text.add_theme_constant_override("outline_size", 2)
	mouse_entered.connect(func(): hovered = true; queue_redraw())
	mouse_exited.connect(func(): hovered = false; queue_redraw())
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
	tooltip_text = slot.item.name.replace("_", " ").capitalize() if slot != null and slot.item != null else "Empty slot"
	if slot != null and slot.item != null and slot.item.healing_amount > 0:
		tooltip_text += "\nRight-click: eat (+%d HP)" % slot.item.healing_amount

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
	preview.custom_minimum_size = Vector2(22, 22)
	
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
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed and is_instance_valid(PlayerManager.player):
				PlayerManager.player.consume_inventory_slot(inv, slot_index)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				slot_pressed.emit(slot_index)

func set_selected(value: bool) -> void:
	selected = value
	modulate = Color.WHITE
	queue_redraw()

func _draw() -> void:
	var w := int(size.x)
	var h := int(size.y)
	draw_rect(Rect2(0, 0, w, h), Color("0b1713"))
	draw_rect(Rect2(1, 1, w - 2, h - 2), Color("d3b671") if selected or hovered else Color("705634"))
	draw_rect(Rect2(2, 2, w - 4, h - 4), Color("2e4732") if selected else Color("1c3026"))
	draw_rect(Rect2(3, 3, w - 6, 1), Color("111f19"))
	draw_rect(Rect2(3, h - 4, w - 6, 1), Color("43513a"))
	for x in [1, w - 3]:
		for y in [1, h - 3]:
			draw_rect(Rect2(x, y, 2, 2), Color("c2a66b"))
