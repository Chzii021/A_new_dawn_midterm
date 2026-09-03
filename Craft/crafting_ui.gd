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
	_style_interface()
	root.visible = false

	close_button.pressed.connect(
		close_crafting
	)

	create_recipe_list()
	root.resized.connect(_fit_interface)
	$Root/CenterContainer/MenuRow.resized.connect(_fit_interface)
	_fit_interface.call_deferred()

func _fit_interface() -> void:
	var row := $Root/CenterContainer/MenuRow
	var room := root.size - Vector2(16, 16)
	var fit: float = minf(1.0, minf(room.x / maxf(row.size.x, 1), room.y / maxf(row.size.y, 1)))
	row.pivot_offset = row.size * 0.5
	row.scale = Vector2.ONE * maxf(fit, 0.1)

func _style_interface() -> void:
	var skin = preload("res://inventory/forest_ui_theme.gd")
	layer = 8
	root.theme = skin.create_theme()
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.03, 0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	root.move_child(shade, 0)
	var center := $Root/CenterContainer
	center.scale = Vector2.ONE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := $Root/CenterContainer/MenuRow
	row.add_theme_constant_override("separation", 6)
	var panel := $Root/CenterContainer/MenuRow/CraftPanel
	panel.custom_minimum_size = Vector2(214, 174)
	skin.margins(panel.get_node("Margin"), 5)
	var top := panel.get_node("Margin/VBox/TopBar")
	top.self_modulate = Color.WHITE
	top.get_node("Title").text = "WORKBENCH"
	top.get_node("Title").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.get_node("Title").add_theme_font_size_override("font_size", 11)
	close_button.modulate = Color.WHITE
	close_button.custom_minimum_size = Vector2(17, 17)
	var scroll := panel.get_node("Margin/VBox/RecipeScroll")
	scroll.custom_minimum_size = Vector2(194, 118)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	recipe_list.add_theme_constant_override("separation", 4)
	var help := Label.new()
	help.name = "CraftHint"
	help.text = "C CLOSE / CRAFT NEAR TABLE"
	help.add_theme_font_size_override("font_size", 7)
	help.modulate = Color("97af7a")
	panel.get_node("Margin/VBox").add_child(help)
	var trim := Control.new()
	trim.set_script(preload("res://inventory/forest_panel_trim.gd"))
	trim.caption = "WORKBENCH"
	panel.add_child(trim)
	top.get_node("Title").self_modulate.a = 0.0


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
