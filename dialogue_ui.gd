extends CanvasLayer


signal answer_selected(answer: bool)
signal dialogue_closed


@onready var root: Control = $Root

@onready var portrait: TextureRect = (
	$Root/DialoguePanel/MarginContainer/HBoxContainer/Portrait
)

@onready var npc_name_label: Label = (
	$Root/DialoguePanel/MarginContainer/HBoxContainer/VBoxContainer/NPCName
)

@onready var dialogue_text: Label = (
	$Root/DialoguePanel/MarginContainer/HBoxContainer/VBoxContainer/DialogueText
)

@onready var yes_button: Button = (
	$Root/DialoguePanel/MarginContainer/HBoxContainer/VBoxContainer/ButtonRow/YesButton
)

@onready var no_button: Button = (
	$Root/DialoguePanel/MarginContainer/HBoxContainer/VBoxContainer/ButtonRow/NoButton
)

@onready var next_button: Button = (
	$Root/DialoguePanel/MarginContainer/HBoxContainer/VBoxContainer/ButtonRow/NextButton
)


func _ready() -> void:

	root.visible = false

	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)
	next_button.pressed.connect(_on_next_pressed)


# =====================================================
# คำถามแบบ มี ตกลง / ไม่
# =====================================================

func ask(
	npc_name: String,
	text: String,
	npc_portrait: Texture2D
) -> bool:

	global.dialogue_open = true

	root.visible = true

	npc_name_label.text = npc_name
	dialogue_text.text = text
	portrait.texture = npc_portrait

	yes_button.visible = true
	no_button.visible = true
	next_button.visible = false


	var answer: bool = await answer_selected

	return answer


# =====================================================
# ข้อความธรรมดา มีปุ่ม ต่อไป
# =====================================================

func message(
	npc_name: String,
	text: String,
	npc_portrait: Texture2D
) -> void:

	global.dialogue_open = true

	root.visible = true

	npc_name_label.text = npc_name
	dialogue_text.text = text
	portrait.texture = npc_portrait

	yes_button.visible = false
	no_button.visible = false
	next_button.visible = true


	await dialogue_closed


# =====================================================
# BUTTONS
# =====================================================

func _on_yes_pressed() -> void:

	root.visible = false
	global.dialogue_open = false

	answer_selected.emit(true)


func _on_no_pressed() -> void:

	root.visible = false
	global.dialogue_open = false

	answer_selected.emit(false)


func _on_next_pressed() -> void:

	root.visible = false
	global.dialogue_open = false

	dialogue_closed.emit()
