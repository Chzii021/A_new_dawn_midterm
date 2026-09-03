extends PanelContainer

var recipe: CraftRecipe = null
var inv: Inv = null

@onready var item_icon: TextureRect = $Margin/HBox/ItemIcon
@onready var item_name: Label = $Margin/HBox/Info/ItemName
@onready var requirements_container: VBoxContainer = $Margin/HBox/Info/Requirements
@onready var craft_button: Button = $Margin/HBox/CraftButton


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

		label.text = (
			requirement.item.name
			+ "   "
			+ str(current_amount)
			+ "/"
			+ str(requirement.amount)
		)

		requirements_container.add_child(label)


	# ถ้าของไม่ครบ ปุ่ม Craft กดไม่ได้
	craft_button.disabled = not can_craft()

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
	if not can_craft():
		print("วัตถุดิบไม่พอ")
		return


	print("====================")
	print("CRAFT: ", recipe.result_item.name)


	# หักวัตถุดิบ
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


	# เพิ่มของที่คราฟเข้า Inventory
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

	print("====================")

	refresh()
