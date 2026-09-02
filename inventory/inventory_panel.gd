extends PanelContainer

@onready var inv: Inv = preload(
	"res://inventory/playerinv.tres"
)

@onready var grid: GridContainer = (
	$MarginContainer/VBoxContainer/GridContainer
)

var slots: Array = []

func _ready() -> void:
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
