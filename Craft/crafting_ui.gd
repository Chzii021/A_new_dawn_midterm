extends CanvasLayer


@export_category("Inventory")
@export var inv: Inv

@export_category("Craft Recipes")
@export var recipes: Array[CraftRecipe]

@export_category("UI")
@export var recipe_row_scene: PackedScene


@onready var root: Control = $Root

@onready var recipe_list: VBoxContainer = (
	$Root/CenterContainer/MenuRow/CraftPanel/Margin/VBox/RecipeScroll/RecipeList
)

@onready var close_button: Button = (
	$Root/CenterContainer/MenuRow/CraftPanel/Margin/VBox/TopBar/CloseButton
)


func _ready() -> void:
	root.visible = false

	close_button.pressed.connect(
		close_crafting
	)

	create_recipe_list()


func create_recipe_list() -> void:

	for child in recipe_list.get_children():
		child.queue_free()

	for recipe in recipes:

		var row = recipe_row_scene.instantiate()

		recipe_list.add_child(row)

		row.setup(
			recipe,
			inv
		)


func _unhandled_input(event: InputEvent) -> void:

	if event.is_action_pressed("openCraft"):

		toggle_crafting()


func toggle_crafting() -> void:

	# C เปิด/ปิดได้ทุกที่
	root.visible = not root.visible

	if root.visible:
		refresh()


func close_crafting() -> void:

	root.visible = false


func refresh() -> void:

	for child in recipe_list.get_children():

		if child.has_method("refresh"):

			child.refresh()
