extends StaticBody2D

@export_category("ID")
@export var pond_id: String = "world_pond_01"

@export_category("Items")
@export var empty_bucket: InvItem
@export var water_bucket: InvItem

@export_category("Water")
@export var max_uses: int = 5
@export var refill_time: float = 120.0

@export_category("Animation")
@export var water_animation: String = "water"
@export var dry_animation: String = "dry"

var player: player_2 = null
var player_in_area: bool = false

var uses: int = 0
var is_dry: bool = false
var refill_at: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	load_pond_state()
	update_animation()


func _process(_delta: float) -> void:

	# ==========================================
	# บ่อน้ำแห้ง
	# ==========================================
	if is_dry:
		var now: float = Time.get_unix_time_from_system()

		if now >= refill_at:
			refill_pond()

		return


	# ==========================================
	# Player อยู่ใกล้ + กด Space
	# ==========================================
	if player_in_area:
		if Input.is_action_just_pressed("interact"):
			fill_bucket()


# =====================================================
# Player เข้าใกล้บ่อน้ำ
# =====================================================

func _on_interact_area_body_entered(body: Node2D) -> void:
	if body is player_2:
		player = body
		player_in_area = true


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		player_in_area = false

func fill_bucket() -> void:# ตักน้ำ
	if is_dry:
		print("บ่อน้ำแห้ง")
		return

	if player == null:
		return

	# เช็กว่ามี Bucket เปล่า
	var bucket_amount: int = player.inv.get_item_amount(
		empty_bucket
	)

	if bucket_amount <= 0:
		print("ไม่มีถังเปล่า")
		return
	else:
		audio.play()
		var success: bool = player.inv.replace_item(
			empty_bucket,
			water_bucket
		)
		if not success:
			return

		uses += 1
		print("Well uses = ", uses, "/", max_uses)
		save_pond_state()
		if uses >= max_uses: # ครบ 5 ครั้ง
			make_pond_dry()

func make_pond_dry() -> void: # น้ำแห้ง
	if is_dry:
		return

	is_dry = true

	# เวลาที่น้ำจะกลับมา
	refill_at = (
		Time.get_unix_time_from_system()
		+ refill_time
	)

	update_animation()
	save_pond_state()

	print("WELL DRY!")
	print("Refill in ", refill_time, " seconds")


func refill_pond() -> void: # น้ำกลับมา
	is_dry = false

	uses = 0
	refill_at = 0.0

	update_animation()
	save_pond_state()

	print("WELL REFILLED!")
	print("สามารถตักน้ำได้อีก ", max_uses, " ครั้ง")

func update_animation() -> void:
	if is_dry:
		animated_sprite.play(dry_animation)
	else:
		animated_sprite.play(water_animation)

func save_pond_state() -> void:
	global.pond_states[pond_id] = {
		"uses": uses,
		"is_dry": is_dry,
		"refill_at": refill_at
	}

func load_pond_state() -> void:

	# บ่อนี้ยังไม่เคยถูกใช้
	if not global.pond_states.has(pond_id):
		save_pond_state()
		return

	var data: Dictionary = global.pond_states[pond_id]

	uses = data.get("uses", 0)
	is_dry = data.get("is_dry", false)
	refill_at = data.get("refill_at", 0.0)

	if is_dry:
		var now: float = Time.get_unix_time_from_system()
		# ครบ 60 วิระหว่างอยู่แมพอื่นแล้ว
		if now >= refill_at:
			refill_pond()
		else:
			print(
				"Well remaining = ",
				round(refill_at - now),
				" seconds"
			)
