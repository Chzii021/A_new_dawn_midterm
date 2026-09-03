extends PanelContainer

@onready var inv: Inv = preload(
	"res://inventory/playerinv.tres"
)

@onready var grid: GridContainer = (
	$MarginContainer/VBoxContainer/GridContainer
)

var slots: Array = []

func _ready() -> void:
	var skin = preload("res://inventory/forest_ui_theme.gd")
	theme = skin.create_theme()
	custom_minimum_size = Vector2(128, 174)
	skin.margins($MarginContainer, 5)
	$MarginContainer/VBoxContainer.add_theme_constant_override("separation", 6)
	$MarginContainer/VBoxContainer/Title.text = "SATCHEL"
	$MarginContainer/VBoxContainer/Title.add_theme_font_size_override("font_size", 11)
	grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	var note := Label.new()
	note.text = "12 SLOTS\nDRAG TO REARRANGE\n1-4 QUICK SELECT"
	note.add_theme_font_size_override("font_size", 7)
	note.modulate = Color("97af7a")
	$MarginContainer/VBoxContainer.add_child(note)
	var trim := Control.new()
	trim.set_script(preload("res://inventory/forest_panel_trim.gd"))
	trim.caption = "SATCHEL"
	add_child(trim)
	$MarginContainer/VBoxContainer/Title.self_modulate.a = 0.0
	slots = grid.get_children()
	if not inv.update.is_connected(update_slots):
		inv.update.connect(update_slots)
	setup_slots()

func setup_slots() -> void:
	var count: int = min(
		inv.slots.size(),
		slots.size()
	)

	for i in range(count):
		if slots[i].has_method("setup"):
			slots[i].setup(
				inv,
				i
			)
	update_slots()

func update_slots() -> void:

	var count: int = min(
		inv.slots.size(),
		slots.size()
	)
	for i in range(count):
		if slots[i].has_method("update"):
			slots[i].update(
				inv.slots[i]
			)
