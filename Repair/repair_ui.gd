extends Control

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/Title
@onready var requirement_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/RequirementList
@onready var hint_label: Label = $Panel/MarginContainer/VBoxContainer/HintLabel


func _ready() -> void:
	visible = false


func show_repair(
	title: String,
	requirements: Array
) -> void:

	title_label.text = title

	for child in requirement_list.get_children():
		child.queue_free()

	var all_complete: bool = true

	for requirement in requirements:

		var item_name: String = requirement.get("name", "Item")
		var current: int = requirement.get("current", 0)
		var required: int = requirement.get("required", 0)

		var label := Label.new()

		label.text = (
			item_name
			+ " "
			+ str(current)
			+ " / "
			+ str(required)
		)

		requirement_list.add_child(label)

		if current < required:
			all_complete = false


	if all_complete:
		hint_label.text = "Press Space to repair"
	else:
		hint_label.text = "Press Space to repair"

	visible = true


func hide_panel() -> void:
	visible = false
