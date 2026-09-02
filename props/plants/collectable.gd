extends StaticBody2D

@export var object_id: String = "_w_01"
@export var item: InvItem
@export var respawn_time: float = 60.0

var player = null
var player_in_area: bool = false
var collected: bool = false
var respawn_at: float = 0.0

var original_collision_layer: int
var original_collision_mask: int

@onready var interactable_area: Area2D = $interactable_area

func _ready() -> void:
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask
	load_state()

func _process(_delta: float) -> void:
	if collected:
		var now: float = Time.get_unix_time_from_system()
		if now >= respawn_at:
			respawn_item()
		return
	if player_in_area and Input.is_action_just_pressed("interact"):
		collect_item()

func _on_interactable_area_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player = body
		player_in_area = true

func _on_interactable_area_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_area = false
		player = null

func collect_item() -> void:
	if collected:
		return
	if player == null:
		return
	if item == null:
		print("ERROR: Item ยังไม่ได้กำหนด")
		return
	collected = true
	respawn_at = Time.get_unix_time_from_system() + respawn_time
	player.collect(item)
	hide_item()
	save_state()

func hide_item() -> void:
	visible = false

	player_in_area = false
	player = null

	interactable_area.set_deferred("monitoring", false)
	interactable_area.set_deferred("monitorable", false)

	collision_layer = 0
	collision_mask = 0

func respawn_item() -> void:
	collected = false
	respawn_at = 0.0

	visible = true

	# เปิด Area กลับมา
	interactable_area.set_deferred("monitoring", true)
	interactable_area.set_deferred("monitorable", true)

	# คืน Collision เดิม
	collision_layer = original_collision_layer
	collision_mask = original_collision_mask

	save_state()

	print("Respawned: ", object_id)

func save_state() -> void:
	global.collectible_states[object_id] = {
		"collected": collected,
		"respawn_at": respawn_at
	}

func load_state() -> void:

	# ยังไม่เคยเก็บ Object นี้
	if not global.collectible_states.has(object_id):
		save_state()
		return


	var data: Dictionary = global.collectible_states[object_id]

	collected = data.get("collected", false)
	respawn_at = data.get("respawn_at", 0.0)


	if collected:

		var now: float = Time.get_unix_time_from_system()

		# ครบเวลาแล้ว
		if now >= respawn_at:
			respawn_item()

		# ยังไม่ครบ
		else:
			hide_item()

			print(
				object_id,
				" respawn remaining: ",
				round(respawn_at - now),
				" sec"
			)
