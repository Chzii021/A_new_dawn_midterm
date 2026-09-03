extends PanelContainer

var recipe: CraftRecipe = null
var inv: Inv = null

@onready var item_icon: TextureRect = $Margin/HBox/ItemIcon
@onready var item_name: Label = $Margin/HBox/Info/ItemName
@onready var requirements_container: VBoxContainer = $Margin/HBox/Info/Requirements
@onready var craft_button: Button = $Margin/HBox/CraftButton

func _ready() -> void:
	var skin = preload("res://inventory/forest_ui_theme.gd")
	custom_minimum_size = Vector2(188, 35)
	scale = Vector2.ONE
	add_theme_stylebox_override("panel", skin.box(Color("233c2c"), Color("4e6040")))
	skin.margins($Margin, 2)
	item_icon.custom_minimum_size = Vector2(24, 24)
	item_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Margin/HBox.add_theme_constant_override("separation", 5)
	requirements_container.modulate = Color.WHITE
	requirements_container.add_theme_constant_override("separation", 0)
	craft_button.custom_minimum_size = Vector2(36, 20)
	craft_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	craft_button.add_theme_font_size_override("font_size", 7)


func setup(_recipe: CraftRecipe, _inv: Inv) -> void:
	recipe = _recipe
	inv = _inv

	if not craft_button.pressed.is_connected(craft):
		craft_button.pressed.connect(craft)

	if inv != null:
		if not inv.update.is_connected(refresh):
			inv.update.connect(refresh)

	refresh()
	
func refresh() -> void:
	if recipe == null:
		return

	if inv == null:
		return

	if recipe.result_item == null:
		return


	# รูปของที่จะได้
	item_icon.texture = recipe.result_item.texture


	# ชื่อ เช่น Axe x1
	item_name.text = (
		recipe.result_item.name
		+ " x"
		+ str(recipe.result_amount)
	)


	# ลบข้อความ Requirement เก่า
	for child in requirements_container.get_children():
		requirements_container.remove_child(child)
		child.queue_free()


	# สร้างข้อความ Requirement ใหม่
	for requirement in recipe.requirements:
		if requirement == null:
			continue

		if requirement.item == null:
			continue


		var current_amount: int = inv.get_item_amount(
			requirement.item
		)


		var label := Label.new()
		label.add_theme_font_size_override("font_size", 7)
		label.add_theme_color_override("font_color", Color("b7d38e") if current_amount >= requirement.amount else Color("d18d65"))

		label.text = (
			requirement.item.name
			+ "   "
			+ str(current_amount)
			+ "/"
			+ str(requirement.amount)
		)

		requirements_container.add_child(label)


	# ถ้าของไม่ครบ ปุ่ม Craft กดไม่ได้
	craft_button.disabled = (
	not can_craft()
	or not global.near_crafting_table
)
	craft_button.tooltip_text = "Stand near the crafting table" if not global.near_crafting_table else ("Craft item" if can_craft() else "Missing materials or inventory space")

func can_craft() -> bool:
	if recipe == null:
		return false

	if inv == null:
		return false

	if recipe.result_item == null:
		return false


	for requirement in recipe.requirements:
		if requirement == null:
			continue

		if requirement.item == null:
			continue


		var current_amount: int = inv.get_item_amount(
			requirement.item
		)


		if current_amount < requirement.amount:
			return false


	# เช็กว่ากระเป๋ามีที่ใส่ของที่คราฟไหม
	if not inv.can_insert(recipe.result_item):
		return false


	return true

func craft() -> void:

	# ========================================
	# ต้องอยู่ใกล้โต๊ะ Craft ก่อน
	# ========================================

	if not global.near_crafting_table:
		print("❌ ต้องยืนใกล้โต๊ะคราฟก่อน!")
		return


	# ========================================
	# เช็กวัตถุดิบ
	# ========================================

	if not can_craft():
		print("วัตถุดิบไม่พอ")
		return


	print("====================")
	print("CRAFT: ", recipe.result_item.name)


	# ========================================
	# หักวัตถุดิบ
	# ========================================

	for requirement in recipe.requirements:

		if requirement == null:
			continue

		if requirement.item == null:
			continue


		inv.remove_item(
			requirement.item,
			requirement.amount
		)


		print(
			"- ",
			requirement.item.name,
			" x",
			requirement.amount
		)


	# ========================================
	# เพิ่มของที่ Craft
	# ========================================

	inv.insert_amount(
		recipe.result_item,
		recipe.result_amount
	)


	print(
		"+ ",
		recipe.result_item.name,
		" x",
		recipe.result_amount
	)
	if recipe.quest_id_on_craft != "":
		QuestManager.objective_complete(
			recipe.quest_id_on_craft
		)

	print("====================")
	


	refresh()
